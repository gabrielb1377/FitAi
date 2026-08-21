import 'dart:async';

import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/core/navigation/app_routes.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_scope.dart';
import 'package:fitai/features/core_journey/presentation/unified_workout_navigation.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('persiste sessão antes da rota e coalesce toque duplo', (
    tester,
  ) async {
    final store = _MemoryStore();
    final controller = CoreJourneyController(
      identityResolver: () async => const CoreJourneyIdentity(
        userId: 'navigation-user',
        name: 'Navigation User',
        isAuthenticated: true,
      ),
      planLoader: () async => DevFixtures.workouts,
      repositoryFactory: (_) async => WorkoutVerticalRepository(
        localStore: store,
        transport: const _OfflineTransport(),
      ),
    );
    await controller.initialize();
    addTearDown(controller.dispose);
    final observer = _PersistenceObserver(store);
    final plan = DevFixtures.workouts.single;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        navigatorObservers: [observer],
        home: CoreJourneyScope(
          controller: controller,
          onOpenHome: () {},
          onOpenPlanWorkoutHistory: (_) async {},
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => unawaited(
                  UnifiedWorkoutNavigation.startAndOpen(context, plan: plan),
                ),
                child: const Text('Abrir treino'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir treino'));
    await tester.tap(find.text('Abrir treino'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TreinoEmAndamentoPage), findsOneWidget);
    expect(store.snapshot.sessions, hasLength(1));
    expect(observer.workoutPushes, 1);
    expect(observer.wasPersistedBeforePush, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.pump();
  });
}

class _PersistenceObserver extends NavigatorObserver {
  _PersistenceObserver(this.store);

  final _MemoryStore store;
  int workoutPushes = 0;
  bool wasPersistedBeforePush = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != AppRoutes.coreWorkout) return;
    workoutPushes++;
    wasPersistedBeforePush =
        store.snapshot.sessions.length == 1 &&
        store.snapshot.outbox.any(
          (event) => event.eventType == 'workout_session_started',
        );
  }
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

class _OfflineTransport implements WorkoutVerticalSyncTransport {
  const _OfflineTransport();

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) {
    throw const WorkoutSyncTransportException('Offline', retryable: true);
  }
}
