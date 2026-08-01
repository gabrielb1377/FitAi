import 'package:fitai/core/exercises/exercise_library_intelligence.dart';
import 'package:fitai/core/exercises/exercise_library_local_store.dart';
import 'package:fitai/core/exercises/exercise_plan_integration.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ExerciseLibraryIntelligence intelligence;
  late List<ExercicioModel> catalog;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    intelligence = const ExerciseLibraryIntelligence();
    catalog = [_bench(), _dumbbellBench(), _pushUp(), _row(), _easyBench()];
  });

  test(
    'favorites are persisted without duplication and with stable order',
    () async {
      final firstStore = SharedPreferencesExerciseLibraryLocalStore();
      await firstStore.toggleFavorite('bench');
      final saved = await firstStore.toggleFavorite('row');

      expect(saved.favoriteIds, ['row', 'bench']);

      final restored = await SharedPreferencesExerciseLibraryLocalStore()
          .load();
      expect(restored.favoriteIds, ['row', 'bench']);

      final removed = await firstStore.toggleFavorite('row');
      expect(removed.favoriteIds, ['bench']);
    },
  );

  test(
    'recent usage is limited, ordered and does not duplicate the current item',
    () async {
      final store = SharedPreferencesExerciseLibraryLocalStore();
      for (var index = 0; index < 25; index++) {
        await store.recordUse('exercise-$index', ExerciseUsageEvent.viewed);
      }
      final repeated = await store.recordUse(
        'exercise-24',
        ExerciseUsageEvent.addedToPlan,
      );

      expect(repeated.recentIds, hasLength(20));
      expect(repeated.recentIds.first, 'exercise-24');
      expect(repeated.recentIds.last, 'exercise-5');
      expect(
        repeated.recentIds.where((id) => id == 'exercise-24'),
        hasLength(1),
      );
      expect(repeated.usageScoreById['exercise-24'], 5);

      final cleared = await store.clearRecents();
      expect(cleared.recentIds, isEmpty);
      expect(cleared.usageScoreById['exercise-24'], 5);
    },
  );

  test(
    'invalid library cache is isolated and legacy favorites are recovered',
    () async {
      final store = SharedPreferencesExerciseLibraryLocalStore();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(store.storageKey, '{invalid');
      await preferences.setStringList('favoritosExercicios', ['bench']);

      final state = await store.load();

      expect(state.favoriteIds, ['bench']);
      expect(preferences.getString(store.storageKey), isNot('{invalid'));
    },
  );

  test('most used is calculated from real local scores only', () {
    final result = intelligence.mostUsed(
      catalog: catalog,
      usageScoreById: const {'row': 8, 'bench': 6},
    );

    expect(result.map((exercise) => exercise.id), ['row', 'bench']);
  });

  test('related score excludes the exercise itself and exposes reasons', () {
    final results = intelligence.related(exercise: _bench(), catalog: catalog);

    expect(results.map((item) => item.exercise.id), isNot(contains('bench')));
    expect(results.first.exercise.id, 'dumbbell-bench');
    expect(
      results.first.reasons.map((reason) => reason.code),
      containsAll(['same_primary_muscle', 'same_movement']),
    );
    expect(results.first.score, greaterThanOrEqualTo(65));
  });

  test(
    'substitutions distinguish no-equipment and lower difficulty options',
    () {
      final substitutions = intelligence.substitutions(
        exercise: _bench(),
        catalog: catalog,
      );

      expect(
        substitutions.map((item) => item.kind),
        contains(ExerciseSubstitutionKind.noEquipment),
      );
      expect(
        substitutions.map((item) => item.kind),
        contains(ExerciseSubstitutionKind.easier),
      );
    },
  );

  test(
    'comparison remains objective and does not claim an absolute winner',
    () {
      final comparison = intelligence.compare(_bench(), _dumbbellBench());

      expect(comparison.sameMovement, isTrue);
      expect(comparison.sharedMuscles, contains('peitoral maior'));
      expect(comparison.summary.join(' '), isNot(contains('melhor')));
    },
  );

  test('collections are derived from catalog metadata', () {
    final collections = intelligence.collections(catalog);
    final push = collections.firstWhere((item) => item.id == 'push');
    final bodyweight = collections.firstWhere(
      (item) => item.id == 'bodyweight',
    );

    expect(push.exercises.map((exercise) => exercise.id), contains('bench'));
    expect(
      bodyweight.exercises.map((exercise) => exercise.id),
      contains('push-up'),
    );
  });

  test('related ranking stays below 100ms for a normal local catalog', () {
    final largeCatalog = List<ExercicioModel>.generate(
      1000,
      (index) => _exercise(
        id: 'bench-$index',
        name: 'Supino reto $index',
        category: 'Peito',
        muscles: const ['Peitoral maior'],
        equipment: const ['Barra'],
        difficulty: 'Intermediario',
      ),
    );
    // Measure the steady-state local ranking after lazy regex/JIT setup.
    intelligence.related(exercise: _bench(), catalog: largeCatalog.take(1));
    final watch = Stopwatch()..start();
    final recommendations = intelligence.related(
      exercise: _bench(),
      catalog: largeCatalog,
    );
    watch.stop();

    expect(recommendations, hasLength(8));
    expect(watch.elapsedMilliseconds, lessThan(100));
  });

  test('prescription copy keeps the canonical exercise identity intact', () {
    final configured = _bench().copyWith(
      series: 5,
      repeticoes: '6-8',
      descansoSegundos: 120,
    );

    expect(configured.id, 'bench');
    expect(configured.series, 5);
    expect(configured.repeticoes, '6-8');
    expect(_bench().series, 4);
  });

  test(
    'plan insertion uses the existing plan source and keeps day ordering',
    () async {
      final plan = _planWithRow();
      TreinoModel? saved;
      final integration = ExercisePlanIntegration(
        loadPlans: () async => [plan],
        savePlan: (value) async => saved = value,
      );

      final result = await integration.addToPlan(
        ExercisePlanInsertion(
          plan: plan,
          exercise: _bench(),
          dayIndex: 0,
          position: 0,
          sets: 5,
          repetitions: '6-8',
          restSeconds: 120,
        ),
      );

      expect(saved, isNotNull);
      expect(result.plan.exercicios.map((exercise) => exercise.id), [
        'bench',
        'row',
      ]);
      expect(result.plan.planoDias.single.exercicioIds, ['bench', 'row']);
      expect(result.insertedExercise.series, 5);
      expect(result.insertedExercise.descansoSegundos, 120);
      await expectLater(
        integration.addToPlan(
          ExercisePlanInsertion(
            plan: result.plan,
            exercise: _bench(),
            sets: 3,
            repetitions: '8-12',
            restSeconds: 90,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}

TreinoModel _planWithRow() => TreinoModel(
  id: 'plan-1',
  nome: 'Plano local',
  descricao: '',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  tempoEstimado: 45,
  criadoPorIA: false,
  exercicios: [_row()],
  planoDias: const [
    TreinoDiaModel(codigo: 'A', nome: 'Upper', ordem: 1, exercicioIds: ['row']),
  ],
  dataCriacao: '2026-01-01T00:00:00.000Z',
);

ExercicioModel _bench() => _exercise(
  id: 'bench',
  name: 'Supino reto com barra',
  category: 'Peito',
  muscles: const ['Peitoral maior'],
  equipment: const ['Barra', 'Banco'],
  difficulty: 'Intermediario',
);

ExercicioModel _dumbbellBench() => _exercise(
  id: 'dumbbell-bench',
  name: 'Supino reto com halteres',
  category: 'Peito',
  muscles: const ['Peitoral maior'],
  equipment: const ['Halteres', 'Banco'],
  difficulty: 'Intermediario',
);

ExercicioModel _pushUp() => _exercise(
  id: 'push-up',
  name: 'Flexao de bracos',
  category: 'Peito',
  muscles: const ['Peitoral maior'],
  equipment: const ['Peso corporal'],
  difficulty: 'Iniciante',
);

ExercicioModel _row() => _exercise(
  id: 'row',
  name: 'Remada baixa',
  category: 'Costas',
  muscles: const ['Dorsal'],
  equipment: const ['Cabo'],
  difficulty: 'Intermediario',
);

ExercicioModel _easyBench() => _exercise(
  id: 'easy-bench',
  name: 'Supino guiado',
  category: 'Peito',
  muscles: const ['Peitoral maior'],
  equipment: const ['Maquina'],
  difficulty: 'Iniciante',
);

ExercicioModel _exercise({
  required String id,
  required String name,
  required String category,
  required List<String> muscles,
  required List<String> equipment,
  required String difficulty,
}) => ExercicioModel(
  id: id,
  nome: name,
  categoria: category,
  descricao: 'Descricao local.',
  comoExecutar: 'Execute com controle.',
  cuidados: 'Mantenha a postura.',
  musculos: muscles,
  equipamentos: equipment,
  locais: const ['Academia'],
  dificuldade: difficulty,
  objetivo: 'Hipertrofia',
  imagem: '',
  video: '',
  tags: const ['Composto'],
  caloriasHora: 300,
  series: 4,
  repeticoes: '8-12',
  descansoSegundos: 90,
);
