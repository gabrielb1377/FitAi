import 'dart:async';
import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plans_controller.dart';
import 'package:fitai/services/network_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:fitai/services/treino_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.configure(baseUrl: 'https://plan-lifecycle.fitia.test');
  });

  tearDown(ApiConfig.reset);

  test('PLAN-01: criar plano e reiniciar preserva a definicao local', () async {
    final plan = _plan('created');
    await StorageService.salvarTreino(
      plan,
      syncService: _offlineSync('user-a'),
    );

    expect((await StorageService.carregarTreinos()).single.id, plan.id);
  });

  test('PLAN-02: editar plano e reiniciar preserva a alteracao', () async {
    final original = _plan('updated', name: 'Original');
    final updated = _plan('updated', name: 'Atualizado');
    await StorageService.salvarTreino(
      original,
      syncService: _offlineSync('user-a'),
    );
    await StorageService.salvarTreino(
      updated,
      syncService: _offlineSync('user-a'),
    );

    expect((await StorageService.carregarTreinos()).single.nome, 'Atualizado');
  });

  test(
    'PLAN-03: duplicar cria IDs independentes que sobrevivem ao reinicio',
    () async {
      final original = _plan('source');
      final duplicate = _plan('copy', name: 'Plano base (copia)');
      final sync = _offlineSync('user-a');
      await StorageService.salvarTreino(original, syncService: sync);
      await StorageService.salvarTreino(duplicate, syncService: sync);

      final ids = (await StorageService.carregarTreinos()).map(
        (item) => item.id,
      );
      expect(ids, containsAll([original.id, duplicate.id]));
    },
  );

  test('PLAN-04: excluir e reiniciar nao ressuscita o plano', () async {
    final plan = _plan('delete-restart');
    final sync = _offlineSync('user-a');
    await StorageService.salvarTreino(plan, syncService: sync);

    expect(
      await StorageService.removerTreino(plan.id, syncService: sync),
      isTrue,
    );
    expect(await StorageService.carregarTreinos(), isEmpty);
  });

  test(
    'PLAN-05: excluir offline permanece excluido apos reinicio offline',
    () async {
      final plan = _plan('delete-offline');
      final sync = _offlineSync('user-a');
      await StorageService.salvarTreino(plan, syncService: sync);
      await StorageService.removerTreino(plan.id, syncService: sync);
      await _waitFor(() async => (await sync.pendingCount()) == 1);

      expect(await StorageService.carregarTreinos(), isEmpty);
    },
  );

  test('PLAN-06: reconexao entrega delete sem recriar o plano local', () async {
    final plan = _plan('delete-reconnect');
    final offline = _offlineSync('user-a');
    await StorageService.salvarTreino(plan, syncService: offline);
    await StorageService.removerTreino(plan.id, syncService: offline);
    await _waitFor(() async => (await offline.pendingCount()) == 1);

    final onlineClient = _CaptureClient();
    final online = _syncFor('user-a', onlineClient);
    await online.flushPending();

    expect(onlineClient.deletedIds, [plan.id]);
    expect(await online.pendingCount(), 0);
    expect(await StorageService.carregarTreinos(), isEmpty);
  });

  test(
    'PLAN-07: replay de delete ocupa uma unica entrada idempotente',
    () async {
      final offline = _offlineSync('user-a');
      await offline.deleteWorkout('plan-replay');
      await offline.deleteWorkout('plan-replay');
      await _waitFor(() async => (await offline.pendingCount()) == 1);

      final onlineClient = _CaptureClient();
      final online = _syncFor('user-a', onlineClient);
      await online.flushPending();

      expect(onlineClient.deletedIds, ['plan-replay']);
    },
  );

  test(
    'PLAN-08: excluir plano ativo deixa uma sessao existente recuperavel',
    () async {
      final plan = _plan('active-delete');
      await StorageService.salvarTreino(
        plan,
        syncService: _offlineSync('user-a'),
      );
      final repository = _repository();
      final session = await repository.startOrRecover(
        planId: plan.id,
        workoutId: plan.id,
        workoutSnapshot: plan.toJson(),
      );

      await StorageService.removerTreino(
        plan.id,
        syncService: _offlineSync('user-a'),
      );
      final recovered = await repository.activeSession();

      expect(recovered?.id, session.id);
      expect(recovered?.workoutSnapshot?['id'], plan.id);
    },
  );

  test('PLAN-09: excluir o unico plano deixa a lista oficial vazia', () async {
    final plan = _plan('last-plan');
    await StorageService.salvarTreino(
      plan,
      syncService: _offlineSync('user-a'),
    );
    final service = TreinoService.instance;
    await service.initialize(force: true);
    final controller = PlansController(
      workoutService: service,
      useDeveloperFallback: false,
      checkBackend: () async => false,
    );
    addTearDown(controller.dispose);
    await controller.initialize(force: true);

    await service.removerTreinoComPersistencia(plan.id);

    expect(controller.plans, isEmpty);
  });

  test(
    'PLAN-10: excluir plano nao apaga sessao concluida do journal',
    () async {
      final plan = _plan('history-preserved');
      await StorageService.salvarTreino(
        plan,
        syncService: _offlineSync('user-a'),
      );
      final repository = _repository();
      final session = await repository.startOrRecover(
        planId: plan.id,
        workoutId: plan.id,
        workoutSnapshot: plan.toJson(),
      );
      await repository.finish(session.id);

      await StorageService.removerTreino(
        plan.id,
        syncService: _offlineSync('user-a'),
      );
      final snapshot = await repository.load();

      expect(snapshot.sessions.single.id, session.id);
      expect(snapshot.sessions.single.status, WorkoutSessionStatus.completed);
    },
  );

  test(
    'PLAN-11: sessao ativa conserva o snapshot apos exclusao do plano',
    () async {
      final plan = _plan('active-snapshot');
      final repository = _repository();
      final session = await repository.startOrRecover(
        planId: plan.id,
        workoutId: plan.id,
        workoutSnapshot: plan.toJson(),
      );

      await StorageService.salvarTreino(
        plan,
        syncService: _offlineSync('user-a'),
      );
      await StorageService.removerTreino(
        plan.id,
        syncService: _offlineSync('user-a'),
      );

      expect(
        (await repository.load()).sessions.single.workoutSnapshot,
        session.workoutSnapshot,
      );
    },
  );

  test(
    'PLAN-12: excluir instancia de template nao altera o template de origem',
    () async {
      final templateId = 'ready-template-1';
      final instance = _plan('template-instance', readyPlanId: templateId);
      await StorageService.salvarTreino(
        instance,
        syncService: _offlineSync('user-a'),
      );

      await StorageService.removerTreino(
        instance.id,
        syncService: _offlineSync('user-a'),
      );

      expect(instance.readyPlanId, templateId);
      expect(await StorageService.carregarTreinos(), isEmpty);
    },
  );

  test(
    'PLAN-13: plano IA salvo e excluido permanece ausente apos reinicio',
    () async {
      final plan = _plan('ai-delete', createdByAi: true);
      final sync = _offlineSync('user-a');
      await StorageService.salvarTreino(plan, syncService: sync);
      await StorageService.removerTreino(plan.id, syncService: sync);

      final afterRestart = await StorageService.carregarTreinos();
      expect(afterRestart.where((item) => item.id == plan.id), isEmpty);
    },
  );

  test('PLAN-14: exclusao de A nao vaza nem ressuscita para B', () async {
    final boundary = LocalAccountDataBoundary();
    await boundary.activate('user-a', claimUnownedData: true);
    final plan = _plan('owned-delete');
    await StorageService.salvarTreino(
      plan,
      syncService: _offlineSync('user-a'),
    );
    await StorageService.removerTreino(
      plan.id,
      syncService: _offlineSync('user-a'),
    );

    await boundary.activate('user-b');
    expect(await StorageService.carregarTreinos(), isEmpty);

    await boundary.activate('user-a');
    expect(await StorageService.carregarTreinos(), isEmpty);
  });

  test(
    'PLAN-15: memoria e fonte persistida convergem para Home apos exclusao',
    () async {
      final plan = _plan('home-lifecycle');
      final service = TreinoService.instance;
      await StorageService.salvarTreino(
        plan,
        syncService: _offlineSync('user-a'),
      );
      await service.initialize(force: true);

      expect(await service.removerTreinoComPersistencia(plan.id), isTrue);
      expect(service.treinos, isEmpty);
      expect(await StorageService.carregarTreinos(), isEmpty);
    },
  );
}

TreinoModel _plan(
  String id, {
  String? name,
  bool createdByAi = false,
  String? readyPlanId,
}) => TreinoModel(
  id: id,
  nome: name ?? 'Plano $id',
  descricao: 'Plano de ciclo de vida.',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  tempoEstimado: 45,
  criadoPorIA: createdByAi,
  exercicios: const [],
  dataCriacao: DateTime.utc(2026, 8, 26).toIso8601String(),
  readyPlanId: readyPlanId,
);

WorkoutVerticalRepository _repository() => WorkoutVerticalRepository(
  localStore: _MemoryStore(),
  transport: DebugWorkoutSyncTransport(),
);

SyncService _offlineSync(String userId) => _syncFor(userId, _OfflineClient());

SyncService _syncFor(String userId, http.Client client) =>
    SyncService.forTesting(
      networkService: NetworkService(client: client),
      authService: _authFor(userId),
    );

AuthService _authFor(String userId) {
  final store = InMemoryAuthSessionStore();
  unawaited(
    store.write(
      jsonEncode(
        AuthSession(
          userId: userId,
          name: userId,
          email: '$userId@fitia.test',
          token: _token(),
        ).toJson(),
      ),
    ),
  );
  return AuthService(sessionStore: store);
}

Future<void> _waitFor(Future<bool> Function() condition) async {
  for (var attempt = 0; attempt < 40; attempt += 1) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('A fila local nao atingiu o estado esperado.');
}

String _token() {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          }),
        ),
      )
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot _snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => _snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      throw http.ClientException('offline');
}

class _CaptureClient extends http.BaseClient {
  final List<String> deletedIds = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'POST' &&
        request.url.path == '/sync/workouts/delete' &&
        request is http.Request) {
      deletedIds.add((jsonDecode(request.body) as Map)['id'].toString());
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
