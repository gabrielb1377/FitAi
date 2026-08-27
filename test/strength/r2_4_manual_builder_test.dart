import 'dart:io';

import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/plans/domain/manual_plan_draft.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/exercicios/biblioteca/library_catalog_controller.dart';
import 'package:fitai/screens/treinos/official/official_plan_model_utils.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('BUILDER-01: a rota oficial mantém o builder manual oficial', () {
    final source = File(
      'lib/features/plans/presentation/routes/plans_routes.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('createManual: (_, _) => const PlanosManualGoalPage()'),
    );
  });

  test('BUILDER-02: catálogo exibido vem da fonte local oficial', () async {
    final controller = LibraryCatalogController();
    addTearDown(controller.dispose);
    await controller.initialize();

    expect(controller.exercises, isNotEmpty);
    expect(controller.exercises.first.id, startsWith('peito_'));
  });

  test('BUILDER-03: exerciseId real é preservado no plano final', () {
    final draft = _configuredDraft();
    final plan = draft.toPlan(name: 'Manual', level: 'Intermediário');

    expect(plan.exercicios.single.id, 'catalog-bench');
    expect(plan.planoDias.single.exercicioIds, ['catalog-bench']);
  });

  test('BUILDER-04: seleção e remoção usam a identidade do catálogo', () {
    final draft = ManualPlanDraft(id: 'manual-select', goal: 'Força');
    final exercise = _exercise();

    expect(
      draft.addExercise(dayId: draft.days.single.id, exercise: exercise),
      ManualPlanDraftSelectionResult.added,
    );
    expect(
      draft.addExercise(dayId: draft.days.single.id, exercise: exercise),
      ManualPlanDraftSelectionResult.duplicate,
    );
    expect(
      draft.removeExercise(
        dayId: draft.days.single.id,
        exerciseId: exercise.id,
      ),
      isTrue,
    );
    expect(draft.exerciseCount, 0);
  });

  test('BUILDER-05: prescrição válida materializa entidade persistível', () {
    final plan = _configuredDraft().toPlan(
      name: 'Upper manual',
      level: 'Intermediário',
    );

    expect(plan.exercicios.single.series, 4);
    expect(plan.exercicios.single.repeticoes, '8-10');
    expect(plan.exercicios.single.descansoSegundos, 90);
  });

  test('BUILDER-06: entidade inválida não materializa plano', () {
    final draft = ManualPlanDraft(id: 'manual-invalid', goal: 'Força');
    draft.addExercise(dayId: draft.days.single.id, exercise: _exercise());

    expect(draft.validate(), isNotNull);
    expect(
      () => draft.toPlan(name: 'Inválido', level: 'Intermediário'),
      throwsStateError,
    );
  });

  test('BUILDER-07: catálogo local e save local funcionam sem rede', () async {
    final controller = LibraryCatalogController();
    addTearDown(controller.dispose);
    await controller.initialize();
    final draft = ManualPlanDraft(id: 'manual-offline', goal: 'Força');
    final selected = controller.exercises.first;
    draft.addExercise(dayId: draft.days.single.id, exercise: selected);
    draft.updatePrescription(
      dayId: draft.days.single.id,
      exerciseId: selected.id,
      sets: 3,
      reps: '10',
      restSeconds: 60,
    );

    final plan = draft.toPlan(name: 'Offline', level: 'Intermediário');
    await StorageService.salvarTreino(plan);
    expect((await StorageService.carregarTreinos()).single.id, plan.id);
  });

  test('BUILDER-08: reinício após save preserva o plano manual', () async {
    final plan = _configuredDraft(
      id: 'manual-restart',
    ).toPlan(name: 'Persistente', level: 'Intermediário');
    await StorageService.salvarTreino(plan);

    final loaded = await StorageService.carregarTreinos();
    expect(loaded.single.toJson(), plan.toJson());
  });

  test('BUILDER-09: edição após criar usa o mesmo ID e persiste', () async {
    final original = _configuredDraft(
      id: 'manual-edit',
    ).toPlan(name: 'Antes', level: 'Intermediário');
    final edited = copyOfficialPlan(original, name: 'Depois');
    await StorageService.salvarTreino(original);
    await StorageService.salvarTreino(edited);

    final loaded = await StorageService.carregarTreinos();
    expect(loaded, hasLength(1));
    expect(loaded.single.nome, 'Depois');
    expect(loaded.single.exercicios.single.id, 'catalog-bench');
  });

  test('BUILDER-10: duplicar plano manual cria ID independente', () async {
    final original = _configuredDraft(
      id: 'manual-original',
    ).toPlan(name: 'Original', level: 'Intermediário');
    final duplicate = copyOfficialPlan(
      original,
      id: 'manual-duplicate',
      name: 'Cópia',
    );
    await StorageService.salvarTreino(original);
    await StorageService.salvarTreino(duplicate);

    final ids = (await StorageService.carregarTreinos()).map((plan) => plan.id);
    expect(ids, containsAll(['manual-original', 'manual-duplicate']));
  });

  test('BUILDER-11: delete reutiliza lifecycle persistente', () async {
    final plan = _configuredDraft(
      id: 'manual-delete',
    ).toPlan(name: 'Excluir', level: 'Intermediário');
    await StorageService.salvarTreino(plan);
    await StorageService.removerTreino(plan.id);

    expect(await StorageService.carregarTreinos(), isEmpty);
  });

  test('BUILDER-12: plano manual inicia na jornada canônica', () async {
    final plan = _configuredDraft(
      id: 'manual-start',
    ).toPlan(name: 'Iniciar', level: 'Intermediário');
    final store = _MemoryStore();
    final controller = CoreJourneyController(
      identityResolver: () async => const CoreJourneyIdentity(
        userId: 'manual-builder-user',
        name: 'Manual Builder User',
        isAuthenticated: true,
      ),
      planLoader: () async => [plan],
      repositoryFactory: (_) async => WorkoutVerticalRepository(
        localStore: store,
        transport: const _OfflineTransport(),
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    final session = await controller.startPlan(plan);

    expect(session?.planId, plan.id);
    expect(
      store.snapshot.sessions.single.workoutSnapshot?['id'],
      '${plan.id}_1',
    );
  });

  test(
    'BUILDER-13: Manual, Template e IA convergem no mesmo domínio final',
    () {
      final manual = _configuredDraft(
        id: 'manual-convergence',
      ).toPlan(name: 'Manual', level: 'Intermediário');
      final template = _copyPlan(
        manual,
        id: 'template-convergence',
        readyPlanId: 'ready-1',
      );
      final ai = _copyPlan(manual, id: 'ai-convergence', createdByAi: true);

      for (final plan in [manual, template, ai]) {
        expect(plan.planoDias, isNotEmpty);
        expect(plan.exercicios.single.id, 'catalog-bench');
      }
    },
  );

  test('BUILDER-14: rota oficial não contém exercícios exemplo', () {
    final source = File(
      'lib/features/plans/presentation/pages/planos_official_wizards.dart',
    ).readAsStringSync();
    expect(source, isNot(contains("'Supino reto'")));
    expect(source, isNot(contains("'Remada curvada'")));
    expect(source, contains('BibliotecaExerciciosPage'));
  });

  test('BUILDER-15: plano manual de A não aparece para B', () async {
    final boundary = LocalAccountDataBoundary();
    await boundary.activate('manual-user-a', claimUnownedData: true);
    final plan = _configuredDraft(
      id: 'manual-owner',
    ).toPlan(name: 'Owner A', level: 'Intermediário');
    await StorageService.salvarTreino(plan);

    await boundary.activate('manual-user-b');
    expect(await StorageService.carregarTreinos(), isEmpty);

    await boundary.activate('manual-user-a');
    expect((await StorageService.carregarTreinos()).single.id, plan.id);
  });
}

ManualPlanDraft _configuredDraft({String id = 'manual-plan'}) {
  final draft = ManualPlanDraft(id: id, goal: 'Força');
  final exercise = _exercise();
  draft.addExercise(dayId: draft.days.single.id, exercise: exercise);
  draft.updatePrescription(
    dayId: draft.days.single.id,
    exerciseId: exercise.id,
    sets: 4,
    reps: '8-10',
    restSeconds: 90,
  );
  return draft;
}

TreinoModel _copyPlan(
  TreinoModel source, {
  required String id,
  bool createdByAi = false,
  String? readyPlanId,
}) => TreinoModel(
  id: id,
  nome: source.nome,
  descricao: source.descricao,
  objetivo: source.objetivo,
  nivel: source.nivel,
  divisao: source.divisao,
  tempoEstimado: source.tempoEstimado,
  diasPorSemana: source.diasPorSemana,
  planoDias: source.planoDias,
  criadoPorIA: createdByAi,
  exercicios: source.exercicios,
  dataCriacao: source.dataCriacao,
  origem: createdByAi ? 'ai' : source.origem,
  readyPlanId: readyPlanId,
);

ExercicioModel _exercise() => ExercicioModel(
  id: 'catalog-bench',
  nome: 'Supino do catálogo',
  categoria: 'Peito',
  descricao: 'Exercício real de teste do catálogo.',
  comoExecutar: 'Executar com técnica.',
  cuidados: 'Controlar a carga.',
  musculos: const ['Peito'],
  equipamentos: const ['Barra'],
  locais: const ['Academia'],
  dificuldade: 'Intermediário',
  objetivo: 'Força',
  imagem: '',
  video: '',
  tags: const ['supino'],
  caloriasHora: 0,
);

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    snapshot = WorkoutSliceSnapshot.fromJson(value.toJson());
  }
}

class _OfflineTransport implements WorkoutVerticalSyncTransport {
  const _OfflineTransport();

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) {
    throw const WorkoutSyncTransportException('Offline', retryable: true);
  }
}
