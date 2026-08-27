import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R1.2 unified workout path', () {
    late _ScopedStore stores;
    late CoreJourneyController controller;

    setUp(() async {
      stores = _ScopedStore();
      controller = _controller(stores, 'user-a');
      await controller.initialize();
    });

    tearDown(() => controller.dispose());

    test('duplo start cria uma sessao e recupera a mesma identidade', () async {
      final plan = DevFixtures.workouts.single;
      final sessions = await Future.wait([
        controller.startWorkout(plan: plan),
        controller.startWorkout(plan: plan),
      ]);

      expect(sessions[0]?.id, sessions[1]?.id);
      expect(
        controller.snapshot.sessions.where((item) => item.isOpen),
        hasLength(1),
      );
      expect(
        controller.snapshot.outbox.where(
          (event) => event.eventType == 'workout_session_started',
        ),
        hasLength(1),
      );
      expect(
        controller.workoutForSession(sessions.first!)?.exercicios,
        isNotEmpty,
      );
    });

    test(
      'duplo completeSet mantém um setId e uma mensagem de outbox',
      () async {
        final plan = DevFixtures.workouts.single;
        final session = await controller.startWorkout(plan: plan);
        final exercise = controller
            .workoutForSession(session!)!
            .exercicios
            .first;

        final results = await Future.wait([
          controller.completeSet(
            sessionId: session.id,
            exercise: exercise,
            weight: 55,
            reps: 10,
          ),
          controller.completeSet(
            sessionId: session.id,
            exercise: exercise,
            weight: 55,
            reps: 10,
          ),
        ]);

        expect(results.every((result) => result != null), isTrue);
        expect(results[0]!.set.id, results[1]!.set.id);
        expect(controller.setsFor(session.id), hasLength(1));
        expect(
          controller.snapshot.outbox.where(
            (event) => event.eventType == 'workout_set_completed',
          ),
          hasLength(1),
        );
      },
    );

    test(
      'restart restaura sessao, set, exercício, descanso e outbox',
      () async {
        final plan = DevFixtures.workouts.single;
        final session = await controller.startWorkout(plan: plan);
        final workout = controller.workoutForSession(session!)!;
        await controller.completeSet(
          sessionId: session.id,
          exercise: workout.exercicios.first,
          weight: 52.5,
          reps: 9,
        );
        final beforeRestart = controller.sessionById(session.id)!;
        expect(beforeRestart.restEndsAt, isNotNull);

        controller.dispose();
        controller = _controller(stores, 'user-a');
        await controller.initialize();

        final recovered = await controller.recoverWorkout();
        expect(recovered?.id, session.id);
        expect(
          recovered?.currentExerciseIndex,
          beforeRestart.currentExerciseIndex,
        );
        expect(recovered?.currentSetIndex, beforeRestart.currentSetIndex);
        expect(recovered?.restEndsAt, beforeRestart.restEndsAt);
        expect(controller.setsFor(session.id).single.weight, 52.5);
        expect(controller.workoutForSession(recovered!)?.id, workout.id);
        expect(controller.snapshot.outbox, isNotEmpty);
      },
    );

    test(
      'troca e adicao preservam sets originais e usam a mesma sessao',
      () async {
        final plan = DevFixtures.workouts.single;
        final session = await controller.startWorkout(plan: plan);
        final workout = controller.workoutForSession(session!)!;
        final original = workout.exercicios.first;
        final replacement = ExercicioModel.fromJson({
          ...workout.exercicios.last.toJson(),
          'id': 'replacement-${workout.exercicios.last.id}',
          'nome': 'Substituicao canônica',
        });
        await controller.completeSet(
          sessionId: session.id,
          exercise: original,
          weight: 40,
          reps: 12,
        );

        final updated = await controller.updateWorkoutExercises(
          sessionId: session.id,
          exercises: [replacement, ...workout.exercicios.skip(1)],
          change: 'replace',
          previousExerciseId: original.id,
          exerciseId: replacement.id,
        );

        expect(updated, isNotNull);
        expect(controller.activeSession?.id, session.id);
        expect(controller.setsFor(session.id).single.exerciseId, original.id);
        expect(
          controller
              .workoutForSession(controller.activeSession!)!
              .exercicios
              .first
              .id,
          replacement.id,
        );
        expect(
          controller.snapshot.outbox.where(
            (event) => event.eventType == 'workout_exercise_changed',
          ),
          hasLength(1),
        );
      },
    );

    test('adicao de exercicio sobrevive ao restart sem nova sessao', () async {
      final plan = DevFixtures.workouts.single;
      final session = await controller.startWorkout(plan: plan);
      final workout = controller.workoutForSession(session!)!;
      final original = workout.exercicios.first;
      final added = ExercicioModel.fromJson({
        ...original.toJson(),
        'id': 'library-added-exercise',
        'nome': 'Exercicio adicionado pela Biblioteca',
      });
      await controller.completeSet(
        sessionId: session.id,
        exercise: original,
        weight: 30,
        reps: 12,
      );

      await controller.updateWorkoutExercises(
        sessionId: session.id,
        exercises: [...workout.exercicios, added],
        change: 'add',
        exerciseId: added.id,
      );
      controller.dispose();
      controller = _controller(stores, 'user-a');
      await controller.initialize();

      final recovered = controller.activeSession!;
      expect(recovered.id, session.id);
      expect(
        controller.workoutForSession(recovered)!.exercicios.last.id,
        added.id,
      );
      expect(controller.setsFor(session.id).single.exerciseId, original.id);
      expect(
        controller.snapshot.outbox.where(
          (event) => event.eventType == 'workout_exercise_changed',
        ),
        hasLength(1),
      );
    });

    test(
      'cancelamento descarta a sessao sem apagar sets persistidos',
      () async {
        final plan = DevFixtures.workouts.single;
        final session = await controller.startWorkout(plan: plan);
        final exercise = controller
            .workoutForSession(session!)!
            .exercicios
            .first;
        final completed = await controller.completeSet(
          sessionId: session.id,
          exercise: exercise,
          weight: 35,
          reps: 10,
        );

        await controller.cancelWorkout(session.id);
        controller.dispose();
        controller = _controller(stores, 'user-a');
        await controller.initialize();

        expect(controller.activeSession, isNull);
        expect(
          controller.sessionById(session.id)?.status,
          WorkoutSessionStatus.discarded,
        );
        expect(controller.setsFor(session.id).single.id, completed!.set.id);
        expect(
          controller.snapshot.outbox.where(
            (event) => event.eventType == 'workout_session_discarded',
          ),
          hasLength(1),
        );
      },
    );

    test('finalização repetida permanece local, única e recuperável', () async {
      final session = await controller.startPlan(DevFixtures.workouts.single);
      await Future.wait([
        controller.finishWorkout(session!.id),
        controller.finishWorkout(session.id),
      ]);

      expect(controller.activeSession, isNull);
      expect(
        controller.completedSessions.where((item) => item.id == session.id),
        hasLength(1),
      );
      expect(
        controller.snapshot.outbox.where(
          (event) => event.eventType == 'workout_session_finished',
        ),
        hasLength(1),
      );

      controller.dispose();
      controller = _controller(stores, 'user-a');
      await controller.initialize();
      expect(await controller.recoverWorkout(), isNull);
      expect(
        controller.sessionById(session.id)?.status,
        WorkoutSessionStatus.completed,
      );
    });

    test('logout e login não expõem sessão de outro owner', () async {
      final session = await controller.startPlan(DevFixtures.workouts.single);
      controller.dispose();
      controller = _controller(stores, 'user-b');
      await controller.initialize();

      expect(controller.activeSession, isNull);
      expect(controller.sessionById(session!.id), isNull);

      controller.dispose();
      controller = _controller(stores, 'user-a');
      await controller.initialize();
      expect(controller.activeSession?.id, session.id);
    });
  });
}

CoreJourneyController _controller(_ScopedStore stores, String userId) {
  return CoreJourneyController(
    identityResolver: () async => CoreJourneyIdentity(
      userId: userId,
      name: userId,
      isAuthenticated: true,
    ),
    planLoader: () async => DevFixtures.workouts,
    repositoryFactory: (scope) async => WorkoutVerticalRepository(
      localStore: stores.forScope(scope),
      transport: const _OfflineTransport(),
    ),
  );
}

class _ScopedStore {
  final Map<String, WorkoutSliceSnapshot> snapshots = {};

  WorkoutVerticalLocalStore forScope(String scope) => _MemoryStore(
    readSnapshot: () => snapshots[scope] ?? const WorkoutSliceSnapshot.empty(),
    writeSnapshot: (value) => snapshots[scope] = value,
  );
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  const _MemoryStore({required this.readSnapshot, required this.writeSnapshot});

  final WorkoutSliceSnapshot Function() readSnapshot;
  final void Function(WorkoutSliceSnapshot value) writeSnapshot;

  @override
  Future<WorkoutSliceSnapshot> read() async => readSnapshot();

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    writeSnapshot(WorkoutSliceSnapshot.fromJson(snapshot.toJson()));
  }
}

class _OfflineTransport implements WorkoutVerticalSyncTransport {
  const _OfflineTransport();

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) {
    throw const WorkoutSyncTransportException('Offline', retryable: true);
  }
}
