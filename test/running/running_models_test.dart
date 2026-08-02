import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/features/activities/data/running_activity_mapper.dart';
import 'package:fitai/features/activities/domain/activity_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('corrida preserva passos e status de sincronizacao no JSON', () {
    final corrida = CorridaModel(
      id: 'run-1',
      distancia: 5.2,
      segundos: 1800,
      data: '2026-08-02T10:30:00.000',
      steps: 6200,
      syncStatus: RunningSyncStatus.queued,
    );

    final restored = CorridaModel.fromJson(corrida.toJson());

    expect(restored.id, 'run-1');
    expect(restored.steps, 6200);
    expect(restored.syncStatus, RunningSyncStatus.queued);
    expect(restored.pace, greaterThan(0));
  });

  test('dados legados de corrida continuam validos sem status ou passos', () {
    final restored = CorridaModel.fromJson({
      'id': 'legacy-run',
      'distancia': 2.5,
      'segundos': 900,
      'data': '2026-08-01T08:00:00.000',
    });

    expect(restored.steps, isNull);
    expect(restored.syncStatus, RunningSyncStatus.local);
    expect(restored.averageSpeed, greaterThan(0));
  });

  test('adapta corrida sem duplicar dados para o contrato de Atividades', () {
    final activity = CorridaModel(
      id: 'run-activity-1',
      distancia: 4,
      segundos: 1500,
      data: '2026-08-02T07:25:00.000',
      startTime: '2026-08-02T07:00:00.000',
      steps: 4800,
      syncStatus: RunningSyncStatus.queued,
    ).toActivityRecord();

    expect(activity.type, ActivityType.running);
    expect(activity.syncStatus, ActivitySyncStatus.queued);
    expect(activity.details.distanceKm, 4);
    expect(activity.details.steps, 4800);
  });
}
