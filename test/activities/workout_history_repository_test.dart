import 'package:fitai/features/activities/data/workout_history_repository.dart';
import 'package:fitai/features/activities/domain/activity_history_models.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutHistoryRepository', () {
    test(
      'projeta sessoes concluidas com metricas e detalhes executados',
      () async {
        final store = _MemoryStore();
        final clock = _TestClock(DateTime.utc(2026, 8, 1, 9));
        final workouts = WorkoutVerticalRepository(
          localStore: store,
          transport: const _OfflineTransport(),
          clock: clock.call,
        );
        final session = await workouts.startOrRecover(
          planId: 'plan-upper',
          workoutId: 'upper-a',
          planName: 'Plano Upper',
          workoutName: 'Upper A',
        );
        await workouts.registerSet(
          sessionId: session.id,
          exerciseId: 'supino-reto',
          exerciseName: 'Supino reto',
          setIndex: 0,
          weight: 55,
          reps: 10,
          rpe: 8,
          notes: 'Controle na descida',
          restDuration: const Duration(seconds: 60),
        );
        clock.advance(const Duration(minutes: 1));
        await workouts.registerSet(
          sessionId: session.id,
          exerciseId: 'supino-reto',
          exerciseName: 'Supino reto',
          setIndex: 1,
          weight: 60,
          reps: 8,
          rpe: 9,
          restDuration: const Duration(seconds: 75),
        );
        clock.advance(const Duration(minutes: 44));
        await workouts.finish(session.id);

        final history = await WorkoutHistoryRepository(
          localStore: store,
          clock: clock.call,
        ).load();

        expect(history.workouts, hasLength(1));
        final workout = history.workouts.single;
        expect(workout.planId, 'plan-upper');
        expect(workout.workoutName, 'Upper A');
        expect(workout.metrics.durationSeconds, 45 * 60);
        expect(workout.metrics.totalVolume, 1030);
        expect(workout.metrics.totalLoad, 115);
        expect(workout.metrics.setCount, 2);
        expect(workout.metrics.totalRepetitions, 18);
        expect(workout.syncStatus, WorkoutSyncStatus.pending);
        expect(workout.exercises.single.name, 'Supino reto');
        expect(workout.exercises.single.sets.first.restSeconds, 60);
        expect(workout.exercises.single.sets.first.rpe, 8);
        expect(
          workout.exercises.single.sets.first.notes,
          'Controle na descida',
        );
      },
    );

    test(
      'recria historico local offline sem depender da rede ou duplicar series',
      () async {
        final store = _MemoryStore();
        final clock = _TestClock(DateTime.utc(2026, 8, 2, 10));
        final writer = WorkoutVerticalRepository(
          localStore: store,
          transport: const _OfflineTransport(),
          clock: clock.call,
        );
        final session = await writer.startOrRecover(
          planId: 'plan-a',
          workoutId: 'workout-a',
        );
        await writer.registerSet(
          sessionId: session.id,
          exerciseId: 'agachamento-livre',
          setIndex: 0,
          weight: 80,
          reps: 6,
        );
        await writer.registerSet(
          sessionId: session.id,
          exerciseId: 'agachamento-livre',
          setIndex: 0,
          weight: 80,
          reps: 6,
        );
        clock.advance(const Duration(minutes: 30));
        await writer.finish(session.id);

        final recreatedReader = WorkoutHistoryRepository(
          localStore: store,
          exerciseNameResolver: (id) =>
              id == 'agachamento-livre' ? 'Agachamento livre' : null,
          clock: clock.call,
        );
        final history = await recreatedReader.load();

        expect(history.workouts, hasLength(1));
        expect(history.workouts.single.exercises.single.sets, hasLength(1));
        expect(
          history.workouts.single.exercises.single.name,
          'Agachamento livre',
        );
        expect(history.workouts.single.syncStatus, WorkoutSyncStatus.pending);
      },
    );

    test('calcula PRs, calendario, timeline, troca de plano e sequencia', () {
      final history =
          WorkoutHistoryRepository(
            localStore: _MemoryStore(),
            clock: () => DateTime.utc(2026, 8, 3, 20),
          ).project(
            WorkoutSliceSnapshot(
              sessions: [
                _session(
                  id: 'session-1',
                  planId: 'plan-a',
                  startedAt: DateTime.utc(2026, 8, 1, 9),
                  finishedAt: DateTime.utc(2026, 8, 1, 10),
                ),
                _session(
                  id: 'session-2',
                  planId: 'plan-a',
                  startedAt: DateTime.utc(2026, 8, 2, 9),
                  finishedAt: DateTime.utc(2026, 8, 2, 10),
                ),
                _session(
                  id: 'session-3',
                  planId: 'plan-b',
                  startedAt: DateTime.utc(2026, 8, 3, 9),
                  finishedAt: DateTime.utc(2026, 8, 3, 10),
                ),
              ],
              sets: [
                _set(
                  'set-1',
                  'session-1',
                  50,
                  8,
                  completedAt: DateTime.utc(2026, 8, 1, 10),
                ),
                _set(
                  'set-2',
                  'session-2',
                  55,
                  8,
                  completedAt: DateTime.utc(2026, 8, 2, 10),
                ),
                _set(
                  'set-3',
                  'session-3',
                  60,
                  8,
                  completedAt: DateTime.utc(2026, 8, 3, 10),
                ),
              ],
              outbox: const [],
              schemaVersion: 1,
            ),
          );

      expect(history.personalRecords, hasLength(9));
      expect(history.exercisePrs.single.maxLoad, 60);
      expect(history.calendar, hasLength(3));
      expect(history.calendar.first.personalRecordCount, 3);
      expect(history.streak.currentDays, 3);
      expect(history.streak.longestDays, 3);
      expect(
        history.timeline.where(
          (event) => event.type == TimelineEventType.firstWorkout,
        ),
        hasLength(1),
      );
      expect(
        history.timeline.where(
          (event) => event.type == TimelineEventType.planChanged,
        ),
        hasLength(1),
      );
      expect(
        history.timeline.where(
          (event) => event.type == TimelineEventType.streak,
        ),
        hasLength(1),
      );
    });

    test(
      'ignora sessoes abertas ou descartadas e preserva campos antigos ausentes',
      () {
        final completed = _session(
          id: 'completed',
          planId: 'plan-a',
          startedAt: DateTime.utc(2026, 8, 1, 8),
          finishedAt: DateTime.utc(2026, 8, 1, 9),
        );
        final active = completed.copyWith(
          status: WorkoutSessionStatus.active,
          finishedAt: null,
        );
        final discarded = completed.copyWith(
          status: WorkoutSessionStatus.discarded,
        );
      final legacySession = completed.toJson()
        ..remove('planName')
        ..remove('workoutName')
        ..remove('calories');
      final legacySet = _set('set-1', 'completed', 50, 10).toJson()
        ..remove('exerciseName')
        ..remove('restSeconds')
        ..remove('rpe')
        ..remove('notes');
      final snapshot = WorkoutSliceSnapshot.fromJson({
        'schemaVersion': 1,
        'sessions': [legacySession, active.toJson(), discarded.toJson()],
        'sets': [legacySet],
          'outbox': const [],
        });

        final history = WorkoutHistoryRepository(
          localStore: _MemoryStore(),
        ).project(snapshot);

        expect(history.workouts, hasLength(1));
        expect(history.workouts.single.id, 'completed');
        expect(
          history.workouts.single.exercises.single.sets.single.restSeconds,
          isNull,
        );
        expect(
          history.workouts.single.exercises.single.sets.single.rpe,
          isNull,
        );
      },
    );
  });
}

WorkoutSessionLocal _session({
  required String id,
  required String planId,
  required DateTime startedAt,
  required DateTime finishedAt,
}) => WorkoutSessionLocal(
  id: id,
  planId: planId,
  workoutId: 'upper-a',
  planName: planId,
  workoutName: 'Upper A',
  startedAt: startedAt,
  finishedAt: finishedAt,
  status: WorkoutSessionStatus.completed,
  currentExerciseIndex: 0,
  currentSetIndex: 0,
  updatedAt: finishedAt,
  syncStatus: WorkoutSyncStatus.synced,
  version: 1,
);

WorkoutSetLocal _set(
  String id,
  String sessionId,
  double weight,
  int repetitions, {
  DateTime? completedAt,
}) => WorkoutSetLocal(
  id: id,
  sessionId: sessionId,
  exerciseId: 'supino-reto',
  exerciseName: 'Supino reto',
  setIndex: 0,
  weight: weight,
  reps: repetitions,
  completedAt: completedAt ?? DateTime.utc(2026, 8, 1, 10),
  updatedAt: completedAt ?? DateTime.utc(2026, 8, 1, 10),
  syncStatus: WorkoutSyncStatus.synced,
  version: 1,
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

class _TestClock {
  _TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}

class _OfflineTransport implements WorkoutVerticalSyncTransport {
  const _OfflineTransport();

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) {
    throw const WorkoutSyncTransportException('Sem conexao.', retryable: true);
  }
}
