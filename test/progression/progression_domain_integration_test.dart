import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_controller.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/steps_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('meta real de passos alimenta o motor uma unica vez', () async {
    final engine = _engine();
    final service = StepsService.forTesting(
      now: () => DateTime(2026, 8, 3, 12),
      progressionEngine: engine,
    );

    await service.recordManualSteps(steps: 10000);
    await service.recordManualSteps(steps: 12500);

    final events = (await engine.load()).events;
    expect(
      events.where((event) => event.sourceType == XpSourceType.stepsGoal),
      hasLength(1),
    );
  });

  test('corrida finalizada persiste antes de atualizar progressao', () async {
    var now = DateTime(2026, 8, 3, 8);
    final engine = _engine();
    final service = RunningSessionService.forTesting(
      clock: () => now,
      progressionEngine: engine,
    );

    await service.start();
    now = now.add(const Duration(seconds: 60));
    final run = await service.finish();

    expect(run, isNotNull);
    expect(
      (await engine.load()).events.where(
        (event) => event.sourceType == XpSourceType.running,
      ),
      hasLength(1),
    );
  });

  test(
    'vertical slice concluido atualiza o motor sem bloquear a sessao',
    () async {
      final engine = _engine();
      final transport = DebugWorkoutSyncTransport();
      final controller = WorkoutVerticalSliceController(
        repository: WorkoutVerticalRepository(
          localStore: _MemoryWorkoutStore(),
          transport: transport,
          clock: () => DateTime(2026, 8, 3, 9),
        ),
        debugTransport: transport,
        clock: () => DateTime(2026, 8, 3, 9),
        progressionEngine: engine,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.startExampleWorkout();
      await controller.registerSet(weight: 55, reps: 10);
      await controller.finishWorkout();

      expect(
        controller.snapshot.sessions.last.status,
        WorkoutSessionStatus.completed,
      );
      expect(
        (await engine.load()).events.where(
          (event) => event.sourceType == XpSourceType.workout,
        ),
        hasLength(1),
      );
    },
  );
}

ProgressionEngine _engine() => ProgressionEngine(
  store: InMemoryProgressionStore(),
  legacyReader: () async => const LegacyProgression(level: 1, xpIntoLevel: 0),
  legacyWriter: (_) async {},
  clock: () => DateTime(2026, 8, 3, 12),
);

class _MemoryWorkoutStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    snapshot = value;
  }
}
