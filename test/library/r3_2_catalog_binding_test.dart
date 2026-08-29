import 'dart:async';
import 'dart:convert';

import 'package:fitai/core/exercises/exercise_catalog_binding.dart';
import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/ready_plan_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/backend_ai_service.dart';
import 'package:fitai/services/ready_plan_mapper.dart';
import 'package:fitai/services/ready_plans_service.dart';
import 'package:fitai/services/network_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  ApiConfig.configure(baseUrl: 'https://catalog-binding.fitia.test');
  final binder = ExerciseCatalogBinder(bancoExercicios);

  test('LIB-BIND-01: os 27 nomes do seed têm estado explícito', () {
    final bindings = _seedNames
        .map(
          (name) => binder.bindTemplate(
            templateItemId: 'seed-$name',
            remoteExerciseId: 'remote-$name',
            exerciseName: name,
          ),
        )
        .toList();

    final unresolved = bindings
        .where((item) => !item.isResolved)
        .map((item) => item.sourceName)
        .toList();
    expect(bindings.where((item) => item.isResolved), hasLength(25));
    expect(
      unresolved,
      unorderedEquals(const ['Remada com mochila', 'Barra fixa assistida']),
    );
  });

  test('LIB-BIND-02: canonicalExerciseId vence sem depender de nome', () {
    final binding = binder.bindAi(
      templateItemId: 'item-1',
      remoteExerciseId: 'uuid-1',
      canonicalExerciseId: 'peito_001',
      exerciseName: 'nome remoto diferente',
    );
    expect(binding.canonicalExerciseId, 'peito_001');
    expect(binding.method, ExerciseCatalogBindingMethod.canonical);
  });

  test('LIB-BIND-03: redirect legado seguro mantém ID canônico', () {
    final binding = binder.bindAi(
      templateItemId: 'item-1',
      remoteExerciseId: '',
      canonicalExerciseId: 'supino-reto',
      exerciseName: 'Supino reto',
    );
    expect(binding.canonicalExerciseId, 'peito_001');
    expect(binding.method, ExerciseCatalogBindingMethod.legacy);
  });

  test('LIB-BIND-04: ID canônico inválido não usa nome como atalho', () {
    final binding = binder.bindAi(
      templateItemId: 'item-1',
      remoteExerciseId: '',
      canonicalExerciseId: 'uuid-remoto-invalido',
      exerciseName: 'Supino Reto com Barra',
    );
    expect(binding.status, ExerciseCatalogBindingStatus.unresolved);
  });

  test('LIB-BIND-05: nome exato resolve de forma determinística', () {
    final binding = _template(binder, 'Supino Reto com Barra');
    expect(binding.canonicalExerciseId, 'peito_001');
    expect(binding.method, ExerciseCatalogBindingMethod.exactName);
  });

  test('LIB-BIND-06: alias único resolve sem fuzzy matching', () {
    final binding = _template(binder, 'Puxada frontal');
    expect(binding.canonicalExerciseId, 'costas_001');
    expect(binding.method, ExerciseCatalogBindingMethod.alias);
  });

  test('LIB-BIND-07: mapping editorial resolve legado de template', () {
    final binding = _template(binder, 'Mesa flexora');
    expect(binding.canonicalExerciseId, 'pernas_004');
    expect(binding.method, ExerciseCatalogBindingMethod.manual);
  });

  test(
    'LIB-BIND-08: agachamento do template usa decisão editorial específica',
    () {
      final binding = _template(binder, 'Agachamento livre');
      expect(binding.canonicalExerciseId, 'pernas_001');
      expect(binding.method, ExerciseCatalogBindingMethod.manual);
    },
  );

  test('LIB-BIND-09: UUID remoto não é promovido a identidade local', () {
    final binding = _template(
      binder,
      'Leg press',
      remoteExerciseId: '8b7802d8-remote',
    );
    expect(binding.remoteExerciseId, '8b7802d8-remote');
    expect(binding.canonicalExerciseId, 'pernas_002');
  });

  test('LIB-BIND-10: nomes ambíguos ficam explícitos sem resolver', () {
    final synthetic = ExerciseCatalogBinder([
      _exercise('first', 'Movimento igual'),
      _exercise('second', 'Movimento igual'),
    ]);
    final binding = synthetic.bindAi(
      templateItemId: 'item',
      remoteExerciseId: '',
      exerciseName: 'Movimento igual',
    );
    expect(binding.status, ExerciseCatalogBindingStatus.ambiguous);
  });

  test('LIB-BIND-11: desconhecido não cria ID derivado', () {
    final binding = _template(binder, 'Remada com mochila');
    expect(binding.isResolved, isFalse);
    expect(binding.canonicalExerciseId, isEmpty);
  });

  test('LIB-BIND-12: binding expõe nome e mediaKey canônicos', () {
    final binding = _template(binder, 'Supino Reto com Barra');
    expect(binding.canonicalName, 'Supino Reto com Barra');
    expect(binding.mediaKey, 'exercise/peito_001');
  });

  test(
    'LIB-BIND-13: execução e PR usam identidade canônica, não ocorrência',
    () {
      final treino = ReadyPlanMapper.toTreino(
        _readyPlan('Supino Reto com Barra'),
        workoutId: 'workout-1',
        source: 'ready_plan_offline',
      );
      final exercise = treino.exercicios.single;
      expect(exercise.id, 'workout-1_day-1_item-1');
      expect(exercise.canonicalExerciseId, 'peito_001');
      expect(exercise.templateItemId, 'item-1');

      final now = DateTime.utc(2026, 8, 28, 12);
      final snapshot = WorkoutSliceSnapshot(
        schemaVersion: 1,
        outbox: const [],
        sessions: [
          WorkoutSessionLocal(
            id: 'session-1',
            planId: 'plan-1',
            workoutId: 'workout-1',
            startedAt: now.subtract(const Duration(minutes: 45)),
            finishedAt: now,
            status: WorkoutSessionStatus.completed,
            currentExerciseIndex: 0,
            currentSetIndex: 0,
            updatedAt: now,
            syncStatus: WorkoutSyncStatus.synced,
            version: 1,
          ),
        ],
        sets: [
          _journalSet(
            id: 'set-a',
            occurrenceId: exercise.id,
            canonicalExerciseId: exercise.canonicalExerciseId,
            completedAt: now.subtract(const Duration(minutes: 5)),
          ),
          _journalSet(
            id: 'set-b',
            occurrenceId: 'another-plan_occurrence-2',
            canonicalExerciseId: exercise.canonicalExerciseId,
            completedAt: now,
          ),
        ],
      );
      final history = WorkoutHistoryRepository(
        localStore: _UnusedWorkoutStore(),
      ).project(snapshot);
      expect(history.workouts.single.exercises, hasLength(1));
      expect(history.exercisePrs.single.exerciseId, 'peito_001');
    },
  );

  test('LIB-BIND-14: template preserva o remoteExerciseId sem misturá-lo', () {
    final treino = ReadyPlanMapper.toTreino(
      _readyPlan('Supino Reto com Barra', remoteExerciseId: 'backend-uuid'),
      workoutId: 'workout-1',
      source: 'ready_plan',
    );
    expect(treino.exercicios.single.remoteExerciseId, 'backend-uuid');
    expect(treino.exercicios.single.canonicalExerciseId, 'peito_001');
  });

  test('LIB-BIND-15: template sem vínculo seguro não chega à persistência', () {
    expect(
      () => ReadyPlanMapper.toTreino(
        _readyPlan('Remada com mochila'),
        workoutId: 'workout-1',
        source: 'ready_plan_offline',
      ),
      throwsA(isA<ReadyPlanBindingException>()),
    );
  });

  test(
    'LIB-BIND-16: template cacheado offline preserva identidade canônica',
    () async {
      final readyPlans = ReadyPlansService(client: _OfflineClient());
      await readyPlans.savePlanDetailCache(_readyPlan('Supino Reto com Barra'));
      final cached = await readyPlans.getPlanDetails('ready-1');
      final treino = ReadyPlanMapper.toTreino(
        cached,
        workoutId: 'workout-1',
        source: 'ready_plan_offline',
      );
      final restored = TreinoModel.fromJson(treino.toJson());
      expect(restored.exercicios.single.canonicalExerciseId, 'peito_001');
      expect(restored.exercicios.single.templateItemId, 'item-1');
    },
  );

  test('LIB-BIND-17: IA aceita resposta já ligada ao catálogo', () async {
    final treino = await _generateAiPlan([
      {'id': 'ai-1', 'canonicalExerciseId': 'peito_001', 'nome': 'qualquer'},
    ]);
    expect(treino.exercicios.first.canonicalExerciseId, 'peito_001');
    expect(treino.exercicios.first.id, 'ai-1');
  });

  test('LIB-BIND-18: IA resolve alias seguro do catálogo', () async {
    final treino = await _generateAiPlan([
      {'id': 'ai-1', 'nome': 'Puxada frontal'},
    ]);
    expect(treino.exercicios.first.canonicalExerciseId, 'costas_001');
  });

  test(
    'LIB-BIND-19: IA rejeita nome fora do catálogo antes de salvar',
    () async {
      await expectLater(
        _generateAiPlan([
          {'id': 'ai-1', 'nome': 'Exercício inventado pelo provider'},
        ]),
        throwsA(isA<BackendAIException>()),
      );
    },
  );

  test(
    'LIB-BIND-20: template persistido respeita ownership e ocorrência',
    () async {
      final first = _template(binder, 'Supino Reto com Barra');
      final second = binder.bindTemplate(
        templateItemId: 'item-2',
        remoteExerciseId: '',
        exerciseName: 'Supino Reto com Barra',
      );
      expect(first.canonicalExerciseId, second.canonicalExerciseId);
      expect(first.templateItemId, isNot(equals(second.templateItemId)));

      final boundary = LocalAccountDataBoundary();
      await boundary.activate('template-owner-a', claimUnownedData: true);
      final treino = ReadyPlanMapper.toTreino(
        _readyPlan('Supino Reto com Barra'),
        workoutId: 'workout-owner',
        source: 'ready_plan_offline',
      );
      await StorageService.salvarTreino(
        treino,
        syncService: _offlineSyncFor('template-owner-a'),
      );

      await boundary.activate('template-owner-b');
      expect(await StorageService.carregarTreinos(), isEmpty);
      await boundary.activate('template-owner-a');
      final restored = await StorageService.carregarTreinos();
      expect(
        restored.single.exercicios.single.canonicalExerciseId,
        'peito_001',
      );
    },
  );
}

const _seedNames = [
  'Supino reto com barra',
  'Supino inclinado com halteres',
  'Crucifixo no cabo',
  'Tríceps na polia',
  'Puxada frontal',
  'Remada baixa',
  'Remada unilateral com halter',
  'Rosca direta',
  'Agachamento livre',
  'Leg press',
  'Mesa flexora',
  'Panturrilha em pé',
  'Supino reto com halteres',
  'Desenvolvimento com halteres',
  'Rosca alternada',
  'Agachamento goblet',
  'Levantamento terra romeno',
  'Cadeira extensora',
  'Prancha',
  'Levantamento terra',
  'Remada curvada',
  'Agachamento com peso corporal',
  'Flexão de braços',
  'Remada com mochila',
  'Barra fixa assistida',
  'Afundo alternado',
  'Elevação de pernas',
];

ExerciseCatalogBinding _template(
  ExerciseCatalogBinder binder,
  String name, {
  String remoteExerciseId = '',
}) => binder.bindTemplate(
  templateItemId: 'item-$name',
  remoteExerciseId: remoteExerciseId,
  exerciseName: name,
);

ReadyPlanModel _readyPlan(String name, {String remoteExerciseId = ''}) =>
    ReadyPlanModel.fromJson({
      'id': 'ready-1',
      'nome': 'Plano pronto',
      'dias': [
        {
          'id': 'day-1',
          'nome': 'Dia A',
          'titulo': 'Peito',
          'exercicios': [
            {
              'id': 'item-1',
              'exerciseId': remoteExerciseId,
              'nome': name,
              'series': 3,
              'repeticoes': '8-12',
              'descanso': 90,
            },
          ],
        },
      ],
    });

ExercicioModel _exercise(String id, String name) => ExercicioModel(
  id: id,
  nome: name,
  categoria: 'Teste',
  descricao: '',
  comoExecutar: '',
  cuidados: '',
  musculos: const [],
  equipamentos: const [],
  locais: const [],
  dificuldade: '',
  objetivo: '',
  imagem: '',
  video: '',
  tags: const [],
  caloriasHora: 0,
);

Future<TreinoModel> _generateAiPlan(List<Map<String, String>> exercises) async {
  final sessionStore = InMemoryAuthSessionStore();
  await sessionStore.write(
    jsonEncode({
      'userId': 'user-a',
      'name': 'User A',
      'email': 'user-a@fitia.test',
      'token': _token(),
    }),
  );
  final payloadExercises = <Map<String, String>>[
    ...exercises,
    ..._validAiExercises,
  ].take(6).toList(growable: false);
  final service = BackendAIService(
    authService: AuthService(sessionStore: sessionStore),
    client: _AiClient(payloadExercises),
  );
  return service.generateWorkout(
    objetivo: 'Hipertrofia',
    divisao: 'Full Body',
    nivel: 'Iniciante',
    diasPorSemana: 1,
    tempoPorTreino: 45,
    minExerciciosPorDia: 6,
    local: 'Academia',
    equipamentos: const [],
    restricoes: const [],
    prioridades: const [],
  );
}

const _validAiExercises = [
  {'id': 'fallback-1', 'nome': 'Supino Reto com Barra'},
  {'id': 'fallback-2', 'nome': 'Supino Inclinado com Halteres'},
  {'id': 'fallback-3', 'nome': 'Crucifixo no Cabo'},
  {'id': 'fallback-4', 'nome': 'Puxada Frontal na Polia Alta'},
  {'id': 'fallback-5', 'nome': 'Remada Curvada com Barra'},
  {'id': 'fallback-6', 'nome': 'Rosca Direta com Barra'},
];

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

SyncService _offlineSyncFor(String userId) => SyncService.forTesting(
  networkService: NetworkService(client: _OfflineClient()),
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

class _AiClient extends http.BaseClient {
  _AiClient(this.exercises);

  final List<Map<String, String>> exercises;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = {
      'id': 'ai-plan-1',
      'nome': 'Plano IA',
      'dias': [
        {
          'nome': 'Dia A',
          'titulo': 'Treino',
          'exercicios': exercises
              .map(
                (exercise) => {
                  ...exercise,
                  'series': 3,
                  'repeticoes': '8-12',
                  'descanso': 90,
                },
              )
              .toList(),
        },
      ],
    };
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode(body))),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      throw http.ClientException('offline');
}

WorkoutSetLocal _journalSet({
  required String id,
  required String occurrenceId,
  required String canonicalExerciseId,
  required DateTime completedAt,
}) => WorkoutSetLocal(
  id: id,
  sessionId: 'session-1',
  exerciseId: occurrenceId,
  canonicalExerciseId: canonicalExerciseId,
  exerciseName: 'Supino Reto com Barra',
  setIndex: 0,
  weight: 55,
  reps: 10,
  completedAt: completedAt,
  updatedAt: completedAt,
  syncStatus: WorkoutSyncStatus.synced,
  version: 1,
);

class _UnusedWorkoutStore implements WorkoutVerticalLocalStore {
  @override
  Future<WorkoutSliceSnapshot> read() async =>
      const WorkoutSliceSnapshot.empty();

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {}
}
