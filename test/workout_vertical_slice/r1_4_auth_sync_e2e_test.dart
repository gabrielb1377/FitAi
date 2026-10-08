import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = String.fromEnvironment('VS2_LIVE_BASE_URL');
const _runId = String.fromEnvironment('R1_4_RUN_ID');

void main() {
  test(
    'R1.4: Flutter outbox atravessa JWT, HTTP, Prisma e PostgreSQL',
    () async {
      expect(_runId, isNotEmpty);
      SharedPreferences.setMockInitialValues({});
      ApiConfig.configure(baseUrl: _baseUrl);

      final userA = await _register('a');
      final userB = await _register('b');
      final storeA = _MemoryStore();
      final primaryTransport = HttpWorkoutSyncTransport(
        authService: userA.authService,
      );
      final repositoryA = WorkoutVerticalRepository(
        localStore: storeA,
        transport: primaryTransport,
      );

      // E2E-01: evento criado pelo repositorio e removido apenas apos ACK real.
      final session = await repositoryA.startOrRecover(
        planId: 'r1-4-plan-$_runId',
        workoutId: 'r1-4-workout-$_runId',
      );
      await repositoryA.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: 0,
        weight: 55,
        reps: 10,
      );
      final setEvent = (await storeA.read()).outbox.firstWhere(
        (event) => event.eventType == 'workout_set_completed',
      );
      await repositoryA.flushOutbox();
      expect((await storeA.read()).outbox, isEmpty);

      // E2E-02: o mesmo evento recebe alreadyProcessed e nao duplica a operacao.
      final acknowledged = await storeA.read();
      await storeA.write(acknowledged.copyWith(outbox: [setEvent]));
      await repositoryA.flushOutbox();
      expect((await storeA.read()).outbox, isEmpty);

      // E2E-03: uma falha de transporte antes da API preserva a outbox; o retry
      // seguinte usa o mesmo adaptador HTTP real e recebe ACK do backend.
      final retryTransport = HttpWorkoutSyncTransport(
        client: _FailOnceClient(),
        authService: userA.authService,
      );
      final retryRepository = WorkoutVerticalRepository(
        localStore: storeA,
        transport: retryTransport,
      );
      await retryRepository.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: 1,
        weight: 57.5,
        reps: 8,
      );
      await retryRepository.flushOutbox();
      var afterFailure = await storeA.read();
      expect(afterFailure.outbox, hasLength(1));
      expect(afterFailure.outbox.single.status, OutboxEventStatus.pending);
      expect(afterFailure.outbox.single.attempts, 1);
      await retryRepository.retryNow();
      await retryRepository.flushOutbox();
      expect((await storeA.read()).outbox, isEmpty);
      retryTransport.dispose();

      // E2E-04: sem bearer a API real responde 401. Com um JWT de assinatura
      // invalida, a outbox permanece pendente e volta a sincronizar apos login.
      final noBearer = await http.post(
        ApiConfig.endpoint('/workout-sync/events'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': 'r1-4-no-bearer', 'events': const []}),
      );
      expect(noBearer.statusCode, 401);
      final invalidStore = InMemoryAuthSessionStore();
      await invalidStore.write(
        jsonEncode(
          AuthSession(
            userId: userA.session.userId,
            name: userA.session.name,
            email: userA.session.email,
            token: _invalidateSignature(userA.session.token),
          ).toJson(),
        ),
      );
      final invalidAuth = AuthService(sessionStore: invalidStore);
      final unauthorizedStore = _MemoryStore();
      final unauthorizedRepository = WorkoutVerticalRepository(
        localStore: unauthorizedStore,
        transport: HttpWorkoutSyncTransport(authService: invalidAuth),
      );
      await unauthorizedRepository.startOrRecover(
        planId: 'r1-4-reauth-plan-$_runId',
        workoutId: 'r1-4-reauth-workout-$_runId',
      );
      await unauthorizedRepository.flushOutbox();
      var unauthorizedSnapshot = await unauthorizedStore.read();
      expect(unauthorizedSnapshot.outbox, hasLength(1));
      expect(
        unauthorizedSnapshot.outbox.single.status,
        OutboxEventStatus.pending,
      );
      expect(unauthorizedSnapshot.outbox.single.attempts, 1);
      final reauthenticatedRepository = WorkoutVerticalRepository(
        localStore: unauthorizedStore,
        transport: HttpWorkoutSyncTransport(authService: userA.authService),
      );
      await reauthenticatedRepository.retryNow();
      await reauthenticatedRepository.flushOutbox();
      expect((await unauthorizedStore.read()).outbox, isEmpty);

      // E2E-05: USER_B nao consegue completar uma serie na sessao privada de A.
      final foreignStore = _MemoryStore();
      final foreignSet = _foreignSetEvent(session, userA.session.userId);
      await foreignStore.write(
        WorkoutSliceSnapshot.empty().copyWith(outbox: [foreignSet]),
      );
      final userBRepository = WorkoutVerticalRepository(
        localStore: foreignStore,
        transport: HttpWorkoutSyncTransport(authService: userB.authService),
      );
      await userBRepository.flushOutbox();
      final foreignSnapshot = await foreignStore.read();
      expect(foreignSnapshot.outbox, hasLength(1));
      expect(foreignSnapshot.outbox.single.status, OutboxEventStatus.conflict);

      // Um userId injetado no body e rejeitado pela schema estrita: ele nao
      // participa da definicao de ownership e nao chega ao service.
      final bodyTamper = await http.post(
        ApiConfig.endpoint('/workout-sync/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userA.session.token}',
        },
        body: jsonEncode({
          'deviceId': 'r1-4-body-tamper',
          'userId': userB.session.userId,
          'events': const [],
        }),
      );
      expect(bodyTamper.statusCode, 400);

      // E2E-06: um clientId adulterado continua associado ao owner do JWT.
      SharedPreferences.setMockInitialValues({
        'fitai.workoutVerticalSlice.deviceId.v1': 'tampered-client-$_runId',
      });
      final tamperedPreferences = await SharedPreferences.getInstance();
      final tamperedRepository = WorkoutVerticalRepository(
        localStore: storeA,
        transport: HttpWorkoutSyncTransport(
          authService: userA.authService,
          preferencesLoader: () async => tamperedPreferences,
        ),
      );
      await tamperedRepository.updateProgress(
        sessionId: session.id,
        currentExerciseIndex: 1,
        currentSetIndex: 0,
      );
      await tamperedRepository.flushOutbox();
      expect((await storeA.read()).outbox, isEmpty);

      // FITAI-20: device B is a fresh journal under A's identity, not a copy of A.
      for (var index = 2; index < 52; index++) {
        await repositoryA.registerSet(
          sessionId: session.id,
          exerciseId: 'bench-press-example',
          setIndex: index,
          weight: 55,
          reps: 10,
        );
      }
      await repositoryA.finish(session.id);
      await repositoryA.flushOutbox();
      final deviceBStore = _MemoryStore();
      WorkoutVerticalRepository deviceB() => WorkoutVerticalRepository(
        localStore: deviceBStore,
        transport: DebugWorkoutSyncTransport(),
        historyReader: (revision, setId) => _authenticatedGet(
          userA,
          '/workout-sync/history?afterRevision=$revision&afterSetId=${Uri.encodeQueryComponent(setId)}',
        ),
      );
      await deviceB().pullHistory(maxPages: 1);
      expect((await deviceBStore.read()).sets, hasLength(50));
      expect(
        (await WorkoutHistoryRepository(
          localStore: deviceBStore,
        ).load()).workouts,
        isEmpty,
      );
      await deviceB().pullHistory();
      await deviceB()
          .pullHistory(); // Reconstructing the repository models restart.
      final imported = await deviceBStore.read();
      expect(imported.sessions.single.id, session.id);
      expect(
        imported.sets.map((set) => set.id).toSet(),
        (await storeA.read()).sets.map((set) => set.id).toSet(),
      );
      expect(imported.outbox, isEmpty);
      expect(
        (await WorkoutHistoryRepository(
          localStore: deviceBStore,
        ).load()).workouts,
        hasLength(1),
      );
      final otherOwnerStore = _MemoryStore();
      await WorkoutVerticalRepository(
        localStore: otherOwnerStore,
        transport: DebugWorkoutSyncTransport(),
        historyReader: (revision, setId) => _authenticatedGet(
          userB,
          '/workout-sync/history?afterRevision=$revision&afterSetId=$setId',
        ),
      ).pullHistory();
      expect((await otherOwnerStore.read()).sessions, isEmpty);

      // Real API plan definition -> device B -> tombstone, without deleting history.
      final plan = TreinoModel.fromJson({
        'id': session.planId,
        'nome': 'R7 Plan',
      });
      await _authenticatedPost(userA, '/sync/workouts', {
        'items': [plan.toJson()],
      });
      final definitions = await _authenticatedGet(userA, '/sync/workouts');
      expect((definitions['workouts'] as List).single['id'], plan.id);
      AccountSessionLifecycle.setActiveUser(userA.session.userId);
      await tamperedPreferences.setStringList('treinos', [
        jsonEncode(plan.toJson()),
      ]);
      expect(await StorageService.carregarTreinos(), hasLength(1));
      final deletion = await _authenticatedPost(
        userA,
        '/sync/workouts/delete',
        {'id': plan.id},
      );
      expect(deletion['deleted'], isTrue);
      final lostAckRetry = await _authenticatedPost(
        userA,
        '/sync/workouts/delete',
        {'id': plan.id},
      );
      expect(lostAckRetry['alreadyDeleted'], isTrue);
      final tombstones = await _authenticatedGet(
        userA,
        '/sync/workouts/deletions?afterRevision=0',
      );
      await StorageService.applyPlanDeletions(userA.session.userId, tombstones);
      await StorageService.applyPlanDeletions(userA.session.userId, tombstones);
      expect(await StorageService.carregarTreinos(), isEmpty);
      await expectLater(StorageService.salvarTreino(plan), throwsStateError);
      final stale = await _authenticatedPost(userA, '/sync/workouts', {
        'items': [plan.toJson()],
      });
      expect((stale['workouts'] as List).single['deletedAt'], isNotNull);
      expect(
        (await _authenticatedGet(userA, '/sync/workouts'))['workouts'],
        isEmpty,
      );
      expect(
        (await _authenticatedGet(
          userB,
          '/sync/workouts/deletions?afterRevision=0',
        ))['deletions'],
        isEmpty,
      );
      expect(
        (await WorkoutHistoryRepository(
          localStore: deviceBStore,
        ).load()).workouts,
        hasLength(1),
      );
      expect((await deviceBStore.read()).sets, hasLength(52));
      AccountSessionLifecycle.setActiveUser(null);

      primaryTransport.dispose();
      repositoryA.dispose();
      userBRepository.dispose();
      unauthorizedRepository.dispose();
      reauthenticatedRepository.dispose();
      tamperedRepository.dispose();
    },
    skip: _baseUrl.isEmpty || _runId.isEmpty
        ? 'Executado por npm run test:r1-4:auth-sync-e2e contra o PostgreSQL de teste.'
        : false,
  );
}

Future<Map<String, dynamic>> _authenticatedGet(
  _AuthenticatedUser user,
  String path,
) async {
  final response = await http.get(
    ApiConfig.endpoint(path),
    headers: {'Authorization': 'Bearer ${user.session.token}'},
  );
  expect(response.statusCode, 200, reason: path);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _authenticatedPost(
  _AuthenticatedUser user,
  String path,
  Map<String, dynamic> payload,
) async {
  final response = await http.post(
    ApiConfig.endpoint(path),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${user.session.token}',
    },
    body: jsonEncode(payload),
  );
  expect(response.statusCode, 200, reason: path);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<_AuthenticatedUser> _register(String user) async {
  final store = InMemoryAuthSessionStore();
  final authService = AuthService(sessionStore: store);
  final session = await authService.register(
    name: 'R1.4 User ${user.toUpperCase()}',
    email: 'r14-$user-$_runId@fitia.test',
    password: 'r1-4-auth-sync-password',
  );
  return _AuthenticatedUser(authService: authService, session: session);
}

OutboxEventLocal _foreignSetEvent(WorkoutSessionLocal session, String ownerId) {
  final now = DateTime.now().toUtc();
  final setId = 'r1-4-foreign-set-$_runId';
  return OutboxEventLocal(
    id: 'r1-4-foreign-event-$_runId',
    aggregateId: setId,
    sessionId: session.id,
    eventType: 'workout_set_completed',
    payload: {
      'set': {
        'id': setId,
        'sessionId': session.id,
        'exerciseId': 'bench-press-example',
        'setIndex': 9,
        'weight': 99,
        'reps': 1,
        'completedAt': now.toIso8601String(),
        // Este campo nao faz parte do contrato aceito pelo backend e nao e
        // enviado como owner; ele so documenta a tentativa no teste local.
        'claimedOwnerId': ownerId,
      },
    },
    createdAt: now,
    attempts: 0,
    nextAttemptAt: now,
    status: OutboxEventStatus.pending,
    idempotencyKey: 'workout_set_completed:$setId',
    version: 1,
  );
}

String _invalidateSignature(String token) {
  final last = token.substring(token.length - 1);
  return '${token.substring(0, token.length - 1)}${last == 'a' ? 'b' : 'a'}';
}

class _AuthenticatedUser {
  const _AuthenticatedUser({required this.authService, required this.session});

  final AuthService authService;
  final AuthSession session;
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot _snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => _snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    _snapshot = WorkoutSliceSnapshot.fromJson(snapshot.toJson());
  }
}

class _FailOnceClient extends http.BaseClient {
  final http.Client _delegate = http.Client();
  bool _shouldFail = true;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (_shouldFail) {
      _shouldFail = false;
      throw http.ClientException(
        'Falha transitória injetada pelo harness R1.4.',
      );
    }
    return _delegate.send(request);
  }

  @override
  void close() => _delegate.close();
}
