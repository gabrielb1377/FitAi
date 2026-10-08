import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/auth_service.dart';
import '../core/auth/local_account_data_boundary.dart';
import 'network_service.dart';

/// Resultado imediato do envio local. Uma entrega em fila continua persistida
/// e pode ser reenviada sem bloquear o usuario.
enum RunningSyncDispatchResult { delivered, queued }

/// Resultado imediato da tentativa de envio de passos. O dado local permanece
/// canônico em ambos os casos e uma entrega em fila pode ser tentada depois.
enum StepsSyncDispatchResult { delivered, queued }

class SyncService {
  SyncService._({NetworkService? networkService, AuthService? authService})
    : _networkService = networkService ?? NetworkService(),
      _authService = authService ?? AuthService();

  static final SyncService instance = SyncService._();

  /// Instancia isolada para validar o contrato de transporte sem compartilhar
  /// fila, sessao ou cliente de rede com a aplicacao em execucao.
  @visibleForTesting
  factory SyncService.forTesting({
    required NetworkService networkService,
    required AuthService authService,
  }) => SyncService._(networkService: networkService, authService: authService);

  static const _queueKey = 'fitaiSyncQueue';
  static const _clientIdKey = 'fitaiSyncClientId';
  static Future<void> _queueMutation = Future<void>.value();

  final NetworkService _networkService;
  final AuthService _authService;
  final Map<String, Future<void> Function()> _domainFlushers = {};
  Timer? _timer;
  bool _flushing = false;

  void startAutoSync() {
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(flushPending());
    });

    unawaited(flushPending());
  }

  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// Registra uma fila de dominio que ja possui persistencia canonica propria.
  /// O callback nao cria outra outbox; ele apenas tenta drenar itens pendentes.
  void registerDomainFlusher(String key, Future<void> Function() flusher) {
    _domainFlushers[key] = flusher;
  }

  void unregisterDomainFlusher(String key) {
    _domainFlushers.remove(key);
  }

  Future<void> syncProfile(Map<String, dynamic> profile) {
    return _sendOrQueue(
      type: 'profile',
      path: '/sync/profile',
      payload: {'profile': profile},
    );
  }

  Future<void> syncGoals(List<Map<String, dynamic>> goals) {
    return _sendOrQueue(
      type: 'goals',
      path: '/sync/goals',
      payload: {'items': goals},
    );
  }

  Future<void> syncRecords(List<Map<String, dynamic>> records) {
    return _sendOrQueue(
      type: 'records',
      path: '/sync/records',
      payload: {'items': records},
    );
  }

  Future<void> syncWorkouts(List<Map<String, dynamic>> workouts) {
    final workoutId = workouts.length == 1
        ? workouts.single['id']?.toString().trim()
        : null;
    return _sendOrQueue(
      type: 'workouts',
      path: '/sync/workouts',
      payload: {'items': workouts},
      queueId: _workoutQueueId(workoutId),
    );
  }

  /// Replica uma exclusao de definicao de plano. A operacao e idempotente e
  /// compartilha a fila de definicoes, portanto uma criacao pendente do mesmo
  /// plano nao pode ressurgir apos a exclusao local.
  Future<void> deleteWorkout(String workoutId) {
    final normalizedId = workoutId.trim();
    if (normalizedId.isEmpty) return Future<void>.value();
    return _sendOrQueue(
      type: 'workout-delete',
      path: '/sync/workouts/delete',
      payload: {'id': normalizedId},
      queueId: _workoutQueueId(normalizedId),
    );
  }

  @Deprecated('Historico de musculacao usa workout-sync. Mantido sem callers.')
  Future<void> syncWorkoutHistory(List<Map<String, dynamic>> history) {
    return _sendOrQueue(
      type: 'workout-history',
      path: '/sync/workout-history',
      payload: {'items': history},
    );
  }

  @Deprecated('Historico de musculacao usa workout-sync. Mantido sem callers.')
  Future<void> syncExerciseHistory(List<Map<String, dynamic>> history) {
    return _sendOrQueue(
      type: 'exercise-history',
      path: '/sync/exercise-history',
      payload: {'items': history},
    );
  }

  Future<RunningSyncDispatchResult> syncRunning(
    List<Map<String, dynamic>> runs,
  ) async {
    final runId = runs.length == 1 ? runs.single['id']?.toString().trim() : '';
    final delivered = await _sendOrQueueWithResult(
      type: 'running',
      path: '/sync/running',
      payload: {'items': runs},
      queueId: runId == null || runId.isEmpty ? null : 'running_$runId',
    );
    return delivered
        ? RunningSyncDispatchResult.delivered
        : RunningSyncDispatchResult.queued;
  }

  Future<StepsSyncDispatchResult> syncSteps(
    List<Map<String, dynamic>> steps,
  ) async {
    final stepId = steps.length == 1
        ? steps.single['id']?.toString().trim()
        : '';
    final delivered = await _sendOrQueueWithResult(
      type: 'steps',
      path: '/steps/sync',
      payload: {'items': steps},
      queueId: stepId == null || stepId.isEmpty ? null : 'steps_$stepId',
    );
    return delivered
        ? StepsSyncDispatchResult.delivered
        : StepsSyncDispatchResult.queued;
  }

  Future<void> flushPending() async {
    if (_flushing) return;

    _flushing = true;

    try {
      final queue = await _loadQueue();
      if (queue.isNotEmpty) {
        final available = await _networkService.isBackendAvailable();
        if (!available) {
          _debugLog('Backend offline. ${queue.length} itens pendentes.');
        } else {
          for (final item in queue) {
            final sent = await _trySendQueued(item);
            await _completeQueuedAttempt(item, sent: sent);
          }
          final remaining = await _loadQueue();

          if (remaining.isEmpty) {
            _debugLog('Fila sincronizada.');
          } else {
            _debugLog('${remaining.length} itens continuam pendentes.');
          }
        }
      }
      await _flushDomains();
    } finally {
      _flushing = false;
    }
  }

  Future<int> pendingCount() async {
    return (await _loadQueue()).length;
  }

  Future<String> getClientId() => _clientId();

  /// Transporte autenticado para dominios que precisam consumir o ACK.
  /// Retorna `null` sem enviar quando a sessao nao existe ou pertence a outra
  /// conta. O chamador mantem sua propria mutacao local pendente.
  Future<Map<String, dynamic>?> postAuthenticatedJsonForUser({
    required String userId,
    required String path,
    required Map<String, dynamic> payload,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    return _authenticatedRequest(
      userId: userId,
      send: (headers) => _networkService.postJson(
        path,
        payload,
        headers: headers,
        timeout: timeout,
      ),
    );
  }

  Future<Map<String, dynamic>?> getAuthenticatedJsonForUser({
    required String userId,
    required String path,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    return _authenticatedRequest(
      userId: userId,
      send: (headers) =>
          _networkService.getJson(path, headers: headers, timeout: timeout),
    );
  }

  Future<Map<String, dynamic>?> _authenticatedRequest({
    required String userId,
    required Future<Map<String, dynamic>> Function(Map<String, String>) send,
  }) async {
    final session = await _authService.restoreSession();
    if (session == null || session.userId != userId) return null;
    final lifecycle = AccountSessionLifecycle.revision.value;
    final clientId = await _clientId();
    Map<String, String> headers(AuthSession value) => {
      'Authorization': 'Bearer ${value.token}',
      'X-FitIA-Client-Id': clientId,
    };
    try {
      final result = await send(headers(session));
      return AccountSessionLifecycle.revision.value == lifecycle
          ? result
          : null;
    } on NetworkException catch (error) {
      if (error.statusCode != 401) rethrow;
      if (AccountSessionLifecycle.revision.value != lifecycle) return null;
      final refreshed = await _authService.refreshSession(session: session);
      if (refreshed == null ||
          refreshed.userId != userId ||
          AccountSessionLifecycle.revision.value != lifecycle) {
        return null;
      }
      final result = await send(headers(refreshed));
      return AccountSessionLifecycle.revision.value == lifecycle
          ? result
          : null;
    }
  }

  Future<void> _sendOrQueue({
    required String type,
    required String path,
    required Map<String, dynamic> payload,
    String? queueId,
  }) async {
    await _sendOrQueueWithResult(
      type: type,
      path: path,
      payload: payload,
      queueId: queueId,
    );
  }

  Future<bool> _sendOrQueueWithResult({
    required String type,
    required String path,
    required Map<String, dynamic> payload,
    String? queueId,
  }) async {
    final clientId = await _clientId();
    final session = await _authService.restoreSession();
    final enrichedPayload = {...payload, 'clientId': clientId};
    final queueItemId = queueId ?? _queueId(type);
    final queueItem = {
      'id': '${session?.userId ?? 'unowned'}_$queueItemId',
      'type': type,
      'path': path,
      'payload': enrichedPayload,
      'ownerUserId': session?.userId,
      'attempts': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'operationId': _queueId(type),
    };

    // Persist before dispatch. A crash or lost ACK must leave a replayable item.
    await _enqueue(queueItem);

    final sent = await _trySend(
      path,
      enrichedPayload,
      clientId: clientId,
      session: session,
    );

    await _completeQueuedAttempt(queueItem, sent: sent);
    if (!sent) return false;

    unawaited(flushPending());
    return true;
  }

  Future<bool> _trySendQueued(Map<String, dynamic> item) async {
    final path = item['path']?.toString() ?? '';
    final payload = _map(item['payload']);
    final clientId = payload['clientId']?.toString() ?? await _clientId();

    if (path.isEmpty || payload.isEmpty) {
      return true;
    }

    if (_isLegacyActivityPath(path)) {
      _debugLog(
        'Replay legado de Atividades retido; ActivitySyncContract/v2 e a '
        'unica trilha ativa.',
      );
      return false;
    }

    final ownerUserId = item['ownerUserId']?.toString().trim();
    final session = await _authService.restoreSession();

    // Itens legados sem proprietario ou de outra conta ficam preservados na
    // fila ate que uma migracao explicita os associe a um usuario autenticado.
    if (ownerUserId == null || ownerUserId.isEmpty || session == null) {
      _debugLog('Sync pendente: sessao autenticada indisponivel para $path.');
      return false;
    }
    if (ownerUserId != session.userId) {
      _debugLog('Sync pendente pertence a outra conta e foi preservado.');
      return false;
    }

    return _trySend(path, payload, clientId: clientId, session: session);
  }

  Future<bool> _trySend(
    String path,
    Map<String, dynamic> payload, {
    required String clientId,
    required AuthSession? session,
  }) async {
    if (session == null) {
      _debugLog('Sync pendente: nenhuma sessao autenticada para $path.');
      return false;
    }

    try {
      final result = await postAuthenticatedJsonForUser(
        userId: session.userId,
        path: path,
        payload: payload,
      );
      if (result == null) return false;

      _debugLog('Sync enviado: $path');
      return true;
    } catch (error) {
      _debugLog('Sync pendente para $path: ${error.runtimeType}');
      return false;
    }
  }

  Future<void> _enqueue(Map<String, dynamic> item) async {
    await _mutateQueue((queue) async {
      final id = item['id']?.toString() ?? _queueId('item');
      final withoutSame = queue.where((entry) => entry['id'] != id).toList();

      withoutSame.add(item);
      await _saveQueue(withoutSame);
    });
    _debugLog('Item marcado como pendente: ${item['type']}');
  }

  Future<void> _flushDomains() async {
    for (final entry in [..._domainFlushers.entries]) {
      try {
        await entry.value();
      } on Object catch (error) {
        _debugLog(
          'Sync de dominio pendente (${entry.key}): ${error.runtimeType}',
        );
      }
    }
  }

  Future<void> _completeQueuedAttempt(
    Map<String, dynamic> snapshot, {
    required bool sent,
  }) => _mutateQueue((queue) async {
    final index = queue.indexWhere(
      (entry) =>
          entry['id'] == snapshot['id'] &&
          jsonEncode(entry) == jsonEncode(snapshot),
    );
    if (index < 0) return;
    if (sent) {
      queue.removeAt(index);
    } else {
      queue[index] = {
        ...snapshot,
        'attempts': _int(snapshot['attempts']) + 1,
        'lastAttemptAt': DateTime.now().toIso8601String(),
      };
    }
    await _saveQueue(queue);
  });

  Future<T> _mutateQueue<T>(
    Future<T> Function(List<Map<String, dynamic>>) action,
  ) {
    final result = _queueMutation.then((_) async => action(await _loadQueue()));
    _queueMutation = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  /// Removes only legacy activity items whose canonical v2 identity has been
  /// acknowledged. Unmatched/ambiguous payloads remain preserved for review.
  Future<int> acknowledgeLegacyActivityQueue({
    required String userId,
    Set<String> runningIds = const <String>{},
    Set<String> stepDayKeys = const <String>{},
  }) async {
    final owner = userId.trim();
    if (owner.isEmpty || (runningIds.isEmpty && stepDayKeys.isEmpty)) return 0;

    return _mutateQueue((queue) async {
      final remaining = <Map<String, dynamic>>[];
      var removedItems = 0;

      for (final entry in queue) {
        if (entry['ownerUserId']?.toString().trim() != owner) {
          remaining.add(entry);
          continue;
        }

        final path = entry['path']?.toString() ?? '';
        final isRunning = path == '/sync/running' && runningIds.isNotEmpty;
        final isSteps = path == '/steps/sync' && stepDayKeys.isNotEmpty;
        if (!isRunning && !isSteps) {
          remaining.add(entry);
          continue;
        }

        final payload = _map(entry['payload']);
        final rawItems = payload['items'];
        if (rawItems is! List) {
          final item = _map(payload['item']);
          final matched = isRunning
              ? runningIds.contains(_legacyRunId(item))
              : stepDayKeys.contains(_legacyStepDay(item));
          if (matched) {
            removedItems++;
          } else {
            remaining.add(entry);
          }
          continue;
        }

        final kept = <Object?>[];
        for (final rawItem in rawItems) {
          final item = _map(rawItem);
          final matched = isRunning
              ? runningIds.contains(_legacyRunId(item))
              : stepDayKeys.contains(_legacyStepDay(item));
          if (matched) {
            removedItems++;
          } else {
            kept.add(rawItem);
          }
        }

        if (kept.isNotEmpty) {
          remaining.add({
            ...entry,
            'payload': {...payload, 'items': kept},
          });
        } else if (rawItems.isEmpty) {
          remaining.add(entry);
        }
      }

      if (removedItems > 0) await _saveQueue(remaining);
      return removedItems;
    });
  }

  bool _isLegacyActivityPath(String path) =>
      path == '/sync/running' || path == '/steps/sync';

  String _legacyRunId(Map<String, dynamic> item) =>
      (item['id'] ?? item['syncId'])?.toString().trim() ?? '';

  String _legacyStepDay(Map<String, dynamic> item) =>
      (item['date'] ?? item['dayKey'])?.toString().trim() ?? '';

  Future<List<Map<String, dynamic>>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? const <String>[];
    final items = <Map<String, dynamic>>[];

    for (final value in raw) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is Map<String, dynamic>) {
          items.add(decoded);
        } else if (decoded is Map) {
          items.add(Map<String, dynamic>.from(decoded));
        }
      } catch (error) {
        _debugLog('Item invalido na fila ignorado: $error');
      }
    }

    return items;
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
      _queueKey,
      queue.map((item) => jsonEncode(item)).toList(),
    );
    if (!saved) throw StateError('Sync queue persistence failed');
  }

  Future<String> _clientId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_clientIdKey);

    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final random = Random();
    final value =
        'fitai_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 31)}';
    await prefs.setString(_clientIdKey, value);

    return value;
  }

  String _queueId(String type) {
    return '${type}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 31)}';
  }

  String _workoutQueueId(String? workoutId) {
    final normalizedId = workoutId?.trim() ?? '';
    return normalizedId.isEmpty
        ? _queueId('workouts')
        : 'workout_$normalizedId';
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return <String, dynamic>{};
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[SyncService] $message');
    }
  }
}
