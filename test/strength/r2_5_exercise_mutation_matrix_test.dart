import 'package:fitai/core/exercises/exercise_plan_integration.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('MUT-01: plano ADD sobrevive ao restart', () async {
    final plan = _plan(exercises: [_exercise('bench')]);
    await StorageService.salvarTreino(plan);
    final integration = _planIntegration();

    final result = await integration.addToPlan(
      ExercisePlanInsertion(
        plan: plan,
        exercise: _exercise('row'),
        dayIndex: 0,
        sets: 3,
        repetitions: '10',
        restSeconds: 60,
      ),
    );

    expect(result.plan.planoDias.single.exercicioIds, ['bench', 'row']);
    expect(
      (await StorageService.carregarTreinos()).single.exercicios.last.id,
      'row',
    );
  });

  test('MUT-02: plano REPLACE preserva estrutura apos restart', () async {
    final plan = _plan(exercises: [_exercise('bench'), _exercise('row')]);
    await StorageService.salvarTreino(plan);

    final updated = await _planIntegration().replaceInPlan(
      plan: plan,
      previousExerciseId: 'bench',
      replacement: _exercise('incline'),
    );
    final restarted = (await StorageService.carregarTreinos()).single;

    expect(updated.planoDias.single.exercicioIds, ['incline', 'row']);
    expect(restarted.exercicios.map((item) => item.id), ['incline', 'row']);
  });

  test('MUT-03: plano REMOVE nao ressuscita apos restart', () async {
    final plan = _plan(exercises: [_exercise('bench'), _exercise('row')]);
    await StorageService.salvarTreino(plan);

    final updated = await _planIntegration().removeFromPlan(
      plan: plan,
      exerciseId: 'row',
    );
    final restarted = (await StorageService.carregarTreinos()).single;

    expect(updated.exercicios.map((item) => item.id), ['bench']);
    expect(restarted.planoDias.single.exercicioIds, ['bench']);
  });

  test('MUT-04: plano REORDER preserva ordem canonica apos restart', () async {
    final plan = _plan(
      exercises: [_exercise('bench'), _exercise('row'), _exercise('press')],
    );
    await StorageService.salvarTreino(plan);

    final updated = await _planIntegration().reorderPlanExercises(
      plan: plan,
      orderedExerciseIds: const ['press', 'bench', 'row'],
    );
    final restarted = (await StorageService.carregarTreinos()).single;

    expect(updated.exercicios.map((item) => item.id), [
      'press',
      'bench',
      'row',
    ]);
    expect(
      restarted
          .somenteDia(restarted.planoDias.single)
          .exercicios
          .map((item) => item.id),
      ['press', 'bench', 'row'],
    );
  });

  test('MUT-05: sessao ADD sobrevive a recovery sem nova sessao', () async {
    final store = _MemoryStore();
    final transport = _MutableTransport(online: false);
    var controller = await _controller(store, transport, _plan());
    final session = await controller.startWorkout(plan: _plan());
    final workout = controller.workoutForSession(session!)!;

    await controller.updateWorkoutExercises(
      sessionId: session.id,
      exercises: [...workout.exercicios, _exercise('fly')],
      change: 'add',
      exerciseId: 'fly',
    );
    controller.dispose();
    controller = await _controller(store, transport, _plan());
    addTearDown(controller.dispose);

    expect(controller.activeSession?.id, session.id);
    expect(
      controller
          .workoutForSession(controller.activeSession!)!
          .exercicios
          .last
          .id,
      'fly',
    );
  });

  test(
    'MUT-06: sessao REPLACE preserva sets do original no historico',
    () async {
      final store = _MemoryStore();
      final transport = _MutableTransport(online: false);
      final plan = _plan();
      final controller = await _controller(store, transport, plan);
      addTearDown(controller.dispose);
      final session = await controller.startWorkout(plan: plan);
      final original = controller.workoutForSession(session!)!.exercicios.first;
      await controller.completeSet(
        sessionId: session.id,
        exercise: original,
        weight: 50,
        reps: 10,
      );
      final workout = controller.workoutForSession(session)!;
      await controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: [_exercise('incline'), ...workout.exercicios.skip(1)],
        change: 'replace',
        previousExerciseId: original.id,
        exerciseId: 'incline',
      );
      final replacement = _currentWorkout(
        controller,
        session.id,
      ).exercicios.first;
      await controller.completeSet(
        sessionId: session.id,
        exercise: replacement,
        weight: 70,
        reps: 5,
      );
      await controller.finishWorkout(session.id);

      final history = WorkoutHistoryRepository(
        localStore: store,
      ).project(store.snapshot);
      final exercises = history.workouts.single.exercises;
      expect(
        exercises.map((item) => item.exerciseId),
        containsAll(['bench', 'incline']),
      );
      expect(
        exercises.singleWhere((item) => item.exerciseId == 'bench').volume,
        500,
      );
      expect(
        exercises.singleWhere((item) => item.exerciseId == 'incline').volume,
        350,
      );
    },
  );

  test(
    'MUT-07: sessao REMOVE preserva series e recusa remover exercicio concluido',
    () async {
      final store = _MemoryStore();
      final transport = _MutableTransport(online: false);
      final plan = _plan();
      final controller = await _controller(store, transport, plan);
      addTearDown(controller.dispose);
      final session = await controller.startWorkout(plan: plan);
      final workout = controller.workoutForSession(session!)!;

      final removed = await controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: [workout.exercicios.first],
        change: 'remove',
        previousExerciseId: 'row',
      );
      expect(removed?.exercicios.single.id, 'bench');

      await controller.completeSet(
        sessionId: session.id,
        exercise: removed!.exercicios.single,
        weight: 40,
        reps: 8,
      );
      final refused = await controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: [_exercise('row')],
        change: 'remove',
        previousExerciseId: 'bench',
      );

      expect(refused, isNull);
      expect(controller.setsFor(session.id).single.exerciseId, 'bench');
      expect(
        _currentWorkout(controller, session.id).exercicios.single.id,
        'bench',
      );
    },
  );

  test(
    'MUT-08: sessao REORDER mantem IDs de sessao e serie estaveis',
    () async {
      final store = _MemoryStore();
      final transport = _MutableTransport(online: false);
      final plan = _plan(
        exercises: [_exercise('bench'), _exercise('row'), _exercise('press')],
      );
      var controller = await _controller(store, transport, plan);
      final session = await controller.startWorkout(plan: plan);
      final workout = controller.workoutForSession(session!)!;
      final set = await controller.completeSet(
        sessionId: session.id,
        exercise: workout.exercicios.first,
        weight: 40,
        reps: 10,
      );
      await controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: [
          workout.exercicios.first,
          workout.exercicios.last,
          workout.exercicios[1],
        ],
        change: 'reorder',
      );
      controller.dispose();
      controller = await _controller(store, transport, plan);
      addTearDown(controller.dispose);

      expect(controller.activeSession?.id, session.id);
      expect(controller.setsFor(session.id).single.id, set!.set.id);
      expect(
        controller
            .workoutForSession(controller.activeSession!)!
            .exercicios
            .map((item) => item.id),
        ['bench', 'press', 'row'],
      );
    },
  );

  test('MUT-09: offline ADD recebe ACK sem duplicar', () async {
    final result = await _offlineMutation(change: 'add');
    expect(result.exercises, ['bench', 'row', 'fly']);
    expect(result.transport.events, hasLength(2));
  });

  test('MUT-10: offline REPLACE recebe ACK sem duplicar', () async {
    final result = await _offlineMutation(change: 'replace');
    expect(result.exercises, ['incline', 'row']);
    expect(result.transport.events, hasLength(2));
  });

  test('MUT-11: offline REMOVE recebe ACK sem ressuscitar exercicio', () async {
    final result = await _offlineMutation(change: 'remove');
    expect(result.exercises, ['bench']);
    expect(result.transport.events, hasLength(2));
  });

  test('MUT-12: offline REORDER recebe ACK e preserva ordem', () async {
    final result = await _offlineMutation(change: 'reorder');
    expect(result.exercises, ['row', 'bench']);
    expect(result.transport.events, hasLength(2));
  });

  test('MUT-13: double tap nao cria mutacao logica duplicada', () async {
    final store = _MemoryStore();
    final transport = _MutableTransport(online: false);
    final plan = _plan();
    final controller = await _controller(store, transport, plan);
    addTearDown(controller.dispose);
    final session = await controller.startWorkout(plan: plan);
    final initial = controller.workoutForSession(session!)!;
    final proposed = [...initial.exercicios, _exercise('fly')];

    await Future.wait([
      controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: proposed,
        change: 'add',
        exerciseId: 'fly',
      ),
      controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: proposed,
        change: 'add',
        exerciseId: 'fly',
      ),
    ]);

    expect(
      _currentWorkout(controller, session.id).exercicios.map((item) => item.id),
      ['bench', 'row', 'fly'],
    );
    expect(
      controller.snapshot.outbox.where(
        (event) => event.eventType == 'workout_exercise_changed',
      ),
      hasLength(1),
    );
  });

  test('MUT-14: USER_A e USER_B nao compartilham mutacoes de sessao', () async {
    final stores = <String, _MemoryStore>{};
    final transport = _MutableTransport(online: false);
    final plan = _plan();
    var controller = await _controller(
      stores.putIfAbsent('user-a', _MemoryStore.new),
      transport,
      plan,
      userId: 'user-a',
    );
    final session = await controller.startWorkout(plan: plan);
    final workout = controller.workoutForSession(session!)!;
    await controller.updateWorkoutExercises(
      sessionId: session.id,
      exercises: [...workout.exercicios, _exercise('fly')],
      change: 'add',
      exerciseId: 'fly',
    );
    controller.dispose();

    controller = await _controller(
      stores.putIfAbsent('user-b', _MemoryStore.new),
      transport,
      plan,
      userId: 'user-b',
    );
    addTearDown(controller.dispose);
    expect(controller.activeSession, isNull);
  });

  test(
    'MUT-15: finalizar apos mutacao atribui volume e PR ao exerciseId correto',
    () async {
      final store = _MemoryStore();
      final transport = _MutableTransport(online: false);
      final plan = _plan();
      final controller = await _controller(store, transport, plan);
      addTearDown(controller.dispose);
      final session = await controller.startWorkout(plan: plan);
      final original = controller.workoutForSession(session!)!.exercicios.first;
      await controller.completeSet(
        sessionId: session.id,
        exercise: original,
        weight: 60,
        reps: 8,
      );
      final workout = controller.workoutForSession(session)!;
      await controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: [_exercise('incline'), ...workout.exercicios.skip(1)],
        change: 'replace',
        previousExerciseId: 'bench',
        exerciseId: 'incline',
      );
      final replacement = _currentWorkout(
        controller,
        session.id,
      ).exercicios.first;
      await controller.completeSet(
        sessionId: session.id,
        exercise: replacement,
        weight: 80,
        reps: 4,
      );
      await controller.finishWorkout(session.id);

      final history = WorkoutHistoryRepository(
        localStore: store,
      ).project(store.snapshot);
      final records = history.exercisePrs;
      expect(
        records.singleWhere((item) => item.exerciseId == 'bench').maxVolume,
        480,
      );
      expect(
        records.singleWhere((item) => item.exerciseId == 'incline').maxVolume,
        320,
      );
      expect(history.workouts.single.metrics.totalVolume, 800);
    },
  );
}

ExercisePlanIntegration _planIntegration() => ExercisePlanIntegration(
  loadPlans: StorageService.carregarTreinos,
  savePlan: StorageService.salvarTreino,
);

Future<CoreJourneyController> _controller(
  _MemoryStore store,
  _MutableTransport transport,
  TreinoModel plan, {
  String userId = 'mutation-user',
}) async {
  final controller = CoreJourneyController(
    identityResolver: () async => CoreJourneyIdentity(
      userId: userId,
      name: userId,
      isAuthenticated: true,
    ),
    planLoader: () async => [plan],
    repositoryFactory: (_) async =>
        WorkoutVerticalRepository(localStore: store, transport: transport),
  );
  await controller.initialize();
  return controller;
}

TreinoModel _currentWorkout(
  CoreJourneyController controller,
  String sessionId,
) {
  final session = controller.sessionById(sessionId);
  if (session == null) throw StateError('Sessao de teste nao encontrada.');
  final workout = controller.workoutForSession(session);
  if (workout == null) throw StateError('Treino de teste nao encontrado.');
  return workout;
}

Future<_OfflineMutationResult> _offlineMutation({
  required String change,
}) async {
  final store = _MemoryStore();
  final transport = _MutableTransport(online: false);
  final repository = WorkoutVerticalRepository(
    localStore: store,
    transport: transport,
  );
  final initial = _plan();
  final session = await repository.startOrRecover(
    planId: initial.id,
    workoutId: initial.id,
    workoutSnapshot: initial.toJson(),
  );
  late final List<ExercicioModel> next;
  late final String? previous;
  late final String? exerciseId;
  switch (change) {
    case 'add':
      next = [...initial.exercicios, _exercise('fly')];
      previous = null;
      exerciseId = 'fly';
      break;
    case 'replace':
      next = [_exercise('incline'), initial.exercicios.last];
      previous = 'bench';
      exerciseId = 'incline';
      break;
    case 'remove':
      next = [initial.exercicios.first];
      previous = 'row';
      exerciseId = null;
      break;
    case 'reorder':
      next = initial.exercicios.reversed.toList(growable: false);
      previous = null;
      exerciseId = null;
      break;
    default:
      throw ArgumentError.value(change, 'change');
  }
  final updated = TreinoModel.fromJson({
    ...initial.toJson(),
    'exercicios': next.map((item) => item.toJson()).toList(),
  });
  await repository.updateWorkoutSnapshot(
    sessionId: session.id,
    workoutSnapshot: updated.toJson(),
    change: change,
    previousExerciseId: previous,
    exerciseId: exerciseId,
  );
  expect((await repository.load()).outbox, hasLength(2));

  transport.online = true;
  await repository.retryNow();
  await repository.flushOutbox();
  final persisted = await repository.load();
  final finalWorkout = TreinoModel.fromJson(
    persisted.sessions.single.workoutSnapshot!,
  );
  expect(persisted.outbox, isEmpty);
  return _OfflineMutationResult(
    exercises: finalWorkout.exercicios.map((item) => item.id).toList(),
    transport: transport,
  );
}

TreinoModel _plan({
  String id = 'mutation-plan',
  List<ExercicioModel>? exercises,
}) {
  final resolved = exercises ?? [_exercise('bench'), _exercise('row')];
  return TreinoModel(
    id: id,
    nome: 'Mutation plan',
    descricao: '',
    objetivo: 'Forca',
    nivel: 'Intermediario',
    tempoEstimado: 45,
    diasPorSemana: 1,
    planoDias: [
      TreinoDiaModel(
        codigo: 'A',
        nome: 'Principal',
        ordem: 1,
        exercicioIds: resolved.map((item) => item.id).toList(),
      ),
    ],
    criadoPorIA: false,
    exercicios: resolved,
    dataCriacao: '2026-08-27T00:00:00.000Z',
  );
}

ExercicioModel _exercise(String id) => ExercicioModel(
  id: id,
  nome: id,
  categoria: 'Peito',
  descricao: '',
  comoExecutar: '',
  cuidados: '',
  musculos: const ['Peito'],
  equipamentos: const ['Barra'],
  locais: const ['Academia'],
  dificuldade: 'Intermediario',
  objetivo: 'Forca',
  imagem: '',
  video: '',
  tags: const [],
  caloriasHora: 0,
  series: 2,
  repeticoes: '8',
  descansoSegundos: 60,
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

class _MutableTransport implements WorkoutVerticalSyncTransport {
  _MutableTransport({required this.online});

  bool online;
  final List<OutboxEventLocal> events = [];

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    if (!online) {
      throw const WorkoutSyncTransportException('Offline', retryable: true);
    }
    events.add(event);
    return const SyncDispatchResult.confirmed();
  }
}

class _OfflineMutationResult {
  const _OfflineMutationResult({
    required this.exercises,
    required this.transport,
  });

  final List<String> exercises;
  final _MutableTransport transport;
}
