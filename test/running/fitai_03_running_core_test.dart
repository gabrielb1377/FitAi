import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RUN-CORE-01/02: start cria uma sessão persistida e estável', () async {
    final now = DateTime(2026, 10, 3, 8);
    final service = RunningSessionService.forTesting(clock: () => now);

    await service.start();
    final id = service.session!.id;
    await service.start();

    expect(service.session!.id, id);
    expect(
      (await StorageService.carregarRunningSessionAtiva())!.startTime,
      now,
    );
  });

  test(
    'RUN-CORE-08/10/23: amostras falsas atualizam distância e pace',
    () async {
      var now = DateTime(2026, 10, 3, 8);
      final service = RunningSessionService.forTesting(clock: () => now);
      await service.start();

      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0,
        recordedAt: now,
      );
      now = now.add(const Duration(minutes: 5));
      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0.009,
        recordedAt: now,
      );

      expect(service.distanceKm, greaterThan(0.9));
      expect(service.pace, greaterThan(0));
      await service.discardActiveSession();
    },
  );

  test(
    'RUN-CORE-09/11/24: zero e pontos inválidos não corrompem métricas',
    () async {
      final now = DateTime(2026, 10, 3, 8);
      final service = RunningSessionService.forTesting(clock: () => now);
      await service.start();

      service.recordLocationForTesting(
        latitude: 999,
        longitude: 0,
        recordedAt: now,
      );
      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0,
        accuracy: 500,
        recordedAt: now,
      );

      expect(service.distanceKm, 0);
      expect(service.pace, 0);
      await service.discardActiveSession();
    },
  );

  test('RUN-CORE-18/19/20: descarte limpa a sessão e não a recupera', () async {
    final first = RunningSessionService.forTesting();
    await first.start();

    await first.discardActiveSession();

    final recovered = RunningSessionService.forTesting();
    await recovered.initialize();
    expect(recovered.hasActiveSession, isFalse);
    expect(await StorageService.carregarCorridas(), isEmpty);
  });

  test('RUN-CORE-21: histórico local permanece em ordem recente', () async {
    await StorageService.salvarCorrida(
      CorridaModel(
        id: 'run-earlier',
        distancia: 1,
        segundos: 300,
        data: '2026-10-03T08:00:00.000',
      ),
    );
    await StorageService.salvarCorrida(
      CorridaModel(
        id: 'run-later',
        distancia: 2,
        segundos: 600,
        data: '2026-10-03T09:00:00.000',
      ),
    );

    final history = await StorageService.carregarCorridas();
    expect(history.map((run) => run.id), ['run-later', 'run-earlier']);

    await StorageService.removerCorrida(0);
    expect((await StorageService.carregarCorridas()).map((run) => run.id), [
      'run-earlier',
    ]);
  });
}
