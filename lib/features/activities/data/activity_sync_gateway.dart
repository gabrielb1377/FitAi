import '../../../services/sync_service.dart';

const String activitySyncContractVersion = 'ActivitySyncContract/v2';

abstract interface class ActivitySyncGateway {
  Future<Map<String, dynamic>?> push({
    required String userId,
    required String deviceId,
    required String afterRevision,
    required List<Map<String, dynamic>> runs,
    required List<Map<String, dynamic>> steps,
  });

  Future<Map<String, dynamic>?> pull({
    required String userId,
    required String afterRevision,
  });
}

class HttpActivitySyncGateway implements ActivitySyncGateway {
  HttpActivitySyncGateway({SyncService? syncService})
    : _syncService = syncService ?? SyncService.instance;

  final SyncService _syncService;

  @override
  Future<Map<String, dynamic>?> push({
    required String userId,
    required String deviceId,
    required String afterRevision,
    required List<Map<String, dynamic>> runs,
    required List<Map<String, dynamic>> steps,
  }) async {
    // Local day/version counters are independent on each device. Namespace the
    // wire identity, while preserving the domain identity used to apply ACKs.
    final localIds = <String, String>{};
    final wireSteps = steps
        .map((step) {
          final localId = step['mutationId'] as String;
          final wireId = '$deviceId:$localId';
          localIds[wireId] = localId;
          return <String, dynamic>{...step, 'mutationId': wireId};
        })
        .toList(growable: false);
    final response = await _syncService.postAuthenticatedJsonForUser(
      userId: userId,
      path: '/activities/sync',
      payload: {
        'contractVersion': activitySyncContractVersion,
        'deviceId': deviceId,
        'afterRevision': afterRevision,
        'runs': runs,
        'steps': wireSteps,
      },
    );
    if (response == null) return null;
    final ack = response['ack'];
    if (ack is Map) {
      for (final bucket in [
        'accepted',
        'alreadyApplied',
        'updated',
        'rejected',
      ]) {
        final items = ack[bucket];
        if (items is! List) continue;
        for (final item in items) {
          if (item is Map && localIds.containsKey(item['mutationId'])) {
            item['mutationId'] = localIds[item['mutationId']];
          }
        }
      }
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>?> pull({
    required String userId,
    required String afterRevision,
  }) {
    final contract = Uri.encodeQueryComponent(activitySyncContractVersion);
    final cursor = Uri.encodeQueryComponent(afterRevision);
    return _syncService.getAuthenticatedJsonForUser(
      userId: userId,
      path: '/activities/sync?contractVersion=$contract&afterRevision=$cursor',
    );
  }
}
