import '../../../models/daily_steps_model.dart';
import '../domain/activity_record.dart';

/// Adapta o agregado diário para a timeline genérica sem transformar passos
/// em sessão de treino ou copiar os dados para outra persistência.
extension DailyStepsActivityMapper on DailyStepsModel {
  ActivityRecord<StepsActivityDetails> toActivityRecord() {
    final dateValue =
        DateTime.tryParse(date)?.toLocal() ?? recordedAt.toLocal();
    final start = DateTime(dateValue.year, dateValue.month, dateValue.day);
    return ActivityRecord(
      id: recordId,
      type: ActivityType.steps,
      startedAt: start,
      endedAt: updatedAt,
      syncStatus: _syncStatus(syncStatus),
      details: StepsActivityDetails(
        steps: steps,
        goal: goal,
        source: sourceKind.storageValue,
        estimatedDistanceMeters: estimatedDistanceMeters,
        estimatedCalories: estimatedCalories,
      ),
    );
  }
}

ActivitySyncStatus _syncStatus(DailyStepsSyncStatus status) {
  return switch (status) {
    DailyStepsSyncStatus.local => ActivitySyncStatus.local,
    DailyStepsSyncStatus.pending => ActivitySyncStatus.queued,
    DailyStepsSyncStatus.syncing => ActivitySyncStatus.syncing,
    DailyStepsSyncStatus.synced => ActivitySyncStatus.synced,
    DailyStepsSyncStatus.conflict => ActivitySyncStatus.conflict,
    DailyStepsSyncStatus.failed => ActivitySyncStatus.failed,
  };
}
