import 'package:fitai/features/activities/data/activity_sync_service.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fitai_08_activity_sync_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'SYNC-19-01: in-flight ACK cannot erase a newer steps observation',
    () async {
      final old = fixture.sampleSteps(userId: 'user-a', count: 5000);
      await StorageService.salvarDailyStepsHistory([old]);
      final gateway = _Gateway(
        onPush: () async {
          await StorageService.salvarDailyStepsHistory([
            old.copyWith(steps: 6200, version: 2),
          ]);
        },
        pushResponse: fixture.response(
          accepted: [old.mutationId],
          steps: [fixture.remoteSteps(old, revision: '1')],
          revision: '1',
        ),
      );
      await ActivitySyncService.forTesting(gateway: gateway).syncUser('user-a');
      final saved = (await StorageService.carregarDailyStepsHistory()).single;
      expect(saved.steps, 6200);
      expect(saved.version, 2);
      expect(saved.syncStatus, DailyStepsSyncStatus.pending);
    },
  );

  test(
    'SYNC-19-02: backlog is bounded and drains over successive syncs',
    () async {
      final base = fixture.sampleSteps(userId: 'user-a', count: 5000);
      await StorageService.salvarDailyStepsHistory([
        for (var day = 0; day < 51; day++)
          base.copyWith(
            date: DateTime.utc(
              2026,
              1,
              1,
            ).add(Duration(days: day)).toIso8601String().substring(0, 10),
          ),
      ]);
      final gateway = _Gateway(ackAll: true);
      final service = ActivitySyncService.forTesting(gateway: gateway);
      await service.syncUser('user-a');
      await service.syncUser('user-a');
      expect(gateway.batchSizes, [50, 1]);
      expect(
        (await StorageService.carregarDailyStepsHistory()).every(
          (item) => item.syncStatus == DailyStepsSyncStatus.synced,
        ),
        isTrue,
      );
    },
  );

  test(
    'SYNC-19-03: permanently rejected steps are not retried automatically',
    () async {
      final record = fixture.sampleSteps(
        userId: 'user-a',
        count: 5000,
        status: DailyStepsSyncStatus.conflict,
      );
      await StorageService.salvarDailyStepsHistory([record]);
      final gateway = _Gateway();
      await ActivitySyncService.forTesting(gateway: gateway).syncUser('user-a');
      expect(gateway.batchSizes, isEmpty);
      expect(gateway.pulls, 1);
      expect(
        (await StorageService.carregarDailyStepsHistory()).single.syncStatus,
        DailyStepsSyncStatus.conflict,
      );
    },
  );

  test('SYNC-19-04: stale pull cannot regress the persisted cursor', () async {
    await StorageService.salvarActivitySyncCursor('user-a', '9');
    final gateway = _Gateway(pullResponse: fixture.response(revision: '3'));
    await ActivitySyncService.forTesting(gateway: gateway).syncUser('user-a');
    expect(await StorageService.carregarActivitySyncCursor('user-a'), '9');
    expect(await StorageService.carregarActivitySyncCursor('user-b'), '0');
  });
}

class _Gateway extends fixture.FakeActivityGateway {
  _Gateway({
    this.onPush,
    this.ackAll = false,
    super.pushResponse,
    super.pullResponse,
  });
  final Future<void> Function()? onPush;
  final bool ackAll;
  final List<int> batchSizes = [];
  int pulls = 0;

  @override
  Future<Map<String, dynamic>?> push({
    required String userId,
    required String deviceId,
    required String afterRevision,
    required List<Map<String, dynamic>> runs,
    required List<Map<String, dynamic>> steps,
  }) async {
    batchSizes.add(steps.length);
    await onPush?.call();
    if (ackAll) {
      return fixture.response(
        accepted: [
          for (final item in [...runs, ...steps]) item['mutationId'] as String,
        ],
      );
    }
    return pushResponse;
  }

  @override
  Future<Map<String, dynamic>?> pull({
    required String userId,
    required String afterRevision,
  }) async {
    pulls++;
    return pullResponse;
  }
}
