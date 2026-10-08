import 'dart:async';
import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/core/config/dev_config.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/workout_vertical_models.dart';
import 'workout_vertical_log.dart';

/// Contrato que o backend devera atender antes de substituir o transporte debug.
abstract interface class WorkoutVerticalSyncTransport {
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event);
}

enum WorkoutSyncConnectionState { unknown, online, offline }

abstract interface class WorkoutSyncConnectionReporter {
  WorkoutSyncConnectionState get connectionState;
}

/// Permite encerrar recursos de transporte que pertencem ao Vertical Slice.
abstract interface class WorkoutSyncTransportDisposer {
  void dispose();
}

/// Transporte deterministico e sem rede, exclusivo para demonstracao em debug.
class DebugWorkoutSyncTransport
    implements WorkoutVerticalSyncTransport, WorkoutSyncConnectionReporter {
  bool online = true;
  bool failNextDispatch = false;
  bool conflictNextDispatch = false;
  final List<String> receivedIdempotencyKeys = [];

  @override
  WorkoutSyncConnectionState get connectionState => online
      ? WorkoutSyncConnectionState.online
      : WorkoutSyncConnectionState.offline;

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    if (!online) throw StateError('Sem conexao.');
    if (failNextDispatch) {
      failNextDispatch = false;
      throw StateError('Falha de sincronizacao simulada.');
    }
    if (conflictNextDispatch) {
      conflictNextDispatch = false;
      return const SyncDispatchResult.conflict();
    }
    if (!receivedIdempotencyKeys.contains(event.idempotencyKey)) {
      receivedIdempotencyKeys.add(event.idempotencyKey);
    }
    return const SyncDispatchResult.confirmed();
  }
}

/// Adapter do contrato VS2. Cada despacho recebe ACK individual do lote.
class HttpWorkoutSyncTransport
    implements
        WorkoutVerticalSyncTransport,
        WorkoutSyncConnectionReporter,
        WorkoutSyncTransportDisposer {
  HttpWorkoutSyncTransport({
    http.Client? client,
    AuthService? authService,
    this.expectedUserId,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _authService = authService ?? AuthService(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _deviceIdKey = 'fitai.workoutVerticalSlice.deviceId.v1';

  final http.Client _client;
  final bool _ownsClient;
  final AuthService _authService;
  final String? expectedUserId;
  final Future<SharedPreferences> Function() _preferencesLoader;
  WorkoutSyncConnectionState _connectionState =
      WorkoutSyncConnectionState.unknown;

  @override
  WorkoutSyncConnectionState get connectionState => _connectionState;

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    final session = await _authService.restoreSession();
    if (session == null ||
        (expectedUserId != null && session.userId != expectedUserId)) {
      throw const WorkoutSyncTransportException(
        'Sessao autenticada necessaria para sincronizar.',
        retryable: true,
      );
    }
    final lifecycle = AccountSessionLifecycle.revision.value;
    try {
      return await dispatchWithToken(event, session.token);
    } on WorkoutSyncTransportException catch (error) {
      if (error.statusCode != 401 && error.statusCode != 403) rethrow;
      if (AccountSessionLifecycle.revision.value != lifecycle) rethrow;
      final refreshed = await _authService.refreshSession(session: session);
      if (refreshed == null ||
          refreshed.userId != session.userId ||
          AccountSessionLifecycle.revision.value != lifecycle) {
        rethrow;
      }
      return dispatchWithToken(event, refreshed.token);
    }
  }

  Future<SyncDispatchResult> dispatchWithToken(
    OutboxEventLocal event,
    String bearerToken,
  ) async {
    final response = await _post(event, bearerToken);
    _setConnectionState(WorkoutSyncConnectionState.online);
    final body = _decodeObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WorkoutSyncTransportException(
        _message(body, 'Falha ao sincronizar treino.'),
        // Uma sessao expirada ou revogada exige nova autenticacao, mas nunca
        // pode descartar uma serie local. A outbox permanece pendente para
        // ser reenviada depois que a sessao for restaurada.
        retryable:
            response.statusCode == 401 ||
            response.statusCode == 403 ||
            response.statusCode == 429 ||
            response.statusCode >= 500,
        statusCode: response.statusCode,
      );
    }

    if (_containsEvent(body['accepted'], event.id) ||
        _containsEvent(body['alreadyProcessed'], event.id)) {
      return _containsEvent(body['accepted'], event.id)
          ? const SyncDispatchResult.confirmed()
          : const SyncDispatchResult.alreadyProcessed();
    }
    if (_containsEvent(body['conflicts'], event.id)) {
      return SyncDispatchResult.conflict(
        _eventMessage(body['conflicts'], event.id),
      );
    }
    if (_containsEvent(body['rejected'], event.id)) {
      return SyncDispatchResult.rejected(
        _eventMessage(body['rejected'], event.id),
      );
    }
    throw const WorkoutSyncTransportException(
      'Resposta de sincronizacao nao confirmou o evento.',
      retryable: true,
    );
  }

  Future<http.Response> _post(
    OutboxEventLocal event,
    String bearerToken,
  ) async {
    try {
      return await _client
          .post(
            ApiConfig.endpoint('/workout-sync/events'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $bearerToken',
            },
            body: jsonEncode({
              'deviceId': await _deviceId(),
              'sessionId': event.sessionId,
              'events': [
                {
                  'eventId': event.id,
                  'idempotencyKey': event.idempotencyKey,
                  'eventType': event.eventType,
                  'aggregateId': event.aggregateId,
                  'occurredAt': event.createdAt.toIso8601String(),
                  'version': event.version,
                  'payload': event.payload,
                },
              ],
            }),
          )
          .timeout(ApiConfig.timeout);
    } on http.ClientException catch (error) {
      _setConnectionState(WorkoutSyncConnectionState.offline);
      WorkoutVerticalLog.failure('sync.transport.client_failure', error);
      throw WorkoutSyncTransportException(error.message, retryable: true);
    } on TimeoutException {
      _setConnectionState(WorkoutSyncConnectionState.offline);
      WorkoutVerticalLog.event('sync.transport.timeout');
      throw const WorkoutSyncTransportException(
        'Tempo esgotado ao sincronizar treino.',
        retryable: true,
      );
    }
  }

  void _setConnectionState(WorkoutSyncConnectionState value) {
    if (_connectionState == value) return;
    _connectionState = value;
    WorkoutVerticalLog.event(
      'sync.transport.connection_changed',
      fields: {'state': value.name},
    );
  }

  Future<String> _deviceId() async {
    final preferences = await _preferencesLoader();
    final existing = preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final value = const Uuid().v4();
    await preferences.setString(_deviceIdKey, value);
    return value;
  }

  Map<String, dynamic> _decodeObject(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // A excecao classificavel abaixo evita tratar HTML como ACK.
    }
    return const {};
  }

  bool _containsEvent(Object? list, String eventId) =>
      list is List &&
      list.any((item) => item is Map && item['eventId']?.toString() == eventId);

  String _eventMessage(Object? list, String eventId) {
    if (list is List) {
      for (final item in list) {
        if (item is Map && item['eventId']?.toString() == eventId) {
          return _message(
            Map<String, dynamic>.from(item),
            'Evento nao confirmado.',
          );
        }
      }
    }
    return 'Evento nao confirmado.';
  }

  String _message(Map<String, dynamic> body, String fallback) {
    final message = body['message']?.toString().trim() ?? '';
    return message.isEmpty ? fallback : message;
  }
}

/// Usa o endpoint real quando existe JWT; o modo debug sem login continua
/// deterministico e nao torna o endpoint anonimo.
class AdaptiveWorkoutSyncTransport
    implements
        WorkoutVerticalSyncTransport,
        WorkoutSyncConnectionReporter,
        WorkoutSyncTransportDisposer {
  AdaptiveWorkoutSyncTransport({
    required this.debugTransport,
    this.expectedUserId,
    this.allowDebugFallback = true,
    HttpWorkoutSyncTransport? remoteTransport,
    AuthService? authService,
  }) : _remoteTransport =
           remoteTransport ??
           HttpWorkoutSyncTransport(
             authService: authService,
             expectedUserId: expectedUserId,
           ),
       _authService = authService ?? AuthService();

  final DebugWorkoutSyncTransport debugTransport;
  final HttpWorkoutSyncTransport _remoteTransport;
  final AuthService _authService;
  final String? expectedUserId;
  final bool allowDebugFallback;

  @override
  void dispose() => _remoteTransport.dispose();

  @override
  WorkoutSyncConnectionState get connectionState {
    if (!debugTransport.online) return WorkoutSyncConnectionState.offline;
    return _remoteTransport.connectionState;
  }

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    final debugAllowed = DevConfig.enabled && allowDebugFallback;
    if (!debugTransport.online && debugAllowed) {
      return debugTransport.dispatch(event);
    }
    final session = await _authService.restoreSession();
    if (session == null) {
      if (debugAllowed) return debugTransport.dispatch(event);
      throw const WorkoutSyncTransportException(
        'Sessao autenticada necessaria para sincronizar.',
        retryable: true,
      );
    }
    if (expectedUserId != null && session.userId != expectedUserId) {
      throw const WorkoutSyncTransportException(
        'Outbox pertence a outra conta.',
        retryable: true,
      );
    }
    return _remoteTransport.dispatch(event);
  }
}
