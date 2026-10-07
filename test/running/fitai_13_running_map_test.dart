import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/activities/application/running_map_controller.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/services/running_location_source.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fitai_04_running_gps_route_test.dart' show FakeLocationSource;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeLocationSource source;
  late RunningSessionService service;
  late RunningMapController map;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 6, 12);
    source = FakeLocationSource();
    service = RunningSessionService.forTesting(
      locationSource: source,
      clock: () => now,
    );
    await service.start();
    await Future<void>.delayed(Duration.zero);
    map = RunningMapController(service);
  });

  tearDown(() async {
    map.dispose();
    service.dispose();
    await Future<void>.delayed(Duration.zero);
    await source.dispose();
  });

  void point(double longitude, {double accuracy = 5}) => source.add(
    RunningLocationSample(
      latitude: 0,
      longitude: longitude,
      timestamp: now,
      accuracy: accuracy,
    ),
  );

  test('RUN-MAP-01 accepted point updates current position', () {
    point(0);
    expect(identical(map.currentPosition, service.route.last), isTrue);
    expect(map.pointCount, 1);
  });
  test('RUN-MAP-02 rejected sample never enters map', () {
    point(0);
    now = now.add(const Duration(seconds: 1));
    point(1);
    point(0.00001, accuracy: 100);
    expect(map.pointCount, 1);
    expect(map.currentPosition!.longitude, 0);
  });
  test('RUN-MAP-03 preserves canonical order and identity', () {
    point(0);
    now = now.add(const Duration(seconds: 10));
    point(0.0001);
    expect(map.segments.single, orderedEquals(service.route));
    expect(map.processedPointCount, 2);
  });
  test('RUN-MAP-04 pause retains route without appending movement', () async {
    point(0);
    await service.pause();
    now = now.add(const Duration(minutes: 5));
    point(0.05);
    expect(map.pointCount, 1);
    expect(map.currentPosition!.longitude, 0);
  });
  test('RUN-MAP-05 resume starts a segment without bridge', () async {
    point(0);
    await service.pause();
    now = now.add(const Duration(minutes: 5));
    await service.resume();
    await Future<void>.delayed(Duration.zero);
    point(0.05);
    now = now.add(const Duration(seconds: 10));
    point(0.0501);
    expect(map.segments.map((s) => s.length), [1, 2]);
    expect(service.distanceKm, lessThan(0.02));
  });
  test('RUN-MAP-06 / RECOVERY-01/02 persisted route restores once', () async {
    point(0);
    now = now.add(const Duration(seconds: 10));
    point(0.0001);
    await service.pause();
    map.dispose();
    service.dispose();
    await Future<void>.delayed(Duration.zero);
    service = RunningSessionService.forTesting(
      locationSource: source,
      clock: () => now,
    );
    await service.initialize();
    map = RunningMapController(service);
    expect(map.segments.single, hasLength(2));
    await service.initialize();
    expect(map.pointCount, 2);
    expect(map.processedPointCount, 2);
  });
  test(
    'RUN-MAP-07 / RECOVERY-03 map mounting does not subscribe GPS',
    () async {
      point(0);
      final requests = source.streamRequests;
      final otherMap = RunningMapController(service);
      otherMap.dispose();
      await service.initialize();
      expect(source.streamRequests, requests);
      expect(source.activeListeners, 1);
    },
  );
  test('RUN-MAP-CAM-01 first accepted point requests centering', () {
    expect(map.cameraRevision, 0);
    point(0);
    expect(map.cameraRevision, 1);
  });
  test('RUN-MAP-CAM-02 follow updates camera revision', () {
    point(0);
    now = now.add(const Duration(seconds: 10));
    point(0.0001);
    expect(map.cameraRevision, 2);
  });
  test('RUN-MAP-CAM-03 manual interaction disables follow', () {
    point(0);
    map.manualCameraInteraction();
    final revision = map.cameraRevision;
    now = now.add(const Duration(seconds: 10));
    point(0.0001);
    expect(map.followUser, isFalse);
    expect(map.cameraRevision, revision);
  });
  test('RUN-MAP-CAM-04 recenter restores follow', () {
    point(0);
    map.manualCameraInteraction();
    map.recenter();
    expect(map.followUser, isTrue);
    expect(map.cameraRevision, 2);
  });
  test(
    'RUN-MAP-FALLBACK-01 provider failure cannot block running core',
    () async {
      point(0);
      map.reportAvailability(RunningMapAvailability.unavailable);
      now = now.add(const Duration(minutes: 1));
      await service.pause();
      await service.resume();
      expect(service.isRunning, isTrue);
      expect(await service.finish(), isNotNull);
      expect(await StorageService.carregarCorridas(), hasLength(1));
    },
  );
  for (final status in [
    RunningLocationStatus.permissionDenied,
    RunningLocationStatus.permissionDeniedForever,
    RunningLocationStatus.serviceDisabled,
  ]) {
    test('RUN-MAP-FALLBACK-03/04 uses core status ${status.name}', () async {
      await service.pause();
      source.status = status;
      await service.resume();
      await Future<void>.delayed(Duration.zero);
      expect(map.locationStatus, status);
      expect(service.isRunning, isTrue);
    });
  }
  test(
    'RUN-MAP-PERF-01 1001 restored points plus incremental update',
    () async {
      await service.pause();
      final route = List.generate(
        1001,
        (i) => RunningRoutePointModel(
          latitude: 0,
          longitude: i * 0.00001,
          accuracy: 5,
          altitude: 0,
          speed: 1,
          timestamp: now.add(Duration(seconds: i)).toIso8601String(),
          startsSegment: i == 0,
          cumulativeDistanceKm: i * 0.001,
          activeElapsedSeconds: i,
        ),
      );
      await StorageService.salvarRunningSessionAtiva(
        service.session!.copyWith(route: route),
      );
      map.dispose();
      service.dispose();
      await Future<void>.delayed(Duration.zero);
      service = RunningSessionService.forTesting(
        locationSource: source,
        clock: () => now,
      );
      await service.initialize();
      map = RunningMapController(service);
      expect(map.pointCount, 1001);
      expect(map.processedPointCount, 1001);
      now = now.add(const Duration(seconds: 1002));
      await service.resume();
      await Future<void>.delayed(Duration.zero);
      point(0.0101);
      expect(map.pointCount, 1002);
      expect(map.processedPointCount, 1002);
      expect(map.segments.map((s) => s.length), [1001, 1]);
    },
  );
  test('RUN-MAP lifecycle dispose leaves canonical subscription running', () {
    point(0);
    map.dispose();
    expect(source.activeListeners, 1);
    map = RunningMapController(service);
    expect(map.pointCount, 1);
  });
  test('RUN-MAP legacy continuity is not invented', () async {
    await service.pause();
    await StorageService.salvarRunningSessionAtiva(
      service.session!.copyWith(
        route: [
          RunningRoutePointModel(
            latitude: 0,
            longitude: 0,
            accuracy: 5,
            altitude: 0,
            speed: 0,
            timestamp: now.toIso8601String(),
          ),
          RunningRoutePointModel(
            latitude: 0,
            longitude: 1,
            accuracy: 5,
            altitude: 0,
            speed: 0,
            timestamp: now.add(const Duration(seconds: 1)).toIso8601String(),
          ),
        ],
      ),
    );
    map.dispose();
    service.dispose();
    await Future<void>.delayed(Duration.zero);
    service = RunningSessionService.forTesting(clock: () => now);
    await service.initialize();
    map = RunningMapController(service);
    expect(map.segments.map((s) => s.length), [1, 1]);
  });
  test('RUN-MAP user change clears previous route before new session', () {
    point(0);
    AccountSessionLifecycle.revision.value++;
    expect(map.pointCount, 0);
    expect(map.currentPosition, isNull);
    now = now.add(const Duration(seconds: 10));
    point(0.0001);
    expect(map.pointCount, 0);
  });
}
