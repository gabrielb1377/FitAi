import 'package:fitai/features/activities/domain/activity_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registros genericos mantem detalhes especificos fora de Planos', () {
    final running = ActivityRecord<RunningActivityDetails>(
      id: 'run-1',
      type: ActivityType.running,
      startedAt: DateTime(2026, 8, 2, 7),
      endedAt: DateTime(2026, 8, 2, 7, 30),
      syncStatus: ActivitySyncStatus.local,
      details: const RunningActivityDetails(distanceKm: 5, paceMinutesPerKm: 6),
    );
    final steps = ActivityRecord<StepsActivityDetails>(
      id: 'steps-2026-08-02',
      type: ActivityType.steps,
      startedAt: DateTime(2026, 8, 2),
      endedAt: DateTime(2026, 8, 2, 23, 59),
      syncStatus: ActivitySyncStatus.synced,
      details: const StepsActivityDetails(steps: 8200),
    );

    expect(running.duration, const Duration(minutes: 30));
    expect(running.details.distanceKm, 5);
    expect(steps.details.steps, 8200);
  });
}
