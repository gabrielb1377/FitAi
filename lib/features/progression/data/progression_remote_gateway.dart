import '../../../services/network_service.dart';
import '../../../services/sync_service.dart';
import '../domain/progression_models.dart';

abstract final class ProgressionRemoteContract {
  static const version = 'ProgressionSyncContract/v1';
  static const rulesVersion = 1;

  static bool supports(XpSourceType sourceType) =>
      sourceType != XpSourceType.achievement;
}

class ProgressionRemoteAckItem {
  const ProgressionRemoteAckItem({
    required this.eventId,
    required this.sourceType,
    required this.sourceId,
    required this.xpAwarded,
    required this.rulesVersion,
    required this.revision,
  });

  final String eventId;
  final XpSourceType sourceType;
  final String sourceId;
  final int xpAwarded;
  final int rulesVersion;
  final String revision;

  factory ProgressionRemoteAckItem.fromJson(Map<String, dynamic> json) =>
      ProgressionRemoteAckItem(
        eventId: _requiredText(json['eventId'], 'eventId'),
        sourceType: _sourceType(json['sourceType']),
        sourceId: _requiredText(json['sourceId'], 'sourceId'),
        xpAwarded: _positiveInt(json['xpAwarded'], 'xpAwarded'),
        rulesVersion: _positiveInt(json['rulesVersion'], 'rulesVersion'),
        revision: _revision(json['revision']),
      );
}

class ProgressionRemoteRejection {
  const ProgressionRemoteRejection({required this.eventId, required this.code});

  final String eventId;
  final String code;

  bool get isRetryable =>
      code == 'source_not_found' || code == 'source_not_completed';

  factory ProgressionRemoteRejection.fromJson(Map<String, dynamic> json) =>
      ProgressionRemoteRejection(
        eventId: _requiredText(json['eventId'], 'eventId'),
        code: _requiredText(json['code'], 'code'),
      );
}

class ProgressionRemoteAcknowledgement {
  const ProgressionRemoteAcknowledgement({
    required this.accepted,
    required this.alreadyApplied,
    required this.rejected,
  });

  final List<ProgressionRemoteAckItem> accepted;
  final List<ProgressionRemoteAckItem> alreadyApplied;
  final List<ProgressionRemoteRejection> rejected;

  factory ProgressionRemoteAcknowledgement.fromJson(
    Map<String, dynamic> json,
  ) => ProgressionRemoteAcknowledgement(
    accepted: _maps(json['accepted'], ProgressionRemoteAckItem.fromJson),
    alreadyApplied: _maps(
      json['alreadyApplied'],
      ProgressionRemoteAckItem.fromJson,
    ),
    rejected: _maps(json['rejected'], ProgressionRemoteRejection.fromJson),
  );
}

class ProgressionRemoteEvent {
  const ProgressionRemoteEvent({
    required this.eventId,
    required this.sourceType,
    required this.sourceId,
    required this.xpAwarded,
    required this.rulesVersion,
    required this.occurredAt,
    required this.revision,
  });

  final String eventId;
  final XpSourceType sourceType;
  final String sourceId;
  final int xpAwarded;
  final int rulesVersion;
  final DateTime occurredAt;
  final String revision;

  factory ProgressionRemoteEvent.fromJson(Map<String, dynamic> json) =>
      ProgressionRemoteEvent(
        eventId: _requiredText(json['eventId'], 'eventId'),
        sourceType: _sourceType(json['sourceType']),
        sourceId: _requiredText(json['sourceId'], 'sourceId'),
        xpAwarded: _positiveInt(json['xpAwarded'], 'xpAwarded'),
        rulesVersion: _positiveInt(json['rulesVersion'], 'rulesVersion'),
        occurredAt: _date(json['occurredAt'], 'occurredAt'),
        revision: _revision(json['revision']),
      );
}

class ProgressionRemoteState {
  const ProgressionRemoteState({required this.revision, required this.events});

  final String revision;
  final List<ProgressionRemoteEvent> events;

  factory ProgressionRemoteState.fromJson(Map<String, dynamic> json) =>
      ProgressionRemoteState(
        revision: _revision(json['revision']),
        events: _maps(json['events'], ProgressionRemoteEvent.fromJson),
      );
}

class ProgressionRemotePushResponse {
  const ProgressionRemotePushResponse({
    required this.acknowledgement,
    required this.state,
  });

  final ProgressionRemoteAcknowledgement acknowledgement;
  final ProgressionRemoteState state;
}

abstract interface class ProgressionRemoteGateway {
  Future<ProgressionRemotePushResponse?> push({
    required String userId,
    required List<XpEvent> events,
    required String afterRevision,
  });

  Future<ProgressionRemoteState?> pull({
    required String userId,
    required String afterRevision,
  });
}

class HttpProgressionRemoteGateway implements ProgressionRemoteGateway {
  HttpProgressionRemoteGateway({SyncService? syncService})
    : _syncService = syncService ?? SyncService.instance;

  final SyncService _syncService;

  @override
  Future<ProgressionRemotePushResponse?> push({
    required String userId,
    required List<XpEvent> events,
    required String afterRevision,
  }) async {
    final deviceId = await _syncService.getClientId();
    final response = await _syncService.postAuthenticatedJsonForUser(
      userId: userId,
      path: '/progression/sync/events',
      payload: {
        'contractVersion': ProgressionRemoteContract.version,
        'rulesVersion': ProgressionRemoteContract.rulesVersion,
        'deviceId': deviceId,
        'afterRevision': afterRevision,
        'events': [
          for (final event in events)
            {
              'eventId': event.id,
              'sourceType': event.sourceType.name,
              'sourceId': event.sourceId,
              'occurredAt': event.createdAt.toUtc().toIso8601String(),
              'rulesVersion': event.version,
            },
        ],
      },
    );
    if (response == null) return null;
    _validateEnvelope(response);
    return ProgressionRemotePushResponse(
      acknowledgement: ProgressionRemoteAcknowledgement.fromJson(
        _map(response['ack'], 'ack'),
      ),
      state: ProgressionRemoteState.fromJson(_map(response['state'], 'state')),
    );
  }

  @override
  Future<ProgressionRemoteState?> pull({
    required String userId,
    required String afterRevision,
  }) async {
    final contract = Uri.encodeQueryComponent(
      ProgressionRemoteContract.version,
    );
    final cursor = Uri.encodeQueryComponent(afterRevision);
    final response = await _syncService.getAuthenticatedJsonForUser(
      userId: userId,
      path: '/progression/sync?contractVersion=$contract&afterRevision=$cursor',
    );
    if (response == null) return null;
    _validateEnvelope(response);
    return ProgressionRemoteState.fromJson(_map(response['state'], 'state'));
  }

  void _validateEnvelope(Map<String, dynamic> response) {
    if (response['contractVersion'] != ProgressionRemoteContract.version ||
        _int(response['rulesVersion']) !=
            ProgressionRemoteContract.rulesVersion) {
      throw const NetworkException(
        'Contrato remoto de progressao incompativel.',
      );
    }
  }
}

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw NetworkException('Campo remoto invalido: $field.');
}

List<T> _maps<T>(Object? value, T Function(Map<String, dynamic>) factory) {
  if (value is! List) {
    throw const NetworkException('Lista remota de progressao invalida.');
  }
  return value
      .map((item) => factory(_map(item, 'item')))
      .toList(growable: false);
}

XpSourceType _sourceType(Object? value) {
  final name = value?.toString();
  for (final source in XpSourceType.values) {
    if (source.name == name && ProgressionRemoteContract.supports(source)) {
      return source;
    }
  }
  throw const NetworkException('Origem remota de XP invalida.');
}

String _requiredText(Object? value, String field) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) throw NetworkException('Campo remoto ausente: $field.');
  return text;
}

String _revision(Object? value) {
  final revision = _requiredText(value, 'revision');
  if (!RegExp(r'^\d+$').hasMatch(revision)) {
    throw const NetworkException('Revisao remota invalida.');
  }
  return revision;
}

int _positiveInt(Object? value, String field) {
  final parsed = _int(value);
  if (parsed <= 0) throw NetworkException('Campo remoto invalido: $field.');
  return parsed;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _date(Object? value, String field) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) throw NetworkException('Data remota invalida: $field.');
  return parsed.toLocal();
}
