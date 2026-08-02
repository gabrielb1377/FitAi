import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network_service.dart';

/// Resultado imediato do envio local. Uma entrega em fila continua persistida
/// e pode ser reenviada sem bloquear o usuario.
enum RunningSyncDispatchResult { delivered, queued }

/// Resultado imediato da tentativa de envio de passos. O dado local permanece
/// canônico em ambos os casos e uma entrega em fila pode ser tentada depois.
enum StepsSyncDispatchResult { delivered, queued }

class SyncService {
  SyncService._({NetworkService? networkService})
    : _networkService = networkService ?? NetworkService();

  static final SyncService instance = SyncService._();

  static const _queueKey = 'fitaiSyncQueue';
  static const _clientIdKey = 'fitaiSyncClientId';

  final NetworkService _networkService;
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
    return _sendOrQueue(
      type: 'workouts',
      path: '/sync/workouts',
      payload: {'items': workouts},
    );
  }

  Future<void> syncWorkoutHistory(List<Map<String, dynamic>> history) {
    return _sendOrQueue(
      type: 'workout-history',
      path: '/sync/workout-history',
      payload: {'items': history},
    );
  }

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
      if (queue.isEmpty) return;

      final available = await _networkService.isBackendAvailable();
      if (!available) {
        _debugLog('Backend offline. ${queue.length} itens pendentes.');
        return;
      }

      final remaining = <Map<String, dynamic>>[];

      for (final item in queue) {
        final sent = await _trySendQueued(item);

        if (!sent) {
          final attempts = _int(item['attempts']) + 1;
          remaining.add({
            ...item,
            'attempts': attempts,
            'lastAttemptAt': DateTime.now().toIso8601String(),
          });
        }
      }

      await _saveQueue(remaining);

      if (remaining.isEmpty) {
        _debugLog('Fila sincronizada.');
      } else {
        _debugLog('${remaining.length} itens continuam pendentes.');
      }
    } finally {
      _flushing = false;
    }
  }

  Future<int> pendingCount() async {
    return (await _loadQueue()).length;
  }

  Future<String> getClientId() => _clientId();

  Future<void> _sendOrQueue({
    required String type,
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    await _sendOrQueueWithResult(type: type, path: path, payload: payload);
  }

  Future<bool> _sendOrQueueWithResult({
    required String type,
    required String path,
    required Map<String, dynamic> payload,
    String? queueId,
  }) async {
    final clientId = await _clientId();
    final enrichedPayload = {...payload, 'clientId': clientId};
    final queueItem = {
      'id': queueId ?? _queueId(type),
      'type': type,
      'path': path,
      'payload': enrichedPayload,
      'attempts': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final sent = await _trySend(path, enrichedPayload, clientId: clientId);

    if (!sent) {
      await _enqueue(queueItem);
      return false;
    }

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

    return _trySend(path, payload, clientId: clientId);
  }

  Future<bool> _trySend(
    String path,
    Map<String, dynamic> payload, {
    required String clientId,
  }) async {
    try {
      await _networkService.postJson(
        path,
        payload,
        headers: {'X-FitIA-Client-Id': clientId},
        timeout: const Duration(seconds: 8),
      );

      _debugLog('Sync enviado: $path');
      return true;
    } catch (error) {
      _debugLog('Sync pendente para $path: $error');
      return false;
    }
  }

  Future<void> _enqueue(Map<String, dynamic> item) async {
    final queue = await _loadQueue();
    final id = item['id']?.toString() ?? _queueId('item');
    final withoutSame = queue.where((entry) => entry['id'] != id).toList();

    withoutSame.add(item);
    await _saveQueue(withoutSame);
    _debugLog('Item marcado como pendente: ${item['type']}');
  }

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
    await prefs.setStringList(
      _queueKey,
      queue.map((item) => jsonEncode(item)).toList(),
    );
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
