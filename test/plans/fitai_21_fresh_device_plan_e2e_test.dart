import 'dart:convert';
import 'dart:io';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/features/activities/data/activity_sync_gateway.dart';
import 'package:fitai/features/activities/data/activity_sync_service.dart';
import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/network_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:fitai/services/treino_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _base = String.fromEnvironment('FITAI_21_BASE_URL');
const _runId = String.fromEnvironment('FITAI_21_RUN_ID');

class _ToggleClient extends http.BaseClient {
  final _delegate = http.Client();
  bool offline = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (offline) throw http.ClientException('Controlled offline boundary');
    return _delegate.send(request);
  }

  @override
  void close() => _delegate.close();
}

Future<Map<String, Object>> _snapshot() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)!};
}

Future<void> _restore(Map<String, Object> snapshot, AuthService auth) async {
  SharedPreferences.setMockInitialValues(snapshot);
  AccountSessionLifecycle.setActiveUser(null);
  await auth.restoreSession();
}

Future<TreinoModel> _local(String id) async =>
    (await StorageService.carregarTreinos()).singleWhere((p) => p.id == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This opt-in E2E uses the real API, not the widget binding's HTTP stub.
  HttpOverrides.global = null;
  test(
    'S21-P1-01 A-J: real API/PG, independent A/B, replay/restart/delete/offline',
    () async {
      SharedPreferences.setMockInitialValues({});
      ApiConfig.configure(baseUrl: _base);
      final authA = AuthService(
        bypassLogin: false,
        sessionStore: InMemoryAuthSessionStore(),
      );
      final a = await authA.register(
        name: 'FITAI21 A',
        email: 'fitai21-plan-$_runId@fitia.test',
        password: 'fitai21-test-password',
      );
      final exercise = bancoExercicios
          .firstWhere((e) => e.id == 'ombros_003')
          .copyWith(series: 4, repeticoes: '8-10', descansoSegundos: 75);
      final plan = TreinoModel.fromJson({
        'id': 'fitai21-plan-$_runId',
        'nome': 'Fresh device plan',
        'exercicios': [exercise.toJson()],
      });
      final syncA = SyncService.forTesting(
        networkService: NetworkService(),
        authService: authA,
      );
      await StorageService.salvarTreino(plan, syncService: syncA);
      await syncA.syncWorkouts([plan.toJson()]);
      await syncA.flushPending();
      var deviceA = await _snapshot();
      final remoteA = await syncA.getAuthenticatedJsonForUser(
        userId: a.userId,
        path: '/sync/workouts',
      );
      expect(
        (remoteA!['workouts'] as List).map((p) => p['id']),
        contains(plan.id),
        reason: 'Precondition: the authenticated API persisted A plan.',
      );

      // A fresh installation has its own empty preferences and auth store.
      // No plan, journal, cursor or token is copied from A.
      SharedPreferences.setMockInitialValues({});
      AccountSessionLifecycle.setActiveUser(null);
      final authB = AuthService(
        bypassLogin: false,
        sessionStore: InMemoryAuthSessionStore(),
      );
      final b = await authB.login(
        email: a.email,
        password: 'fitai21-test-password',
      );
      expect(b.userId, a.userId);
      final clientB = _ToggleClient();
      addTearDown(clientB.close);
      final syncB = SyncService.forTesting(
        networkService: NetworkService(client: clientB),
        authService: authB,
      );
      final remoteB = await syncB.getAuthenticatedJsonForUser(
        userId: b.userId,
        path: '/sync/workouts',
      );
      expect(
        (remoteB!['workouts'] as List).map((p) => p['id']),
        contains(plan.id),
        reason: 'B can read the plan remotely under the same JWT owner.',
      );
      await syncB.flushPending();
      await TreinoService.instance.initialize(force: true);
      final localB = await StorageService.carregarTreinos();
      expect(
        localB.map((p) => p.id),
        contains(plan.id),
        reason:
            'P1: official sync and plan loader must materialize active plans '
            'on an independent fresh device, not only deletion deltas.',
      );
      expect(
        TreinoService.instance.treinos.map((p) => p.id),
        contains(plan.id),
      );
      expect((await _local(plan.id)).exercicios.single.series, 4);
      expect((await _local(plan.id)).exercicios.single.repeticoes, '8-10');
      expect((await _local(plan.id)).exercicios.single.descansoSegundos, 75);
      expect(
        (await _local(plan.id)).exercicios.single.canonicalExerciseId,
        'ombros_003',
      );
      final prefsB = await SharedPreferences.getInstance();
      expect(prefsB.getStringList('fitaiSyncQueue') ?? [], isEmpty);
      expect(prefsB.getInt('xp'), isNull);
      expect(await StorageService.planPullCursor(b.userId), isEmpty);
      await syncB.flushPending();
      expect(await StorageService.carregarTreinos(), hasLength(1));
      var deviceB = await _snapshot();
      await _restore(deviceB, authB);
      await TreinoService.instance.initialize(force: true);
      expect(TreinoService.instance.treinos.single.id, plan.id);

      // Reverse direction: B edits and A receives it using A's own storage.
      final edited = TreinoModel.fromJson({
        ...plan.toJson(),
        'nome': 'Edited on B',
      });
      await StorageService.salvarTreino(edited, syncService: syncB);
      await syncB.syncWorkouts([edited.toJson()]);
      await syncB.flushPending();
      deviceB = await _snapshot();
      await _restore(deviceA, authA);
      await syncA.flushPending();
      expect((await _local(plan.id)).nome, 'Edited on B');
      deviceA = await _snapshot();

      // Independent foreign owner cannot pull A's active definition.
      SharedPreferences.setMockInitialValues({});
      AccountSessionLifecycle.setActiveUser(null);
      final foreign = AuthService(
        bypassLogin: false,
        sessionStore: InMemoryAuthSessionStore(),
      );
      final other = await foreign.register(
        name: 'Other owner',
        email: 'fitai21-other-$_runId@fitia.test',
        password: 'fitai21-test-password',
      );
      final foreignSync = SyncService.forTesting(
        networkService: NetworkService(),
        authService: foreign,
      );
      await foreignSync.flushPending();
      expect(await StorageService.carregarTreinos(), isEmpty);
      expect(other.userId, isNot(a.userId));

      // Preserve another local-only plan while merging a remote edit.
      await _restore(deviceB, authB);
      final localOnly = TreinoModel.fromJson({
        ...plan.toJson(),
        'id': 'local-only-$_runId',
        'nome': 'Local only',
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('treinos', [
        ...prefs.getStringList('treinos')!,
        jsonEncode(localOnly.toJson()),
      ]);
      clientB.offline = true;
      final offlineEdit = TreinoModel.fromJson({
        ...edited.toJson(),
        'nome': 'Offline B edit',
      });
      await StorageService.salvarTreino(offlineEdit, syncService: syncB);
      await syncB.syncWorkouts([offlineEdit.toJson()]);
      await syncB.flushPending();
      expect((await _local(plan.id)).nome, 'Offline B edit');
      expect(
        (await SharedPreferences.getInstance()).getStringList('fitaiSyncQueue'),
        isNotEmpty,
      );
      deviceB = await _snapshot();
      await _restore(deviceB, authB);
      expect((await _local(plan.id)).nome, 'Offline B edit');
      clientB.offline = false;
      await syncB.flushPending();
      expect(
        (await SharedPreferences.getInstance()).getStringList(
              'fitaiSyncQueue',
            ) ??
            [],
        isEmpty,
      );
      expect((await _local(localOnly.id)).nome, 'Local only');
      deviceB = await _snapshot();
      await _restore(deviceA, authA);
      await syncA.flushPending();
      expect((await _local(plan.id)).nome, 'Offline B edit');

      // A deletes; B consumes the tombstone before active materialization.
      expect(
        await StorageService.removerTreino(plan.id, syncService: syncA),
        isTrue,
      );
      await syncA.deleteWorkout(plan.id);
      await syncA.flushPending();
      await _restore(deviceB, authB);
      await syncB.flushPending();
      expect(
        (await StorageService.carregarTreinos()).map((p) => p.id),
        isNot(contains(plan.id)),
      );
      await syncB.postAuthenticatedJsonForUser(
        userId: b.userId,
        path: '/sync/workouts',
        payload: {
          'items': [plan.toJson()],
        },
      );
      final afterStale = await syncB.getAuthenticatedJsonForUser(
        userId: b.userId,
        path: '/sync/workouts',
      );
      expect(
        (afterStale!['workouts'] as List).map((p) => p['id']),
        isNot(contains(plan.id)),
        reason: 'Deleted definition cannot be resurrected.',
      );
      await syncB.flushPending();
      expect(
        (await StorageService.carregarTreinos()).map((p) => p.id),
        isNot(contains(plan.id)),
      );
      expect((await _local(localOnly.id)).nome, 'Local only');

      // Public paging contract: more than one page, reset cursor after full scan.
      final many = [
        for (var i = 0; i < 51; i++)
          {
            ...plan.toJson(),
            'id': 'paged-$_runId-${i.toString().padLeft(3, '0')}',
          },
      ];
      await syncB.syncWorkouts(many);
      await syncB.flushPending();
      expect(
        (await StorageService.carregarTreinos()).where(
          (p) => p.id.startsWith('paged-$_runId'),
        ),
        hasLength(51),
      );
      expect(await StorageService.planPullCursor(b.userId), isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
              'fitaiSyncQueue',
            ) ??
            [],
        isEmpty,
      );
      expect((await SharedPreferences.getInstance()).getInt('xp'), isNull);
      debugPrint(
        'API_RESPONSE: authenticated plan present; REMOTE_CURSOR: bounded full scan complete; LOCAL_SYNC_STATE: empty outbox; MATERIALIZATION_PATH: sync -> canonical treinos; STORAGE_READ_RESULT: A-J PASS + reverse edit + 51 plans',
      );
    },
    skip: _base.isEmpty || _runId.isEmpty
        ? 'Run scripts/run-fitai-21-plan-e2e.js against the test PostgreSQL.'
        : false,
  );
  test(
    'S21 integrated: strength/activity/XP HTTP-PG, independent A/B, offline restart',
    _domainJourney,
    skip: _base.isEmpty || _runId.isEmpty
        ? 'Run scripts/run-fitai-21-plan-e2e.js against the test PostgreSQL.'
        : false,
  );
}

ProgressionEngine _progression(String owner, SyncService sync) =>
    ProgressionEngine(
      store: SharedPreferencesProgressionStore(),
      remoteGateway: HttpProgressionRemoteGateway(syncService: sync),
      userIdResolver: () async => owner,
      autoSync: false,
      legacyReader: () async =>
          const LegacyProgression(level: 1, xpIntoLevel: 0),
      legacyMigrationPolicy: (_) async => false,
      legacyWriter: (_) async {},
    );

Future<WorkoutVerticalRepository> _workout(
  AuthService auth,
  SyncService sync,
  String owner,
  _ToggleClient client,
) async => WorkoutVerticalRepository(
  localStore: SharedPreferencesWorkoutVerticalLocalStore(
    await SharedPreferences.getInstance(),
    userScope: owner,
  ),
  transport: HttpWorkoutSyncTransport(authService: auth, client: client),
  historyReader: (revision, setId) => sync.getAuthenticatedJsonForUser(
    userId: owner,
    path:
        '/workout-sync/history?afterRevision=$revision&afterSetId=${Uri.encodeQueryComponent(setId)}',
  ),
);

ActivitySyncService _activity(SyncService sync) =>
    ActivitySyncService.forTesting(
      gateway: HttpActivitySyncGateway(syncService: sync),
      transport: sync,
    );

Future<void> _domainJourney() async {
  SharedPreferences.setMockInitialValues({});
  AccountSessionLifecycle.setActiveUser(null);
  ApiConfig.configure(baseUrl: _base);
  final authA = AuthService(
    bypassLogin: false,
    sessionStore: InMemoryAuthSessionStore(),
  );
  final user = await authA.register(
    name: 'Integrated A',
    email: 'fitai21-integrated-$_runId@fitia.test',
    password: 'fitai21-test-password',
  );
  final clientA = _ToggleClient();
  final clientB = _ToggleClient();
  addTearDown(clientA.close);
  addTearDown(clientB.close);
  final syncA = SyncService.forTesting(
    networkService: NetworkService(client: clientA),
    authService: authA,
  );
  final repositoryA = await _workout(authA, syncA, user.userId, clientA);
  final sessionA = await repositoryA.startOrRecover(
    planId: 'integrated-plan-$_runId',
    workoutId: 'upper',
  );
  clientA.offline = true;
  final registered = await repositoryA.registerSet(
    sessionId: sessionA.id,
    exerciseId: 'ombros_003',
    canonicalExerciseId: 'ombros_003',
    exerciseName: 'Elevacao lateral',
    setIndex: 0,
    weight: 12,
    reps: 10,
    restDuration: const Duration(seconds: 75),
  );
  await repositoryA.flushOutbox();
  expect((await repositoryA.load()).outbox, isNotEmpty);
  final rest = (await repositoryA.load()).sessions.single.restEndsAt;
  final aBeforeRestart = await _snapshot();
  await _restore(aBeforeRestart, authA);
  final restartedA = await _workout(authA, syncA, user.userId, clientA);
  expect((await restartedA.load()).sets.single.id, registered.set.id);
  expect((await restartedA.load()).sessions.single.restEndsAt, rest);
  final recovered = await restartedA.startOrRecover(
    planId: sessionA.planId,
    workoutId: 'upper',
  );
  expect(recovered.id, sessionA.id);
  await restartedA.finish(sessionA.id);
  expect((await restartedA.load()).outbox, isNotEmpty);
  clientA.offline = false;
  await restartedA.retryNow();
  await restartedA.flushOutbox();
  expect((await restartedA.load()).outbox, isEmpty);
  final historyA = await WorkoutHistoryRepository(
    localStore: restartedA.localStore,
  ).load();
  expect(historyA.workouts, hasLength(1));
  expect(historyA.workouts.single.metrics.totalVolume, 120);

  final now = DateTime.now().toUtc();
  final day = now.toIso8601String().substring(0, 10);
  final run = CorridaModel(
    id: 'integrated-run-$_runId',
    userId: user.userId,
    distancia: 1,
    segundos: 300,
    data: now.toIso8601String(),
    startTime: now.subtract(const Duration(minutes: 5)).toIso8601String(),
    endTime: now.toIso8601String(),
    averageSpeed: 12,
    pace: 5,
    syncStatus: RunningSyncStatus.queued,
    route: [
      RunningRoutePointModel(
        latitude: 0,
        longitude: 0,
        accuracy: 5,
        altitude: 0,
        speed: 3.3,
        timestamp: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      ),
      RunningRoutePointModel(
        latitude: 0,
        longitude: 0.009,
        accuracy: 5,
        altitude: 0,
        speed: 3.3,
        timestamp: now.toIso8601String(),
      ),
    ],
  );
  final steps = DailyStepsModel(
    userId: user.userId,
    date: day,
    steps: 10000,
    goal: 10000,
    source: DailyStepsModel.sourceHealthConnect,
    recordedAt: now,
    updatedAt: now,
  );
  await StorageService.salvarCorrida(run);
  await StorageService.salvarDailyStepsHistory([steps]);
  final activityA = _activity(syncA);
  clientA.offline = true;
  await expectLater(
    activityA.syncUser(user.userId),
    throwsA(isA<http.ClientException>()),
  );
  final activityRestart = await _snapshot();
  await _restore(activityRestart, authA);
  expect(
    (await StorageService.carregarCorridas(userId: user.userId)).single.id,
    run.id,
  );
  expect(
    (await StorageService.carregarDailyStepsHistory()).single.steps,
    10000,
  );
  clientA.offline = false;
  await activityA.syncUser(user.userId);
  expect(
    (await StorageService.carregarCorridas(
      userId: user.userId,
    )).single.syncStatus,
    RunningSyncStatus.synced,
  );
  expect(
    (await StorageService.carregarDailyStepsHistory()).single.syncStatus,
    DailyStepsSyncStatus.synced,
  );
  final xpA = _progression(user.userId, syncA);
  await xpA.recordWorkoutCompletion(workoutId: sessionA.id, completedAt: now);
  await xpA.recordRunCompletion(
    runId: run.id,
    completedAt: now,
    durationSeconds: run.segundos,
    distanceKm: run.distancia,
  );
  await xpA.recordDailyStepsGoal(
    steps: ProgressionStepsSource(
      userId: user.userId,
      date: DateTime.parse(day),
      steps: 10000,
      goal: 10000,
      isSeed: false,
    ),
  );
  await xpA.syncRemote();
  var deviceA = await _snapshot();

  // Truly fresh B: no preference, session, cursor or journal copied from A.
  SharedPreferences.setMockInitialValues({});
  AccountSessionLifecycle.setActiveUser(null);
  final authB = AuthService(
    bypassLogin: false,
    sessionStore: InMemoryAuthSessionStore(),
  );
  await authB.login(email: user.email, password: 'fitai21-test-password');
  final syncB = SyncService.forTesting(
    networkService: NetworkService(client: clientB),
    authService: authB,
  );
  final repositoryB = await _workout(authB, syncB, user.userId, clientB);
  await repositoryB.pullHistory();
  expect((await repositoryB.load()).sets.single.id, registered.set.id);
  expect((await repositoryB.load()).outbox, isEmpty);
  expect(
    (await WorkoutHistoryRepository(
      localStore: repositoryB.localStore,
    ).load()).workouts.single.metrics.totalVolume,
    120,
  );
  final activityB = _activity(syncB);
  await activityB.syncUser(user.userId);
  expect(
    (await StorageService.carregarCorridas(userId: user.userId)).single.route,
    hasLength(2),
  );
  expect(
    (await StorageService.carregarDailyStepsHistory()).single.steps,
    10000,
  );
  final xpB = _progression(user.userId, syncB);
  await xpB.syncRemote();
  var imported = await xpB.load();
  final eligible = imported.events.where(
    (e) => ProgressionRemoteContract.supports(e.sourceType),
  );
  expect(eligible.map((e) => e.amount), unorderedEquals([15, 10, 8]));
  expect(
    eligible.every((e) => e.syncStatus == ProgressionSyncStatus.synced),
    isTrue,
  );
  await repositoryB.pullHistory();
  await activityB.syncUser(user.userId);
  await xpB.syncRemote();
  expect((await repositoryB.load()).sets, hasLength(1));
  expect(
    (await xpB.load()).events.where(
      (e) => ProgressionRemoteContract.supports(e.sourceType),
    ),
    hasLength(3),
  );

  // B contributes all three domains; A must pull its canonical state.
  final sessionB = await repositoryB.startOrRecover(
    planId: sessionA.planId,
    workoutId: 'lower',
  );
  await repositoryB.registerSet(
    sessionId: sessionB.id,
    exerciseId: 'ombros_003',
    setIndex: 0,
    weight: 14,
    reps: 10,
  );
  await repositoryB.finish(sessionB.id);
  await repositoryB.flushOutbox();
  final secondRun = CorridaModel.fromJson({
    ...run.toJson(),
    'id': 'integrated-run-b-$_runId',
  });
  await StorageService.salvarCorrida(secondRun);
  await StorageService.salvarDailyStepsHistory([
    steps.copyWith(
      steps: 9900,
      version: 2,
      updatedAt: now.add(const Duration(seconds: 1)),
    ),
  ]);
  await activityB.syncUser(user.userId);
  await xpB.recordWorkoutCompletion(workoutId: sessionB.id, completedAt: now);
  await xpB.recordRunCompletion(
    runId: secondRun.id,
    completedAt: now,
    durationSeconds: 300,
    distanceKm: 1,
  );
  await xpB.syncRemote();
  final deviceB = await _snapshot();
  await _restore(deviceA, authA);
  final finalA = await _workout(authA, syncA, user.userId, clientA);
  await finalA.pullHistory();
  await activityA.syncUser(user.userId);
  await xpA.syncRemote();
  expect(
    (await finalA.load()).sessions.where((s) => s.id == sessionB.id),
    hasLength(1),
  );
  expect(
    (await StorageService.carregarCorridas(userId: user.userId)),
    hasLength(2),
  );
  expect(
    (await StorageService.carregarDailyStepsHistory()).single.steps,
    9900,
    reason: 'Latest correction, not MAX or addition.',
  );
  final remoteA = (await xpA.load()).events.where(
    (e) => ProgressionRemoteContract.supports(e.sourceType),
  );
  expect(
    remoteA.map((e) => e.amount).fold<int>(0, (total, xp) => total + xp),
    58,
  );
  expect(
    remoteA.where((e) => e.sourceType == XpSourceType.stepsGoal),
    hasLength(1),
  );
  deviceA = await _snapshot();
  await _restore(deviceB, authB);
  await xpB.syncRemote();
  imported = await xpB.load();
  expect(
    imported.events
        .where((e) => ProgressionRemoteContract.supports(e.sourceType))
        .map((e) => e.amount)
        .fold<int>(0, (total, xp) => total + xp),
    58,
  );
  expect(deviceA, isNotEmpty);
  debugPrint(
    'S21_INTEGRATED: strength journal/recovery/history + running route + absolute steps correction + XP 15/10/8, A->B and B->A PASS; native sensors NOT_RUN',
  );
}
