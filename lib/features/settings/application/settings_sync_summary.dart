import '../../../features/progression/progression.dart';
import '../../../models/daily_steps_model.dart';
import '../../../models/running_session_model.dart';
import '../../../services/storage_service.dart';
import '../../../services/sync_service.dart';

class SettingsSyncSummary {
  const SettingsSyncSummary({
    required this.pendingOutbox,
    required this.pendingRuns,
    required this.pendingSteps,
    required this.pendingProgression,
  });

  final int pendingOutbox;
  final int pendingRuns;
  final int pendingSteps;
  final int pendingProgression;

  int get totalPending =>
      pendingOutbox + pendingRuns + pendingSteps + pendingProgression;

  bool get hasPending => totalPending > 0;

  static Future<SettingsSyncSummary> load() async {
    final values = await Future.wait<Object>([
      SyncService.instance.pendingCount(),
      StorageService.carregarCorridas(),
      StorageService.carregarDailyStepsHistory(),
      ProgressionEngine.instance.load(),
    ]);
    final runs = values[1] as List;
    final steps = values[2] as List;
    final progression = values[3] as ProgressionSnapshot;
    return SettingsSyncSummary(
      pendingOutbox: values[0] as int,
      pendingRuns: runs
          .cast<dynamic>()
          .where(
            (item) =>
                item.syncStatus is RunningSyncStatus &&
                item.syncStatus != RunningSyncStatus.synced,
          )
          .length,
      pendingSteps: steps
          .cast<dynamic>()
          .where(
            (item) =>
                item.syncStatus is DailyStepsSyncStatus &&
                item.syncStatus != DailyStepsSyncStatus.synced,
          )
          .length,
      pendingProgression: progression.events
          .where((event) => event.syncStatus != ProgressionSyncStatus.synced)
          .length,
    );
  }

  static Future<void> retry() => SyncService.instance.flushPending();
}
