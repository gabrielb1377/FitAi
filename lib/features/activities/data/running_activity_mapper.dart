import '../../../models/corrida_model.dart';
import '../../../models/running_session_model.dart';
import '../domain/activity_record.dart';

/// Adaptador de leitura entre o historico local de corridas e o contrato
/// generico de Atividades. Ele nao persiste uma segunda copia do dado.
extension RunningActivityMapper on CorridaModel {
  ActivityRecord<RunningActivityDetails> toActivityRecord() {
    final endedAt =
        DateTime.tryParse(endTime ?? data) ??
        DateTime.tryParse(data) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final startedAt =
        DateTime.tryParse(startTime) ??
        endedAt.subtract(Duration(seconds: segundos));
    return ActivityRecord<RunningActivityDetails>(
      id: id,
      type: ActivityType.running,
      startedAt: startedAt,
      endedAt: endedAt,
      syncStatus: _activitySyncStatus(syncStatus),
      details: RunningActivityDetails(
        distanceKm: distancia,
        paceMinutesPerKm: pace > 0 ? pace : null,
        averageSpeedKmh: averageSpeed > 0 ? averageSpeed : null,
        calories: hasReliableCalories ? calories : null,
        steps: steps,
        routePointCount: route.isEmpty ? null : route.length,
      ),
    );
  }
}

ActivitySyncStatus _activitySyncStatus(RunningSyncStatus status) =>
    switch (status) {
      RunningSyncStatus.local => ActivitySyncStatus.local,
      RunningSyncStatus.syncing => ActivitySyncStatus.syncing,
      RunningSyncStatus.queued => ActivitySyncStatus.queued,
      RunningSyncStatus.synced => ActivitySyncStatus.synced,
      RunningSyncStatus.conflict => ActivitySyncStatus.conflict,
    };
