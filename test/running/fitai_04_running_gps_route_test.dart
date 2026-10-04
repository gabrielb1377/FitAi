import 'dart:async';

import 'package:fitai/services/running_location_source.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'RUN-GPS-01/02/03/04: fonte falsa alimenta distância e rota ordenada',
    () async {
      var now = DateTime.utc(2026, 10, 4, 8);
      final source = FakeLocationSource();
      final service = _service(source, () => now);

      await _startAndConnect(service);
      expect(source.activeListeners, 1);

      source.add(_sample(0, 0, now));
      expect(service.distanceKm, 0);

      now = now.add(const Duration(minutes: 5));
      source.add(_sample(0, 0.009, now));

      expect(service.distanceKm, greaterThan(0.9));
      expect(service.route.map((point) => point.timestamp), [
        DateTime.utc(2026, 10, 4, 8).toIso8601String(),
        now.toIso8601String(),
      ]);
      await _dispose(service, source);
    },
  );

  test(
    'RUN-GPS-05/06/07/08/09: samples inválidos não mudam rota ou métricas',
    () async {
      final now = DateTime.utc(2026, 10, 4, 8);
      final source = FakeLocationSource();
      final service = _service(source, () => now);
      await _startAndConnect(service);

      source.add(_sample(0, 0, now));
      final originalRoute = service.route.length;
      final originalDistance = service.distanceKm;
      source
        ..add(_sample(91, 0, now.add(const Duration(seconds: 1))))
        ..add(_sample(0, 181, now.add(const Duration(seconds: 2))))
        ..add(_sample(double.nan, 0, now.add(const Duration(seconds: 3))))
        ..add(_sample(0, double.infinity, now.add(const Duration(seconds: 4))))
        ..add(_sample(0, 0.01, now.subtract(const Duration(seconds: 1))));

      expect(service.route, hasLength(originalRoute));
      expect(service.distanceKm, originalDistance);
      await _dispose(service, source);
    },
  );

  test(
    'RUN-GPS-10/11: baixa precisão e salto impossível são filtrados',
    () async {
      var now = DateTime.utc(2026, 10, 4, 8);
      final source = FakeLocationSource();
      final service = _service(source, () => now);
      await _startAndConnect(service);

      source.add(_sample(0, 0, now));
      now = now.add(const Duration(minutes: 1));
      source.add(_sample(0, 0.01, now, accuracy: 61));
      expect(service.route, hasLength(1));

      now = now.add(const Duration(minutes: 1));
      source.add(_sample(1, 1, now));
      expect(service.route, hasLength(1));
      expect(service.distanceKm, 0);
      await _dispose(service, source);
    },
  );

  test(
    'RUN-GPS-12/13/14: pausa bloqueia amostras e retomada não cria ponte',
    () async {
      var now = DateTime.utc(2026, 10, 4, 8);
      final source = FakeLocationSource();
      final service = _service(source, () => now);
      await _startAndConnect(service);
      final id = service.session!.id;

      source.add(_sample(0, 0, now));
      final beforePauseDistance = service.distanceKm;
      await service.pause();
      expect(source.activeListeners, 0);
      source.add(_sample(0, 0.09, now.add(const Duration(minutes: 10))));
      expect(service.distanceKm, beforePauseDistance);

      now = now.add(const Duration(minutes: 10));
      await service.resume();
      await _settle();
      source.add(_sample(0, 0.09, now));
      expect(service.distanceKm, beforePauseDistance);

      now = now.add(const Duration(minutes: 2));
      source.add(_sample(0, 0.0901, now));
      expect(service.distanceKm, greaterThan(beforePauseDistance));
      expect(service.distanceKm, lessThan(0.1));
      expect(service.session!.id, id);
      await _dispose(service, source);
    },
  );

  test(
    'RUN-GPS-15/16/17/18: rota e distância sobrevivem ao recovery ativo',
    () async {
      var now = DateTime.utc(2026, 10, 4, 8);
      final firstSource = FakeLocationSource();
      final first = _service(firstSource, () => now);
      await _startAndConnect(first);
      final id = first.session!.id;
      firstSource.add(_sample(0, 0, now));
      now = now.add(const Duration(minutes: 5));
      firstSource.add(_sample(0, 0.009, now));
      await _settle();
      final originalDistance = first.distanceKm;
      final originalRoute = List.of(first.route);
      first.dispose();
      await firstSource.dispose();

      now = now.add(const Duration(minutes: 1));
      final recoveredSource = FakeLocationSource();
      final recovered = _service(recoveredSource, () => now);
      await recovered.initialize();
      await _settle();

      expect(recovered.session!.id, id);
      expect(recovered.distanceKm, originalDistance);
      expect(
        recovered.route.map((point) => point.timestamp),
        originalRoute.map((point) => point.timestamp),
      );
      expect(recoveredSource.activeListeners, 1);

      recoveredSource.add(_sample(0, 0.018, now));
      expect(recovered.distanceKm, originalDistance);
      expect(recovered.route, hasLength(originalRoute.length + 1));
      await _dispose(recovered, recoveredSource);
    },
  );

  test(
    'RUN-GPS-19: recovery pausado não volta a capturar localização',
    () async {
      final now = DateTime.utc(2026, 10, 4, 8);
      final firstSource = FakeLocationSource();
      final first = _service(firstSource, () => now);
      await _startAndConnect(first);
      firstSource.add(_sample(0, 0, now));
      await first.pause();
      first.dispose();
      await firstSource.dispose();

      final recoveredSource = FakeLocationSource();
      final recovered = _service(recoveredSource, () => now);
      await recovered.initialize();
      await _settle();
      recoveredSource.add(
        _sample(0, 0.009, now.add(const Duration(minutes: 1))),
      );

      expect(recovered.isPaused, isTrue);
      expect(recoveredSource.streamRequests, 0);
      expect(recovered.route, hasLength(1));
      await _dispose(recovered, recoveredSource);
    },
  );

  test(
    'RUN-GPS-20/21/22: finalizar cancela tracking, preserva rota e é idempotente',
    () async {
      var now = DateTime.utc(2026, 10, 4, 8);
      final source = FakeLocationSource();
      final service = _service(source, () => now);
      await _startAndConnect(service);
      source.add(_sample(0, 0, now));
      now = now.add(const Duration(minutes: 5));
      source.add(_sample(0, 0.009, now));
      final routeBeforeFinish = List.of(service.route);

      final completed = await service.finish();
      source.add(_sample(0, 0.018, now.add(const Duration(minutes: 5))));

      expect(source.activeListeners, 0);
      expect(
        completed!.route.map((point) => point.timestamp),
        routeBeforeFinish.map((point) => point.timestamp),
      );
      expect(await service.finish(), isNull);
      expect(await StorageService.carregarCorridas(), hasLength(1));
      await source.dispose();
    },
  );

  test(
    'RUN-GPS-23/24: descarte cancela tracking e não ressuscita no recovery',
    () async {
      final now = DateTime.utc(2026, 10, 4, 8);
      final source = FakeLocationSource();
      final service = _service(source, () => now);
      await _startAndConnect(service);
      source.add(_sample(0, 0, now));
      await service.discardActiveSession();

      expect(source.activeListeners, 0);
      final recovered = RunningSessionService.forTesting(clock: () => now);
      await recovered.initialize();
      expect(recovered.hasActiveSession, isFalse);
      recovered.dispose();
      await source.dispose();
    },
  );

  test(
    'RUN-GPS-25/26/27: permission e serviço indisponíveis preservam a sessão',
    () async {
      for (final status in [
        RunningLocationStatus.permissionDenied,
        RunningLocationStatus.permissionDeniedForever,
        RunningLocationStatus.serviceDisabled,
      ]) {
        final now = DateTime.utc(2026, 10, 4, 8);
        final source = FakeLocationSource(status: status);
        final service = _service(source, () => now);
        await _startAndConnect(service);

        expect(service.hasActiveSession, isTrue);
        expect(service.locationStatus, status);
        expect(service.gpsConnected, isFalse);
        expect(source.activeListeners, 0);
        await service.discardActiveSession();
        await _dispose(service, source);
      }
    },
  );

  test(
    'RUN-GPS-28: lifecycle não duplica assinatura e dispose a encerra',
    () async {
      final now = DateTime.utc(2026, 10, 4, 8);
      final source = FakeLocationSource();
      final service = _service(source, () => now);
      await _startAndConnect(service);
      await service.initialize();

      expect(source.streamRequests, 1);
      expect(source.activeListeners, 1);
      service.dispose();
      await _settle();
      expect(source.activeListeners, 0);
      await source.dispose();
    },
  );

  test('RUN-GPS-29: tracking offline persiste rota local sem rede', () async {
    var now = DateTime.utc(2026, 10, 4, 8);
    final source = FakeLocationSource();
    final service = _service(source, () => now);
    await _startAndConnect(service);
    source.add(_sample(0, 0, now));
    now = now.add(const Duration(minutes: 5));
    source.add(_sample(0, 0.009, now));
    await _settle();
    await service.pause();

    final stored = await StorageService.carregarRunningSessionAtiva();
    expect(stored, isNotNull);
    expect(stored!.route, hasLength(2));
    expect(stored.distanceKm, greaterThan(0.9));
    await _dispose(service, source);
  });

  test('RUN-GPS-30: duas corridas não misturam pontos de rota', () async {
    var now = DateTime.utc(2026, 10, 4, 8);
    final source = FakeLocationSource();
    final service = _service(source, () => now);
    await _startAndConnect(service);
    source.add(_sample(0, 0, now));
    now = now.add(const Duration(minutes: 5));
    source.add(_sample(0, 0.009, now));
    final first = await service.finish();

    now = now.add(const Duration(minutes: 1));
    await service.start();
    await _settle();
    source.add(_sample(10, 10, now));

    expect(first!.route, hasLength(2));
    expect(service.route, hasLength(1));
    expect(service.route.single.latitude, 10);
    await _dispose(service, source);
  });
}

RunningSessionService _service(
  FakeLocationSource source,
  DateTime Function() clock,
) => RunningSessionService.forTesting(locationSource: source, clock: clock);

Future<void> _startAndConnect(RunningSessionService service) async {
  await service.start();
  await _settle();
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Future<void> _dispose(
  RunningSessionService service,
  FakeLocationSource source,
) async {
  service.dispose();
  await _settle();
  await source.dispose();
}

RunningLocationSample _sample(
  double latitude,
  double longitude,
  DateTime timestamp, {
  double? accuracy = 5,
  double? altitude = 0,
  double? speedMps = 0,
}) => RunningLocationSample(
  latitude: latitude,
  longitude: longitude,
  timestamp: timestamp,
  accuracy: accuracy,
  altitude: altitude,
  speedMps: speedMps,
);

class FakeLocationSource implements RunningLocationSource {
  FakeLocationSource({this.status = RunningLocationStatus.available}) {
    _controller = StreamController<RunningLocationSample>.broadcast(
      sync: true,
      onListen: () => activeListeners += 1,
      onCancel: () => activeListeners -= 1,
    );
  }

  RunningLocationStatus status;
  late final StreamController<RunningLocationSample> _controller;
  int streamRequests = 0;
  int activeListeners = 0;

  @override
  Future<RunningLocationStatus> ensureReady() async => status;

  @override
  Stream<RunningLocationSample> get samples {
    streamRequests += 1;
    return _controller.stream;
  }

  void add(RunningLocationSample sample) => _controller.add(sample);

  Future<void> dispose() => _controller.close();
}
