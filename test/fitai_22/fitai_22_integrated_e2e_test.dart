import 'dart:convert';
import 'dart:io';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/core/config/dev_data.dart';
import 'package:fitai/core/exercises/exercise_library_local_store.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/features/activities/data/activity_sync_gateway.dart';
import 'package:fitai/features/activities/data/activity_sync_service.dart';
import 'package:fitai/features/ai_chat/application/ai_action_controller.dart';
import 'package:fitai/features/ai_chat/application/ai_action_executor.dart';
import 'package:fitai/features/ai_chat/application/ai_chat_controller.dart';
import 'package:fitai/features/ai_chat/data/ai_chat_gateway.dart';
import 'package:fitai/features/ai_chat/data/ai_chat_repository.dart';
import 'package:fitai/features/ai_chat/data/ai_action_gateway.dart';
import 'package:fitai/features/ai_chat/domain/ai_chat_models.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/features/home/presentation/controllers/home_controller.dart';
import 'package:fitai/features/home/presentation/states/home_state.dart';
import 'package:fitai/features/home/presentation/widgets/home_dashboard_content.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/models/fitai_meta_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/exercicios/biblioteca/library_catalog_controller.dart';
import 'package:fitai/services/network_service.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:fitai/services/treino_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _base = String.fromEnvironment('FITAI_22_BASE_URL');
const _runId = String.fromEnvironment('FITAI_22_RUN_ID');
const _planId = String.fromEnvironment('FITAI_22_PLAN_ID');
const _addedExerciseId = String.fromEnvironment('FITAI_22_ADD_EXERCISE_ID');

Future<void> _freshLocalDevice() async {
  SharedPreferences.setMockInitialValues({});
  AccountSessionLifecycle.setActiveUser(null);
}

TreinoModel _plan() {
  final exercise = bancoExercicios
      .singleWhere((item) => item.id == 'ombros_003')
      .copyWith(series: 3, repeticoes: '8-10', descansoSegundos: 60);
  return TreinoModel(
    id: _planId,
    nome: 'FITAI-22 Upper',
    descricao: 'E2E local integration plan',
    objetivo: 'Hipertrofia',
    nivel: 'Intermediário',
    tempoEstimado: 45,
    diasPorSemana: 1,
    planoDias: [
      TreinoDiaModel(
        codigo: 'A',
        nome: 'Upper',
        ordem: 1,
        exercicioIds: [exercise.id],
      ),
    ],
    criadoPorIA: false,
    exercicios: [exercise],
    dataCriacao: DateTime.utc(2026, 10, 9).toIso8601String(),
  );
}

Future<Map<String, Object>> _localSnapshot() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)!};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  testWidgets(
    'FITAI-22: authenticated API, fresh device, Home, Library, running and confirmed AI action',
    (tester) async {
      // Real HTTP runs outside the widget clock; only rendering uses fake time.
      final proof = await tester.runAsync(() async {
        expect([
          _base,
          _runId,
          _planId,
          _addedExerciseId,
        ], everyElement(isNotEmpty));
        ApiConfig.configure(baseUrl: _base);
        await _freshLocalDevice();

        final authA = AuthService(
          bypassLogin: false,
          sessionStore: InMemoryAuthSessionStore(),
        );
        final user = await authA.register(
          name: 'FITAI-22 Owner',
          email: 'fitai22-owner-$_runId@fitia.test',
          password: 'fitai22-test-password',
        );
        final syncA = SyncService.forTesting(
          networkService: NetworkService(),
          authService: authA,
        );
        final emptyHome = _homeController();
        addTearDown(emptyHome.dispose);
        await emptyHome.load(workouts: const [], xp: 0, level: 1);
        expect(emptyHome.state.hasLocalContent, isFalse);
        expect(emptyHome.state.isUsingDeveloperData, isFalse);
        final emptyState = emptyHome.state;

        // Canonical plan and Library actions share the existing catalog identity.
        final plan = _plan();
        await StorageService.salvarTreino(plan);
        await syncA.syncWorkouts([plan.toJson()]);
        await syncA.flushPending();
        final libraryA = LibraryCatalogController(
          catalogLoader: () async => bancoExercicios,
          localStore: SharedPreferencesExerciseLibraryLocalStore(
            userScope: user.userId,
          ),
          userScopeResolver: () => user.userId,
        );
        addTearDown(libraryA.dispose);
        await libraryA.initialize();
        libraryA.updateQuery('elevacao lateral');
        expect(
          libraryA.visibleExercises.map((item) => item.id),
          contains('ombros_003'),
        );
        final libraryExercise = bancoExercicios.singleWhere(
          (item) => item.id == _addedExerciseId,
        );
        expect(await libraryA.toggleFavorite(libraryExercise), isTrue);
        await libraryA.registerViewed(libraryExercise);
        expect(libraryA.favoriteIds, contains(_addedExerciseId));
        expect(libraryA.recentIds, contains(_addedExerciseId));

        final strengthA = await _workout(authA, syncA, user.userId);
        final strengthSession = await strengthA.startOrRecover(
          planId: plan.id,
          workoutId: 'upper',
          planName: plan.nome,
          workoutName: plan.nome,
          workoutSnapshot: plan.toJson(),
        );
        final registeredSet = await strengthA.registerSet(
          sessionId: strengthSession.id,
          exerciseId: 'ombros_003',
          canonicalExerciseId: 'ombros_003',
          exerciseName: plan.exercicios.single.nome,
          setIndex: 0,
          weight: 12,
          reps: 10,
          restDuration: const Duration(seconds: 60),
        );
        await strengthA.finish(strengthSession.id);
        await strengthA.flushOutbox();
        expect((await strengthA.load()).outbox, isEmpty);

        // Real RunningSessionService lifecycle persists locally before ActivitySync.
        var now = DateTime.utc(2026, 10, 9, 12);
        final progression = ProgressionEngine(
          store: SharedPreferencesProgressionStore(),
          remoteGateway: HttpProgressionRemoteGateway(syncService: syncA),
          userIdResolver: () async => user.userId,
          autoSync: false,
          legacyReader: () async =>
              const LegacyProgression(level: 1, xpIntoLevel: 0),
          legacyMigrationPolicy: (_) async => false,
          legacyWriter: (_) async {},
        );
        final running = RunningSessionService.forTesting(
          clock: () => now,
          progressionEngine: progression,
        );
        await progression.recordWorkoutCompletion(
          workoutId: strengthSession.id,
          completedAt: DateTime.now().toUtc(),
        );
        addTearDown(running.dispose);
        await running.start();
        final runId = running.session!.id;
        running.recordLocationForTesting(
          latitude: 0,
          longitude: 0,
          recordedAt: now,
        );
        now = now.add(const Duration(minutes: 2));
        running.recordLocationForTesting(
          latitude: 0,
          longitude: 0.009,
          recordedAt: now,
        );
        await running.pause();
        now = now.add(const Duration(minutes: 1));
        await running.resume();
        now = now.add(const Duration(minutes: 2));
        final run = await running.finish();
        expect(run, isA<CorridaModel>());
        expect(run!.id, runId);
        expect(
          await StorageService.carregarCorridas(userId: user.userId),
          hasLength(1),
        );

        final steps = DailyStepsModel(
          userId: user.userId,
          date: '2026-10-09',
          steps: 8200,
          goal: 8000,
          source: DailyStepsModel.sourceManual,
          recordedAt: now,
          updatedAt: now,
        );
        await StorageService.salvarDailyStepsHistory([steps]);
        final activitiesA = ActivitySyncService.forTesting(
          gateway: HttpActivitySyncGateway(syncService: syncA),
          transport: syncA,
        );
        await activitiesA.syncUser(user.userId);
        expect(
          (await StorageService.carregarCorridas(
            userId: user.userId,
          )).single.syncStatus,
          RunningSyncStatus.synced,
        );
        await progression.syncRemote(userId: user.userId);
        final progressionSnapshot = await progression.load(userId: user.userId);
        expect(progressionSnapshot.balance.totalXp, greaterThan(0));

        // A new local installation authenticates independently and pulls canonical data.
        final aSnapshot = await _localSnapshot();
        await _freshLocalDevice();
        final authB = AuthService(
          bypassLogin: false,
          sessionStore: InMemoryAuthSessionStore(),
        );
        final userB = await authB.login(
          email: user.email,
          password: 'fitai22-test-password',
        );
        expect(userB.userId, user.userId);
        final syncB = SyncService.forTesting(
          networkService: NetworkService(),
          authService: authB,
        );
        await syncB.flushPending();
        await TreinoService.instance.initialize(force: true);
        expect(
          TreinoService.instance.treinos.map((item) => item.id),
          contains(_planId),
        );
        final strengthB = await _workout(authB, syncB, userB.userId);
        await strengthB.pullHistory();
        expect((await strengthB.load()).sets.single.id, registeredSet.set.id);
        expect((await strengthB.load()).outbox, isEmpty);
        final activitiesB = ActivitySyncService.forTesting(
          gateway: HttpActivitySyncGateway(syncService: syncB),
          transport: syncB,
        );
        await activitiesB.syncUser(userB.userId);
        expect(
          (await StorageService.carregarCorridas(
            userId: userB.userId,
          )).map((item) => item.id),
          [runId],
        );
        expect(
          (await StorageService.carregarDailyStepsHistory()).single.steps,
          8200,
        );
        expect(
          (await StorageService.carregarCorridas(userId: userB.userId)).length,
          1,
        );

        final progressionB = ProgressionEngine(
          store: SharedPreferencesProgressionStore(),
          remoteGateway: HttpProgressionRemoteGateway(syncService: syncB),
          userIdResolver: () async => userB.userId,
          autoSync: false,
          legacyReader: () async =>
              const LegacyProgression(level: 1, xpIntoLevel: 0),
          legacyMigrationPolicy: (_) async => false,
          legacyWriter: (_) async {},
        );
        await progressionB.syncRemote(userId: userB.userId);
        final balanceB = await progressionB.load(userId: userB.userId);
        final remotelyEligible = progressionSnapshot.events.where(
          (event) => event.isRemoteSyncEligible,
        );
        expect(
          remotelyEligible.map((event) => event.amount),
          unorderedEquals([
            ProgressionRules.workoutCompletionXp,
            ProgressionRules.runCompletionXp,
          ]),
        );
        expect(
          balanceB.balance.totalXp,
          remotelyEligible.fold<int>(0, (total, event) => total + event.amount),
        );
        expect(
          balanceB.events.map((event) => event.idempotencyKey),
          unorderedEquals(
            remotelyEligible.map((event) => event.idempotencyKey),
          ),
        );
        expect(
          progressionSnapshot.events.where(
            (event) => event.sourceType == XpSourceType.achievement,
          ),
          isNotEmpty,
          reason: 'Local achievements are outside remote contract v1.',
        );
        final homeSteps =
            (await StorageService.carregarDailyStepsHistory()).single.steps;
        final homeDistance = (await StorageService.carregarCorridas(
          userId: userB.userId,
        )).single.distancia;

        var homeOnline = true;
        final home = HomeController(
          coachLoader: () async => const [],
          goalsLoader: () async => const FitaiMetasResumo(metas: []),
          achievementsLoader: () async => const [],
          notificationsLoader: () async => const [],
          networkCheck: () async => homeOnline,
          workoutsLoader: StorageService.carregarTreinos,
          devDataLoader: () async => const DevRuntimeData.disabled(),
        );
        addTearDown(home.dispose);
        await home.load(
          workouts: const [],
          xp: balanceB.balance.totalXp,
          level: balanceB.balance.currentLevel,
        );
        expect(home.state.workouts.map((item) => item.id), contains(_planId));
        expect(home.state.isUsingDeveloperData, isFalse);
        expect(home.state.history.single.id, strengthSession.id);
        expect(home.state.history.single.volumeTotal, 120);
        expect(
          home.state.history.single.xpGanho,
          ProgressionRules.workoutCompletionXp,
        );
        expect(
          (await StorageService.carregarCorridas(userId: userB.userId)),
          hasLength(1),
        );
        expect(
          (await StorageService.carregarDailyStepsHistory()),
          hasLength(1),
        );
        final readyState = home.state;
        homeOnline = false;
        await home.refresh(
          workouts: home.state.workouts,
          xp: balanceB.balance.totalXp,
          level: balanceB.balance.currentLevel,
        );
        expect(home.state.isOffline, isTrue);
        expect(home.state.workouts.map((item) => item.id), contains(_planId));

        final libraryB = LibraryCatalogController(
          catalogLoader: () async => bancoExercicios,
          localStore: SharedPreferencesExerciseLibraryLocalStore(
            userScope: userB.userId,
          ),
          userScopeResolver: () => userB.userId,
        );
        addTearDown(libraryB.dispose);
        await libraryB.initialize();
        expect(
          libraryB.favoriteIds,
          isEmpty,
          reason: 'Device-local A favorites cannot leak across fresh storage.',
        );

        // Real authenticated Flutter chat -> backend fixture gateway -> PostgreSQL proposal.
        final chatGateway = HttpAiChatGateway(auth: authB);
        final chat = AiChatController(
          repository: AiChatRepository(gateway: chatGateway),
          session: authB.restoreSession,
        );
        addTearDown(chat.dispose);
        await chat.initialize();
        await chat.send('Adicione um exercicio canonico a minha ficha.');
        expect(chat.error, isNull);
        final assistantMessage = chat.messages.lastWhere(
          (message) => message.role == 'assistant',
        );
        final original = assistantMessage.actions.single;
        expect(original.status, 'VALIDATED');
        expect(
          (await StorageService.carregarTreinos()).single.exercicios,
          hasLength(1),
        );

        final actions = AiActionController(
          gateway: HttpAiActionGateway(auth: authB),
          executor: CanonicalAiActionExecutor(),
          onChanged: chat.updateAction,
        );
        addTearDown(actions.dispose);
        await actions.confirm(original);
        expect(actions.saved(original.id), isTrue);
        expect(
          (await StorageService.carregarTreinos()).single.exercicios.where(
            (e) => e.id == _addedExerciseId,
          ),
          hasLength(1),
        );
        await syncB.syncWorkouts(
          (await StorageService.carregarTreinos())
              .map((item) => item.toJson())
              .toList(),
        );
        await syncB.flushPending();
        final actionGateway = HttpAiActionGateway(auth: authB);
        addTearDown(actionGateway.dispose);
        final complete = await actionGateway.complete(
          userB.userId,
          original.id,
        );
        expect(complete.status, 'EXECUTED');
        expect(
          (await actionGateway.confirm(
            userB.userId,
            original.id,
            'fitai22-repeat-confirmation',
          )).status,
          'EXECUTED',
        );
        await actions.confirm(complete);
        expect(
          (await StorageService.carregarTreinos()).single.exercicios.where(
            (e) => e.id == _addedExerciseId,
          ),
          hasLength(1),
          reason:
              'Repeated confirmation must not duplicate a canonical exercise.',
        );

        // Reopen an independent installation and materialize B's confirmed mutation.
        await _freshLocalDevice();
        final reopenedAuth = AuthService(
          bypassLogin: false,
          sessionStore: InMemoryAuthSessionStore(),
        );
        await reopenedAuth.login(
          email: user.email,
          password: 'fitai22-test-password',
        );
        final reopenedSync = SyncService.forTesting(
          networkService: NetworkService(),
          authService: reopenedAuth,
        );
        await reopenedSync.flushPending();
        final reopenedPlan = (await StorageService.carregarTreinos()).single;
        expect(reopenedPlan.id, _planId);
        expect(
          reopenedPlan.exercicios.map((item) => item.id),
          unorderedEquals(['ombros_003', _addedExerciseId]),
        );
        await reopenedSync.flushPending();
        expect(
          (await StorageService.carregarTreinos()).single.exercicios,
          hasLength(2),
        );

        // Foreign ownership must not expose A's plan, activities, or AI conversation.
        final foreign = AuthService(
          bypassLogin: false,
          sessionStore: InMemoryAuthSessionStore(),
        );
        final other = await foreign.register(
          name: 'FITAI-22 Other',
          email: 'fitai22-other-$_runId@fitia.test',
          password: 'fitai22-test-password',
        );
        final foreignSync = SyncService.forTesting(
          networkService: NetworkService(),
          authService: foreign,
        );
        final foreignActions = HttpAiActionGateway(auth: foreign);
        addTearDown(foreignActions.dispose);
        await expectLater(
          foreignActions.confirm(other.userId, original.id, 'foreign-device'),
          throwsA(
            isA<AiChatFailure>().having(
              (error) => error.code,
              'code',
              'stale_action',
            ),
          ),
        );
        expect(
          await foreignSync.getAuthenticatedJsonForUser(
            userId: other.userId,
            path: '/sync/workouts',
          ),
          isNotNull,
        );
        expect(
          await StorageService.carregarTreinos(),
          isEmpty,
          reason: 'Switching to a foreign owner must not expose B local plans.',
        );
        await _freshLocalDevice();
        final foreignLogin = AuthService(
          bypassLogin: false,
          sessionStore: InMemoryAuthSessionStore(),
        );
        await foreignLogin.login(
          email: other.email,
          password: 'fitai22-test-password',
        );
        final foreignPull = SyncService.forTesting(
          networkService: NetworkService(),
          authService: foreignLogin,
        );
        await foreignPull.flushPending();
        expect(await StorageService.carregarTreinos(), isEmpty);
        expect(
          await StorageService.carregarCorridas(userId: other.userId),
          isEmpty,
        );
        final foreignHome = _homeController();
        addTearDown(foreignHome.dispose);
        await foreignHome.load(workouts: const [], xp: 0, level: 1);
        expect(foreignHome.state.hasLocalContent, isFalse);

        // Keep A's snapshot only as evidence that the fresh-device transition was independent.
        expect(jsonEncode(aSnapshot), contains(_planId));
        debugPrint(
          'FITAI_22_E2E owner=${user.userId} plan=$_planId run=$runId aiAction=${original.id} result=PASS',
        );
        return (
          empty: emptyState,
          ready: readyState,
          offline: home.state,
          foreign: foreignHome.state,
          xp: balanceB.balance.totalXp,
          level: balanceB.balance.currentLevel,
          steps: homeSteps,
          distance: homeDistance,
        );
      });
      expect(proof, isNotNull);
      await tester.pumpWidget(_homeWidget(proof!.empty));
      expect(find.text('Criar plano'), findsOneWidget);
      expect(find.text('FITAI-22 Upper'), findsNothing);
      await tester.pumpWidget(
        _homeWidget(
          proof.ready,
          xp: proof.xp,
          level: proof.level,
          steps: proof.steps,
          distance: proof.distance,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('FITAI-22 Upper'), findsWidgets);
      expect(find.text('8.2k'), findsOneWidget);
      expect(
        find.text('${proof.distance.toStringAsFixed(1)} km'),
        findsOneWidget,
      );
      expect(
        find.text('Nivel ${proof.level}  /  ${proof.xp} XP'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        _homeWidget(
          proof.offline,
          xp: proof.xp,
          level: proof.level,
          steps: proof.steps,
          distance: proof.distance,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Voce esta offline'), findsOneWidget);
      expect(find.text('FITAI-22 Upper'), findsWidgets);
      await tester.pumpWidget(_homeWidget(proof.foreign));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Criar plano'), findsOneWidget);
      expect(find.text('FITAI-22 Upper'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    skip:
        _base.isEmpty ||
        _runId.isEmpty ||
        _planId.isEmpty ||
        _addedExerciseId.isEmpty,
  );
}

Future<WorkoutVerticalRepository> _workout(
  AuthService auth,
  SyncService sync,
  String owner,
) async {
  final transport = HttpWorkoutSyncTransport(authService: auth);
  addTearDown(transport.dispose);
  return WorkoutVerticalRepository(
    localStore: SharedPreferencesWorkoutVerticalLocalStore(
      await SharedPreferences.getInstance(),
      userScope: owner,
    ),
    transport: transport,
    historyReader: (revision, setId) => sync.getAuthenticatedJsonForUser(
      userId: owner,
      path:
          '/workout-sync/history?afterRevision=$revision&afterSetId=${Uri.encodeQueryComponent(setId)}',
    ),
  );
}

HomeController _homeController() => HomeController(
  workoutsLoader: StorageService.carregarTreinos,
  coachLoader: () async => const [],
  goalsLoader: () async => const FitaiMetasResumo(metas: []),
  achievementsLoader: () async => const [],
  notificationsLoader: () async => const [],
  networkCheck: () async => true,
  devDataLoader: () async => const DevRuntimeData.disabled(),
);

Widget _homeWidget(
  HomeState state, {
  int xp = 0,
  int level = 1,
  int steps = 0,
  double distance = 0,
}) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: HomeDashboardContent(
      state: state,
      name: 'FITAI-22 Owner',
      xp: xp,
      level: level,
      steps: steps,
      distance: distance,
      runningActive: false,
      runningSeconds: 0,
      now: () => DateTime(2026, 10, 9, 12),
      onRefresh: () async {},
      onOpenWorkout: () {},
      onCreatePlan: () {},
      onOpenLibrary: () {},
      onOpenRunning: () {},
      onOpenSteps: () {},
      onOpenCoach: () {},
      onOpenGoals: () {},
      onOpenAchievements: () {},
      onOpenNotifications: () {},
      onCustomize: () {},
      onOpenOverview: () {},
      onOpenTodayWorkout: () {},
      onOpenRecentActivity: () {},
      onOpenProgress: () {},
    ),
  ),
);
