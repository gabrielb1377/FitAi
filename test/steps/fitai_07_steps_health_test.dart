import 'dart:async';

import 'package:fitai/features/activities/domain/steps_day_policy.dart';
import 'package:fitai/features/activities/domain/steps_health_source.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/profile/domain/profile_models.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/services/steps_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Steps Core', () {
    test('STEPS-CORE-01 snapshot diario persiste', () async {
      final fake = FakeStepsHealthSource(totalSteps: 4321);
      final service = _service(fake: fake);

      await service.refreshFromHealth();

      final stored = await StorageService.carregarDailyStepsHistory();
      expect(stored.single.steps, 4321);
      expect(stored.single.date, '2026-10-05');
    });

    test('STEPS-CORE-02 steps nunca sao negativos', () async {
      final record = _record(steps: -10);
      final service = _service(fake: FakeStepsHealthSource(totalSteps: -1));

      await service.refreshFromHealth();

      expect(record.steps, 0);
      expect(service.stepsToday, 0);
      expect(() => service.recordManualSteps(steps: -1), throwsArgumentError);
    });

    test('STEPS-CORE-03 import 5000 resulta em 5000', () async {
      final service = _service(fake: FakeStepsHealthSource(totalSteps: 5000));
      await service.refreshFromHealth();
      expect(service.stepsToday, 5000);
    });

    test('STEPS-CORE-04 reimport 5000 continua 5000', () async {
      final fake = FakeStepsHealthSource(totalSteps: 5000);
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      await service.refreshFromHealth();
      expect(service.stepsToday, 5000);
      expect(service.history, hasLength(1));
      expect(service.today.version, 1);
    });

    test('STEPS-CORE-05 5000 para 6200 resulta em 6200', () async {
      final fake = FakeStepsHealthSource(totalSteps: 5000);
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      fake.totalSteps = 6200;
      await service.refreshFromHealth();
      expect(service.stepsToday, 6200);
      expect(service.today.version, 2);
    });

    test('STEPS-CORE-06 correcao 6200 para 5900 substitui total', () async {
      final fake = FakeStepsHealthSource(totalSteps: 6200);
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      fake.totalSteps = 5900;
      await service.refreshFromHealth();
      expect(service.stepsToday, 5900);
      expect(service.history, hasLength(1));
    });

    test('STEPS-CORE-07 restart preserva snapshot', () async {
      final first = _service(fake: FakeStepsHealthSource(totalSteps: 6100));
      await first.refreshFromHealth();

      final restored = _service(fake: FakeStepsHealthSource(totalSteps: null));
      await restored.initialize();

      expect(restored.stepsToday, 6100);
      expect(restored.today.sourceKind, DailyStepsSource.healthConnect);
    });

    test('STEPS-CORE-08 offline preserva snapshot', () async {
      final fake = FakeStepsHealthSource(totalSteps: 7000);
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      fake.error = StateError('provider offline');

      await service.refreshFromHealth();

      expect(service.stepsToday, 7000);
      expect(service.statusMessage, contains('ultimo valor foi mantido'));
    });

    test('STEPS-CORE-09 provider indisponivel nao inventa dados', () async {
      final fake = FakeStepsHealthSource(
        status: const StepsHealthStatus(
          provider: StepsHealthProvider.healthConnect,
          platformSupported: true,
          available: false,
          permission: StepsHealthPermissionState.unavailable,
          message: 'Indisponivel.',
        ),
        totalSteps: 9999,
      );
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      expect(service.hasTodayRecord, isFalse);
      expect(service.stepsToday, 0);
    });

    test('STEPS-CORE-10 denied nao destroi estado valido', () async {
      final fake = FakeStepsHealthSource(totalSteps: 8123);
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      fake.currentStatus = const StepsHealthStatus(
        provider: StepsHealthProvider.healthConnect,
        platformSupported: true,
        available: true,
        permission: StepsHealthPermissionState.denied,
        message: 'Permissao negada.',
      );

      await service.refreshFromHealth(requestPermission: true);

      expect(service.stepsToday, 8123);
      expect(service.permissionGranted, isFalse);
    });

    test('STEPS-CORE-11 user A nao ve snapshot de B', () async {
      final userA = _service(
        fake: FakeStepsHealthSource(totalSteps: 1111),
        userId: 'user-a',
      );
      await userA.refreshFromHealth();
      final userB = _service(
        fake: FakeStepsHealthSource(totalSteps: null),
        userId: 'user-b',
      );
      await userB.initialize();

      expect(userA.stepsToday, 1111);
      expect(userB.history, isEmpty);
      expect(userB.stepsToday, 0);
    });

    test('STEPS-CORE-12 aggregate de provider nao faz double count', () async {
      final fake = FakeStepsHealthSource(totalSteps: 4500);
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      fake.currentStatus = const StepsHealthStatus(
        provider: StepsHealthProvider.healthKit,
        platformSupported: true,
        available: true,
        permission: StepsHealthPermissionState.granted,
        message: 'Apple Health conectado.',
      );
      await service.refreshFromHealth();

      expect(service.stepsToday, 4500);
      expect(service.history, hasLength(1));
      expect(service.today.sourceKind, DailyStepsSource.healthKit);
    });
  });

  group('Day and timezone', () {
    test('STEPS-DAY-01 23:59 permanece no dia A', () {
      const policy = StepsDayPolicy();
      expect(policy.dayKey(DateTime(2026, 10, 5, 23, 59)), '2026-10-05');
    });

    test('STEPS-DAY-02 00:00 cria dia B', () {
      const policy = StepsDayPolicy();
      expect(policy.dayKey(DateTime(2026, 10, 6)), '2026-10-06');
    });

    test('STEPS-DAY-03 passos de A nao entram em B', () async {
      var now = DateTime(2026, 10, 5, 23, 59);
      final fake = FakeStepsHealthSource(totalSteps: 5000);
      final service = _service(fake: fake, now: () => now);
      await service.refreshFromHealth();
      now = DateTime(2026, 10, 6);
      fake.totalSteps = 25;
      await service.refreshFromHealth();

      expect(service.history, hasLength(2));
      expect(service.stepsToday, 25);
      expect(
        service.history.firstWhere((item) => item.date == '2026-10-05').steps,
        5000,
      );
    });

    test(
      'STEPS-DAY-04 restart apos meia-noite seleciona dia correto',
      () async {
        var now = DateTime(2026, 10, 5, 23, 59);
        final first = _service(
          fake: FakeStepsHealthSource(totalSteps: 3210),
          now: () => now,
        );
        await first.refreshFromHealth();
        now = DateTime(2026, 10, 6, 0, 1);
        final restored = _service(
          fake: FakeStepsHealthSource(totalSteps: null),
          now: () => now,
        );
        await restored.initialize();

        expect(restored.hasTodayRecord, isFalse);
        expect(restored.history.single.date, '2026-10-05');
      },
    );

    test('STEPS-DAY-05 mesmo UTC respeita timezone local', () {
      final instant = DateTime.utc(2026, 10, 6, 1);
      final west = StepsDayPolicy(
        offsetForInstant: (_) => const Duration(hours: -3),
      );
      final east = StepsDayPolicy(
        offsetForInstant: (_) => const Duration(hours: 2),
      );
      expect(west.dayKey(instant), '2026-10-05');
      expect(east.dayKey(instant), '2026-10-06');
    });

    test('STEPS-DAY-06 dayKey e deterministico', () {
      final policy = StepsDayPolicy(
        offsetForInstant: (_) => const Duration(hours: -3),
      );
      final instant = DateTime.utc(2026, 10, 6, 1, 30);
      expect(policy.dayKey(instant), policy.dayKey(instant));
      expect(policy.rangeFor(instant).dayKey, '2026-10-05');
    });

    test(
      'STEPS-DAY-07 timezone nao reescreve recompensa identificada',
      () async {
        var offset = const Duration(hours: -3);
        final store = InMemoryProgressionStore();
        final engine = _engine(store: store);
        final policy = StepsDayPolicy(offsetForInstant: (_) => offset);
        final service = _service(
          fake: FakeStepsHealthSource(totalSteps: 10000),
          dayPolicy: policy,
          now: () => DateTime.utc(2026, 10, 6, 1, 30),
          engine: engine,
        );
        await service.refreshFromHealth();
        offset = const Duration(hours: -2);
        await service.refreshLocal();

        expect(await _stepsEvents(engine), hasLength(1));
        expect((await _stepsEvents(engine)).single.sourceId, '2026-10-05');
      },
    );
  });

  group('Health boundary', () {
    test('STEPS-HEALTH-01 FakeStepsHealthSource funciona', () async {
      final fake = FakeStepsHealthSource(totalSteps: 1234);
      final result = await fake.readDailyTotal(
        start: DateTime(2026, 10, 5),
        end: DateTime(2026, 10, 6),
      );
      expect(result.totalSteps, 1234);
      expect(fake.reads, 1);
    });

    test('STEPS-HEALTH-02 granted permite leitura', () async {
      final service = _service(fake: FakeStepsHealthSource(totalSteps: 2345));
      final result = await service.refreshFromHealth();
      expect(result.hasSnapshot, isTrue);
      expect(service.permissionGranted, isTrue);
    });

    test('STEPS-HEALTH-03 denied e tratado', () async {
      final service = _service(
        fake: FakeStepsHealthSource(
          status: const StepsHealthStatus(
            provider: StepsHealthProvider.healthConnect,
            platformSupported: true,
            available: true,
            permission: StepsHealthPermissionState.denied,
            message: 'Permissao negada.',
          ),
          totalSteps: 3000,
        ),
      );
      final result = await service.refreshFromHealth(requestPermission: true);
      expect(result.hasSnapshot, isFalse);
      expect(
        service.healthStatus.permission,
        StepsHealthPermissionState.denied,
      );
    });

    test('STEPS-HEALTH-04 permanently denied e tratado', () async {
      final service = _service(
        fake: FakeStepsHealthSource(
          status: const StepsHealthStatus(
            provider: StepsHealthProvider.healthConnect,
            platformSupported: true,
            available: true,
            permission: StepsHealthPermissionState.permanentlyDenied,
            message: 'Permissao bloqueada nas configuracoes.',
          ),
          totalSteps: 3000,
        ),
      );
      await service.refreshFromHealth(requestPermission: true);
      expect(
        service.healthStatus.permission,
        StepsHealthPermissionState.permanentlyDenied,
      );
      expect(service.hasTodayRecord, isFalse);
    });

    test('STEPS-HEALTH-05 unavailable e tratado', () async {
      final service = _service(
        fake: FakeStepsHealthSource(
          status: const StepsHealthStatus.notSupported(),
          totalSteps: 3000,
        ),
      );
      await service.refreshFromHealth();
      expect(service.platformSupported, isFalse);
      expect(service.hasTodayRecord, isFalse);
    });

    test('STEPS-HEALTH-06 erro temporario nao zera snapshot', () async {
      final fake = FakeStepsHealthSource(totalSteps: 6789);
      final service = _service(fake: fake);
      await service.refreshFromHealth();
      fake.error = TimeoutException('temporary');
      await service.refreshFromHealth();
      expect(service.stepsToday, 6789);
    });

    test('STEPS-HEALTH-07 refresh concorrente nao duplica leitura', () async {
      final fake = FakeStepsHealthSource(totalSteps: 7000);
      final service = _service(fake: fake);
      await Future.wait([
        service.refreshFromHealth(),
        service.refreshFromHealth(),
      ]);
      expect(fake.reads, 1);
      expect(service.history, hasLength(1));
    });

    test(
      'STEPS-HEALTH-08 dispose/recreate nao duplica subscriptions',
      () async {
        final firstFake = FakeStepsHealthSource(totalSteps: 1000);
        final first = _service(fake: firstFake);
        await first.refreshFromHealth();
        first.dispose();
        await Future<void>.delayed(Duration.zero);

        final secondFake = FakeStepsHealthSource(totalSteps: 1000);
        final second = _service(fake: secondFake);
        await second.refreshFromHealth();

        expect(firstFake.disposals, 1);
        expect(firstFake.reads, 1);
        expect(secondFake.reads, 1);
      },
    );
  });

  group('Steps XP', () {
    test('STEPS-XP-01 antes da meta nao concede XP', () async {
      final engine = _engine(store: InMemoryProgressionStore());
      final service = _service(
        fake: FakeStepsHealthSource(totalSteps: 9999),
        engine: engine,
      );
      await service.refreshFromHealth();
      expect(await _stepsEvents(engine), isEmpty);
    });

    test('STEPS-XP-02 meta concede exatamente 8 XP', () async {
      final engine = _engine(store: InMemoryProgressionStore());
      final service = _service(
        fake: FakeStepsHealthSource(totalSteps: 10000),
        engine: engine,
      );
      await service.refreshFromHealth();
      final events = await _stepsEvents(engine);
      expect(events, hasLength(1));
      expect(events.single.amount, 8);
    });

    test('STEPS-XP-03 refresh nao concede novamente', () async {
      final engine = _engine(store: InMemoryProgressionStore());
      final fake = FakeStepsHealthSource(totalSteps: 10000);
      final service = _service(fake: fake, engine: engine);
      await service.refreshFromHealth();
      await service.refreshFromHealth();
      expect(await _stepsEvents(engine), hasLength(1));
    });

    test('STEPS-XP-04 restart nao concede novamente', () async {
      final store = InMemoryProgressionStore();
      final engine = _engine(store: store);
      final first = _service(
        fake: FakeStepsHealthSource(totalSteps: 10000),
        engine: engine,
      );
      await first.refreshFromHealth();
      final restored = _service(
        fake: FakeStepsHealthSource(totalSteps: 10000),
        engine: engine,
      );
      await restored.refreshFromHealth();
      expect(await _stepsEvents(engine), hasLength(1));
    });

    test('STEPS-XP-05 reimport nao concede novamente', () async {
      final engine = _engine(store: InMemoryProgressionStore());
      final fake = FakeStepsHealthSource(totalSteps: 10000);
      final service = _service(fake: fake, engine: engine);
      await service.refreshFromHealth();
      fake.totalSteps = 9000;
      await service.refreshFromHealth();
      fake.totalSteps = 10000;
      await service.refreshFromHealth();
      expect(await _stepsEvents(engine), hasLength(1));
    });

    test('STEPS-XP-06 sync remoto do mesmo evento nao duplica', () async {
      final gateway = _EchoProgressionGateway();
      final engine = _engine(
        store: InMemoryProgressionStore(),
        gateway: gateway,
      );
      final service = _service(
        fake: FakeStepsHealthSource(totalSteps: 10000),
        engine: engine,
      );
      await service.refreshFromHealth();
      await engine.syncRemote(userId: 'local');
      await engine.syncRemote(userId: 'local');

      final events = await _stepsEvents(engine);
      expect(events, hasLength(1));
      expect(events.single.syncStatus, ProgressionSyncStatus.synced);
    });

    test('STEPS-XP-07 novo dia elegivel cria novo evento', () async {
      var now = DateTime(2026, 10, 5, 12);
      final engine = _engine(store: InMemoryProgressionStore(), now: () => now);
      final fake = FakeStepsHealthSource(totalSteps: 10000);
      final service = _service(fake: fake, engine: engine, now: () => now);
      await service.refreshFromHealth();
      now = DateTime(2026, 10, 6, 12);
      await service.refreshFromHealth();
      expect(await _stepsEvents(engine), hasLength(2));
    });

    test('STEPS-XP-08 correcao do provider nao cria segundo evento', () async {
      final engine = _engine(store: InMemoryProgressionStore());
      final fake = FakeStepsHealthSource(totalSteps: 10000);
      final service = _service(fake: fake, engine: engine);
      await service.refreshFromHealth();
      fake.totalSteps = 8500;
      await service.refreshFromHealth();
      fake.totalSteps = 10500;
      await service.refreshFromHealth();
      expect(await _stepsEvents(engine), hasLength(1));
    });

    test('STEPS-XP-09 eventos sao isolados entre A e B', () async {
      final store = InMemoryProgressionStore();
      final engine = _engine(store: store);
      final userA = _service(
        fake: FakeStepsHealthSource(totalSteps: 10000),
        engine: engine,
        userId: 'user-a',
      );
      final userB = _service(
        fake: FakeStepsHealthSource(totalSteps: 10000),
        engine: engine,
        userId: 'user-b',
      );
      await userA.refreshFromHealth();
      await userB.refreshFromHealth();

      expect(await _stepsEvents(engine, userId: 'user-a'), hasLength(1));
      expect(await _stepsEvents(engine, userId: 'user-b'), hasLength(1));
    });

    test('STEPS-XP-10 rebuilds de Home/Profile nao concedem XP', () async {
      final engine = _engine(store: InMemoryProgressionStore());
      final service = _service(
        fake: FakeStepsHealthSource(totalSteps: 10000),
        engine: engine,
      );
      await service.refreshFromHealth();

      for (var index = 0; index < 3; index += 1) {
        service.stepsToday;
        service.progressToday;
        service.history;
      }
      final profile = ProfileRepository(
        planHistoryLoader: () async => const PlanWorkoutHistorySnapshot.empty(),
        profileValuesLoader: () async => const {},
        runsLoader: () async => const [],
        stepsLoader: () async => service.history,
        favoritesLoader: () async => const {},
        preferencesLoader: () async => const UserPreferences.unavailable(),
        legacyHistoryLoader: () async => const [],
        progressionEngine: engine,
      );
      await profile.load();
      await profile.load();

      expect(await _stepsEvents(engine), hasLength(1));
    });
  });
}

StepsService _service({
  required FakeStepsHealthSource fake,
  DateTime Function()? now,
  StepsDayPolicy? dayPolicy,
  ProgressionEngine? engine,
  String userId = 'local',
}) {
  return StepsService.forTesting(
    now: now ?? () => DateTime(2026, 10, 5, 12),
    healthSource: fake,
    dayPolicy: dayPolicy,
    userIdResolver: () async => userId,
    progressionEngine: engine ?? _engine(store: InMemoryProgressionStore()),
  );
}

ProgressionEngine _engine({
  required InMemoryProgressionStore store,
  DateTime Function()? now,
  ProgressionRemoteGateway? gateway,
}) {
  return ProgressionEngine(
    store: store,
    legacyReader: () async => const LegacyProgression(level: 1, xpIntoLevel: 0),
    legacyWriter: (_) async {},
    clock: now ?? () => DateTime(2026, 10, 5, 12),
    remoteGateway: gateway,
    autoSync: false,
  );
}

Future<List<XpEvent>> _stepsEvents(
  ProgressionEngine engine, {
  String userId = 'local',
}) async {
  final snapshot = await engine.load(userId: userId);
  return snapshot.events
      .where((event) => event.sourceType == XpSourceType.stepsGoal)
      .toList(growable: false);
}

DailyStepsModel _record({required int steps}) => DailyStepsModel(
  date: '2026-10-05',
  steps: steps,
  goal: 10000,
  source: DailyStepsModel.sourceLocal,
  recordedAt: DateTime(2026, 10, 5, 8),
  updatedAt: DateTime(2026, 10, 5, 8),
);

class _EchoProgressionGateway implements ProgressionRemoteGateway {
  final Map<String, ProgressionRemoteEvent> _events = {};

  @override
  Future<ProgressionRemotePushResponse?> push({
    required String userId,
    required List<XpEvent> events,
    required String afterRevision,
  }) async {
    final accepted = <ProgressionRemoteAckItem>[];
    final alreadyApplied = <ProgressionRemoteAckItem>[];
    for (final event in events) {
      final key = '${event.sourceType.name}:${event.sourceId}';
      final existing = _events[key];
      if (existing != null) {
        alreadyApplied.add(_ack(event.id, existing));
        continue;
      }
      final remote = ProgressionRemoteEvent(
        eventId: event.id,
        sourceType: event.sourceType,
        sourceId: event.sourceId,
        xpAwarded: event.amount,
        rulesVersion: ProgressionRemoteContract.rulesVersion,
        occurredAt: event.createdAt,
        revision: '${_events.length + 1}',
      );
      _events[key] = remote;
      accepted.add(_ack(event.id, remote));
    }
    return ProgressionRemotePushResponse(
      acknowledgement: ProgressionRemoteAcknowledgement(
        accepted: accepted,
        alreadyApplied: alreadyApplied,
        rejected: const [],
      ),
      state: _state(),
    );
  }

  @override
  Future<ProgressionRemoteState?> pull({
    required String userId,
    required String afterRevision,
  }) async => _state();

  ProgressionRemoteState _state() => ProgressionRemoteState(
    revision: '${_events.length}',
    events: _events.values.toList(growable: false),
  );

  ProgressionRemoteAckItem _ack(String eventId, ProgressionRemoteEvent event) =>
      ProgressionRemoteAckItem(
        eventId: eventId,
        sourceType: event.sourceType,
        sourceId: event.sourceId,
        xpAwarded: event.xpAwarded,
        rulesVersion: event.rulesVersion,
        revision: event.revision,
      );
}
