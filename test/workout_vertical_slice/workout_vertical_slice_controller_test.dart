import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'clock nao notifica sem descanso e notifica apenas ao mudar segundo',
    () async {
      final clock = _TestClock(DateTime.utc(2026, 7, 31, 10));
      final controller = _controller(clock: clock);
      addTearDown(controller.dispose);
      await controller.initialize();

      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.refreshClock();
      expect(notifications, 0);

      await controller.startExampleWorkout();
      await controller.registerSet(weight: 55, reps: 10);
      notifications = 0;
      controller.refreshClock();
      controller.refreshClock();
      expect(notifications, 1);

      clock.advance(const Duration(seconds: 1));
      controller.refreshClock();
      expect(notifications, 2);
    },
  );

  test(
    'erro de recuperacao nao expoe detalhe tecnico do armazenamento',
    () async {
      final controller = WorkoutVerticalSliceController(
        repository: WorkoutVerticalRepository(
          localStore: _FailingStore(),
          transport: DebugWorkoutSyncTransport(),
        ),
        debugTransport: DebugWorkoutSyncTransport(),
      );
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.errorMessage, isNot(contains('secret-storage-value')));
    },
  );

  test('dispose encerra recursos de sincronizacao do slice', () async {
    final transport = _DisposableTransport();
    final controller = WorkoutVerticalSliceController(
      repository: WorkoutVerticalRepository(
        localStore: _MemoryStore(),
        transport: transport,
      ),
      debugTransport: DebugWorkoutSyncTransport(),
    );

    controller.dispose();

    expect(transport.disposed, isTrue);
  });
}

WorkoutVerticalSliceController _controller({required _TestClock clock}) {
  final debugTransport = DebugWorkoutSyncTransport();
  return WorkoutVerticalSliceController(
    repository: WorkoutVerticalRepository(
      localStore: _MemoryStore(),
      transport: debugTransport,
      clock: clock.call,
    ),
    debugTransport: debugTransport,
    clock: clock.call,
  );
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    snapshot = value;
  }
}

class _FailingStore implements WorkoutVerticalLocalStore {
  @override
  Future<WorkoutSliceSnapshot> read() =>
      throw StateError('secret-storage-value');

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {}
}

class _DisposableTransport
    implements WorkoutVerticalSyncTransport, WorkoutSyncTransportDisposer {
  bool disposed = false;

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async =>
      const SyncDispatchResult.confirmed();

  @override
  void dispose() => disposed = true;
}

class _TestClock {
  _TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration value) => now = now.add(value);
}
