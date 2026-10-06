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
  }) {
    return _syncService.postAuthenticatedJsonForUser(
      userId: userId,
      path: '/activities/sync',
      payload: {
        'contractVersion': activitySyncContractVersion,
        'deviceId': deviceId,
        'afterRevision': afterRevision,
        'runs': runs,
        'steps': steps,
      },
    );
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
