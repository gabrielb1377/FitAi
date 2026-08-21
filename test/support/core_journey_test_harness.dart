import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_scope.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:flutter/widgets.dart';

Future<CoreJourneyController> createCoreJourneyTestController(
  List<TreinoModel> plans,
) async {
  final controller = CoreJourneyController(
    identityResolver: () async => const CoreJourneyIdentity(
      userId: 'widget-test-user',
      name: 'Widget Test',
      isAuthenticated: true,
    ),
    planLoader: () async => plans,
    repositoryFactory: (_) async => WorkoutVerticalRepository(
      localStore: _MemoryStore(),
      transport: DebugWorkoutSyncTransport(),
    ),
  );
  await controller.initialize();
  return controller;
}

Widget coreJourneyTestScope(
  CoreJourneyController controller, {
  required Widget child,
}) {
  return CoreJourneyScope(
    controller: controller,
    onOpenHome: () {},
    onOpenPlanWorkoutHistory: (_) async {},
    child: child,
  );
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    snapshot = WorkoutSliceSnapshot.fromJson(value.toJson());
  }
}
