import 'package:fitai/core/exercises/exercise_catalog_identity.dart';
import 'package:fitai/core/exercises/exercise_identity.dart';
import 'package:fitai/core/exercises/exercise_library_intelligence.dart';
import 'package:fitai/core/exercises/exercise_library_local_store.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/ready_plan_exercise_model.dart';
import 'package:fitai/screens/exercicios/biblioteca/library_catalog_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ExerciseCatalogIdentity identity;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    identity = ExerciseCatalogIdentity(bancoExercicios);
  });

  test('LIB-ID-01: todos os exercícios oficiais têm exerciseId não vazio', () {
    expect(bancoExercicios, isNotEmpty);
    expect(
      bancoExercicios.every((exercise) => exercise.id.trim().isNotEmpty),
      isTrue,
    );
  });

  test('LIB-ID-02: exerciseIds canônicos são únicos', () {
    final ids = bancoExercicios.map((exercise) => exercise.id.trim()).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('LIB-ID-03: canonicalName não é vazio', () {
    expect(
      identity.entries.every((entry) => entry.canonicalName.isNotEmpty),
      isTrue,
    );
  });

  test('LIB-ID-04: alias resolve para o exercício correto', () {
    expect(
      identity.resolve(nameOrAlias: 'bench press')?.entry.canonicalId,
      'peito_001',
    );
  });

  test('LIB-ID-05: alias não cria nova identidade', () {
    final direct = identity.resolve(exerciseId: 'peito_001');
    final alias = identity.resolve(nameOrAlias: 'Supino reto');
    expect(alias?.entry.canonicalId, direct?.entry.canonicalId);
    expect(
      identity.entries.where((entry) => entry.canonicalId == 'peito_001'),
      hasLength(1),
    );
  });

  test('LIB-ID-06: referências de template resolvem sem trocar identidade', () {
    const templateExercises = <ReadyPlanExerciseModel>[
      ReadyPlanExerciseModel(
        id: 'template-1',
        exerciseId: 'supino-reto',
        exerciseName: 'Supino reto',
      ),
      ReadyPlanExerciseModel(
        id: 'template-2',
        exerciseId: 'costas_002',
        exerciseName: 'Remada Curvada com Barra',
      ),
      ReadyPlanExerciseModel(
        id: 'template-3',
        exerciseName: 'Tríceps Pulley com Corda',
      ),
    ];
    for (final exercise in templateExercises) {
      expect(
        identity.resolve(
          exerciseId: exercise.exerciseId,
          nameOrAlias: exercise.exerciseName,
        ),
        isNotNull,
        reason: exercise.exerciseName,
      );
    }
  });

  test('LIB-ID-07: exerciseIds de planos canônicos continuam válidos', () {
    const planIds = <String>['peito_001', 'costas_002', 'pernas_001'];
    for (final id in planIds) {
      expect(
        identity.resolve(exerciseId: id)?.kind,
        ExerciseCatalogIdKind.canonical,
      );
    }
  });

  test(
    'LIB-ID-08: history exerciseIds continuam resolvíveis sem adivinhar ambiguidade',
    () {
      expect(
        identity.resolve(exerciseId: 'supino-reto')?.entry.canonicalId,
        'peito_001',
      );
      expect(identity.resolve(exerciseId: 'agachamento-livre'), isNull);
    },
  );

  test('LIB-ID-09: PRs continuam associados ao ID estável', () {
    final prExerciseId = 'peito_001';
    final entry = identity.resolve(exerciseId: prExerciseId)?.entry;
    expect(entry?.canonicalId, prExerciseId);
  });

  test('LIB-ID-10: busca por canonicalName funciona', () async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.updateQuery('Supino Reto com Barra');
    expect(
      controller.visibleExercises.map((exercise) => exercise.id),
      contains('peito_001'),
    );
  });

  test('LIB-ID-11: busca por alias funciona', () async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.updateQuery('bench press');
    expect(
      controller.visibleExercises.map((exercise) => exercise.id),
      contains('peito_001'),
    );
  });

  test('LIB-ID-12: busca normaliza caixa e acento', () async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.updateQuery('SÚPINO RÉTO');
    expect(
      controller.visibleExercises.map((exercise) => exercise.id),
      contains('peito_001'),
    );
    expect(ExerciseIdentity.normalizeName('SÚPINO RÉTO'), 'supino reto');
  });

  test('LIB-ID-13: taxonomia muscular gera uma chave não vazia', () {
    for (final muscle in bancoExercicios.expand(
      (exercise) => exercise.musculos,
    )) {
      expect(ExerciseTaxonomy.muscleKey(muscle), isNotEmpty, reason: muscle);
    }
  });

  test('LIB-ID-14: taxonomia de equipamento gera uma chave não vazia', () {
    for (final equipment in bancoExercicios.expand(
      (exercise) => exercise.equipamentos,
    )) {
      expect(
        ExerciseTaxonomy.equipmentKey(equipment),
        isNotEmpty,
        reason: equipment,
      );
    }
  });

  test('LIB-ID-15: legacy resolver é determinístico', () {
    expect(
      identity.resolve(exerciseId: 'supino-reto')?.entry.canonicalId,
      'peito_001',
    );
    expect(
      identity.resolve(exerciseId: 'supino-reto')?.kind,
      ExerciseCatalogIdKind.legacy,
    );
    expect(identity.resolve(exerciseId: 'agachamento-livre'), isNull);
  });

  test('LIB-ID-16: nenhuma duplicata canônica de ID existe', () {
    expect(
      identity.entries.map((entry) => entry.canonicalId).toSet(),
      hasLength(identity.entries.length),
    );
  });

  test('LIB-ID-17: mediaKey reservado é estável e único', () {
    final mediaKeys = identity.entries.map((entry) => entry.mediaKey).toList();
    expect(mediaKeys.every((key) => key.startsWith('exercise/')), isTrue);
    expect(mediaKeys.toSet().length, mediaKeys.length);
  });

  test('LIB-ID-18: dados de USER_A e USER_B não se misturam', () async {
    final userA = SharedPreferencesExerciseLibraryLocalStore(
      userScope: 'user-a',
    );
    final userB = SharedPreferencesExerciseLibraryLocalStore(
      userScope: 'user-b',
    );
    await userA.toggleFavorite('peito_001');
    await userA.recordUse('peito_001', ExerciseUsageEvent.viewed);

    final stateA = await userA.load();
    final stateB = await userB.load();
    expect(stateA.favoriteIds, contains('peito_001'));
    expect(stateA.recentIds, contains('peito_001'));
    expect(stateB.favoriteIds, isNot(contains('peito_001')));
    expect(stateB.recentIds, isNot(contains('peito_001')));
  });

  test('LIB-ID-AUDIT: emite métricas reproduzíveis do catálogo', () {
    final ids = bancoExercicios.map((exercise) => exercise.id.trim()).toList();
    final normalizedNames = <String, int>{};
    final muscles = <String>{};
    final equipment = <String>{};
    var withoutMuscle = 0;
    var withoutEquipment = 0;
    var unknownMovement = 0;

    for (final exercise in bancoExercicios) {
      final name = ExerciseIdentity.normalizeName(exercise.nome);
      normalizedNames[name] = (normalizedNames[name] ?? 0) + 1;
      muscles.addAll(exercise.musculos.map(ExerciseTaxonomy.muscleKey));
      equipment.addAll(
        exercise.equipamentos.map(ExerciseTaxonomy.equipmentKey),
      );
      if (exercise.musculos.isEmpty) withoutMuscle++;
      if (exercise.equipamentos.isEmpty) withoutEquipment++;
      if (ExerciseTaxonomy.movementFor(exercise) ==
          ExerciseMovementPattern.unknown) {
        unknownMovement++;
      }
    }

    final duplicateNames = normalizedNames.values
        .where((count) => count > 1)
        .length;
    // ignore: avoid_print
    print(
      'LIB_ID_AUDIT total=${bancoExercicios.length} canonicalIds=${ids.toSet().length} '
      'duplicateIds=${ids.length - ids.toSet().length} duplicateNormalizedNames=$duplicateNames '
      'uniqueAliases=${identity.uniqueAliasCount} ambiguousAliases=${identity.ambiguousAliasCount} '
      'muscleKeys=${muscles.length} equipmentKeys=${equipment.length} '
      'withoutMuscle=$withoutMuscle withoutEquipment=$withoutEquipment '
      'unknownMovement=$unknownMovement mediaKeys=${identity.entries.length}',
    );
  });
}

LibraryCatalogController _controller() => LibraryCatalogController(
  catalogLoader: () async => List<ExercicioModel>.from(bancoExercicios),
  userScopeResolver: () => 'r3-library-test-user',
);
