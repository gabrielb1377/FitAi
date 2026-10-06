import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/plans/domain/workout_strength_metrics.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/exercise_history_model.dart';
import 'package:fitai/models/historico_serie_treino_model.dart';
import 'package:fitai/services/exercise_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fitai/features/plans/workout_execution/widgets/workout_history_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FITAI-11 canonical strength data', () {
    test('STR-VOL-01/03: volume is deterministic and rejects invalid sets', () {
      expect(WorkoutStrengthMetrics.setVolume(70, 10), 700);
      expect(WorkoutStrengthMetrics.setVolume(0, 10), 0);
      expect(WorkoutStrengthMetrics.setVolume(-1, 10), 0);
      expect(WorkoutStrengthMetrics.setVolume(double.nan, 10), 0);
      expect(WorkoutStrengthMetrics.setVolume(70, 0), 0);
    });

    test(
      'RPE is optional but validated in the canonical persistence boundary',
      () async {
        final store = _SnapshotStore(const WorkoutSliceSnapshot.empty());
        final repository = WorkoutVerticalRepository(
          localStore: store,
          transport: const _OfflineTransport(),
        );
        final session = await repository.startOrRecover(
          planId: 'plan',
          workoutId: 'workout',
        );

        await expectLater(
          repository.registerSet(
            sessionId: session.id,
            exerciseId: 'exercise',
            setIndex: 0,
            weight: 50,
            reps: 8,
            rpe: 11,
          ),
          throwsArgumentError,
        );
        final registered = await repository.registerSet(
          sessionId: session.id,
          exerciseId: 'exercise',
          setIndex: 0,
          weight: 50,
          reps: 8,
          rpe: 8,
        );

        expect(registered.set.rpe, 8);
        expect((await store.read()).sets.single.rpe, 8);
      },
    );

    test(
      'STR-PREV-01/02/05/06: last completed canonical execution wins',
      () async {
        final snapshot = _history().project(
          WorkoutSliceSnapshot(
            sessions: [
              _session(
                'old',
                DateTime.utc(2026, 9, 1),
                WorkoutSessionStatus.completed,
              ),
              _session(
                'latest',
                DateTime.utc(2026, 9, 8),
                WorkoutSessionStatus.completed,
              ),
              _session(
                'open',
                DateTime.utc(2026, 9, 9),
                WorkoutSessionStatus.active,
              ),
              _session(
                'discarded',
                DateTime.utc(2026, 9, 10),
                WorkoutSessionStatus.discarded,
              ),
            ],
            sets: [
              _set('old-0', 'old', index: 0, weight: 60, reps: 10),
              _set('old-1', 'old', index: 1, weight: 60, reps: 8),
              _set('latest-0', 'latest', index: 0, weight: 65, reps: 10),
              _set('latest-1', 'latest', index: 1, weight: 65, reps: 8),
              _set('open-0', 'open', index: 0, weight: 90, reps: 20),
              _set('discarded-0', 'discarded', index: 0, weight: 100, reps: 20),
            ],
            outbox: const [],
            schemaVersion: 1,
          ),
        );
        final service = ExerciseHistoryService(
          historyLoader: () async => snapshot,
        );

        final result = await service.loadExerciseHistory(_exercise());

        expect(result.executions, hasLength(2));
        expect(result.stats.latestExecution?.id, 'latest');
        expect(result.stats.latestExecution?.sets, hasLength(2));
        expect(result.stats.latestExecution?.sets.first.peso, 65.0);
      },
    );

    test('STR-PREV-03: history source keeps account scopes isolated', () async {
      SharedPreferences.setMockInitialValues({});
      final storeA = _SnapshotStore(
        WorkoutSliceSnapshot(
          sessions: [
            _session(
              'a-session',
              DateTime.utc(2026, 9, 1),
              WorkoutSessionStatus.completed,
            ),
          ],
          sets: [_set('a-set', 'a-session', index: 0, weight: 70, reps: 10)],
          outbox: const [],
          schemaVersion: 1,
        ),
      );
      final storeB = _SnapshotStore(const WorkoutSliceSnapshot.empty());
      final historyA = _history(storeA).load();
      final historyB = _history(storeB).load();
      final userA = ExerciseHistoryService(historyLoader: () async => historyA);
      final userB = ExerciseHistoryService(historyLoader: () async => historyB);

      expect(
        (await userA.loadExerciseHistory(_exercise())).executions,
        hasLength(1),
      );
      expect(
        (await userB.loadExerciseHistory(_exercise())).executions,
        isEmpty,
      );
    });

    test(
      'STR-PREV-04: completed performance survives journal recreation',
      () async {
        final persisted = WorkoutSliceSnapshot(
          sessions: [
            _session(
              'persisted-session',
              DateTime.utc(2026, 9, 1),
              WorkoutSessionStatus.completed,
            ),
          ],
          sets: [
            _set(
              'persisted-set-0',
              'persisted-session',
              index: 0,
              weight: 65,
              reps: 10,
            ),
            _set(
              'persisted-set-1',
              'persisted-session',
              index: 1,
              weight: 65,
              reps: 8,
            ),
          ],
          outbox: const [],
          schemaVersion: 1,
        );
        final firstStore = _SnapshotStore(persisted);
        final firstRead = await _history(firstStore).load();
        final reopenedStore = _SnapshotStore(
          WorkoutSliceSnapshot.fromJson((await firstStore.read()).toJson()),
        );
        final afterRestart = await ExerciseHistoryService(
          historyLoader: () async => _history(reopenedStore).load(),
        ).loadExerciseHistory(_exercise());

        expect(firstRead.workouts.single.id, 'persisted-session');
        expect(afterRestart.stats.latestExecution?.id, 'persisted-session');
        expect(afterRestart.stats.latestExecution?.sets, hasLength(2));
        expect(afterRestart.stats.latestExecution?.sets.first.peso, 65.0);
      },
    );

    testWidgets('previous performance is visible while the session is active', (
      tester,
    ) async {
      final prior = ExerciseExecution(
        id: 'prior-session',
        exerciseId: 'exercise-canonical',
        exerciseKey: 'id:exercise-canonical',
        exerciseName: 'Supino reto',
        workoutId: 'workout',
        workoutName: 'Upper A',
        date: DateTime(2026, 9, 1),
        sets: [
          _legacySet('prior-set-0', 1, 65, 10),
          _legacySet('prior-set-1', 2, 65, 8),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkoutExerciseHistoryPanel(
                exercise: _exercise(),
                history: Future.value(
                  ExerciseHistorySnapshot(
                    executions: [prior],
                    stats: const ExerciseHistoryStats(
                      totalSessions: 1,
                      latestExecution: null,
                      bestLoadSet: null,
                      highestVolumeExecution: null,
                      estimatedOneRepMax: 0,
                    ),
                  ),
                ),
                currentSessionId: 'current-session',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Performance anterior'), findsOneWidget);
      expect(find.text('65 kg × 10 reps'), findsOneWidget);
      expect(find.text('65 kg × 8 reps'), findsOneWidget);
    });

    test('STR-PR-01/04/05/07: PR projection is stable and 1RM is bounded', () {
      final source = WorkoutSliceSnapshot(
        sessions: [
          _session(
            'pr-session',
            DateTime.utc(2026, 9, 1),
            WorkoutSessionStatus.completed,
          ),
        ],
        sets: [
          _set('set-12', 'pr-session', index: 0, weight: 70, reps: 12),
          _set('set-10', 'pr-session', index: 1, weight: 60, reps: 10),
        ],
        outbox: const [],
        schemaVersion: 1,
      );
      final repository = _history();

      final first = repository.project(source);
      final repeated = repository.project(source);

      expect(
        first.personalRecords.map((record) => record.id).toSet(),
        repeated.personalRecords.map((record) => record.id).toSet(),
      );
      expect(first.workouts.single.metrics.totalVolume, 1440);
      expect(
        first.personalRecords
            .where(
              (record) => record.type == PersonalRecordType.estimatedOneRepMax,
            )
            .single
            .value,
        closeTo(80, 0.001),
      );
    });

    test(
      'STR-VOL-02/06: summary compares only matching plan and exercise set',
      () {
        final source = WorkoutSliceSnapshot(
          sessions: [
            _session(
              'baseline',
              DateTime.utc(2026, 9, 1),
              WorkoutSessionStatus.completed,
            ),
            _session(
              'current',
              DateTime.utc(2026, 9, 8),
              WorkoutSessionStatus.completed,
            ),
          ],
          sets: [
            _set('baseline-set', 'baseline', index: 0, weight: 50, reps: 10),
            _set('current-set', 'current', index: 0, weight: 60, reps: 10),
          ],
          outbox: const [],
          schemaVersion: 1,
        );

        final summary = _history().project(source).summaries.first;

        expect(summary.sessionId, 'current');
        expect(summary.metrics.totalVolume, 600);
        expect(summary.previousVolume, 500);
        expect(summary.volumeChangePercent, closeTo(20, 0.001));
        expect(summary.personalRecordCount, greaterThan(0));
      },
    );
  });
}

WorkoutHistoryRepository _history([WorkoutVerticalLocalStore? store]) =>
    WorkoutHistoryRepository(
      localStore: store ?? _SnapshotStore(const WorkoutSliceSnapshot.empty()),
    );

WorkoutSessionLocal _session(
  String id,
  DateTime date,
  WorkoutSessionStatus status,
) => WorkoutSessionLocal(
  id: id,
  planId: 'plan',
  workoutId: 'workout',
  startedAt: date,
  finishedAt: status == WorkoutSessionStatus.completed
      ? date.add(const Duration(minutes: 30))
      : null,
  status: status,
  currentExerciseIndex: 0,
  currentSetIndex: 0,
  updatedAt: date,
  syncStatus: WorkoutSyncStatus.local,
  version: 1,
);

WorkoutSetLocal _set(
  String id,
  String sessionId, {
  required int index,
  required double weight,
  required int reps,
}) => WorkoutSetLocal(
  id: id,
  sessionId: sessionId,
  exerciseId: 'plan-exercise-occurrence',
  canonicalExerciseId: 'exercise-canonical',
  exerciseName: 'Supino reto',
  setIndex: index,
  weight: weight,
  reps: reps,
  completedAt: DateTime.utc(2026, 9, 1, 10).add(Duration(minutes: index)),
  updatedAt: DateTime.utc(2026, 9, 1, 10).add(Duration(minutes: index)),
  syncStatus: WorkoutSyncStatus.local,
  version: 1,
);

ExercicioModel _exercise() => ExercicioModel.fromJson({
  'id': 'plan-exercise-occurrence',
  'canonicalExerciseId': 'exercise-canonical',
  'nome': 'Supino reto',
});

HistoricoSerieTreinoModel _legacySet(
  String id,
  int number,
  double weight,
  int reps,
) => HistoricoSerieTreinoModel(
  id: id,
  treinoId: 'workout',
  sessaoTreinoId: 'prior-session',
  nomeTreino: 'Upper A',
  exercicioId: 'exercise-canonical',
  exerciseKey: 'id:exercise-canonical',
  nomeExercicio: 'Supino reto',
  serieNumero: number,
  peso: weight,
  repeticoes: reps,
  dataHora: DateTime(2026, 9, 1, 10, number),
);

class _SnapshotStore implements WorkoutVerticalLocalStore {
  _SnapshotStore(this.snapshot);

  WorkoutSliceSnapshot snapshot;

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
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async =>
      const SyncDispatchResult.confirmed();
}
