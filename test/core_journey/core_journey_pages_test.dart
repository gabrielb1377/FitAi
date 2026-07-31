import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_home_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_plans_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_workout_page.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home reflete sessao ativa e Planos abre detalhe', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    await controller.startPlan(DevFixtures.workouts.single);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CoreJourneyHomePage(controller: controller, onOpenPlans: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continuar treino'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CoreJourneyPlansPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upper A').first);
    await tester.pumpAndSettle();
    expect(find.text('Iniciar treino'), findsNothing);
    expect(find.text('Continuar treino'), findsOneWidget);
  });

  testWidgets('treino offline registra serie, finaliza e abre resumo', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    final plan = DevFixtures.workouts.single;
    final session = await controller.startPlan(plan);
    expect(
      controller.sessionById(session!.id)?.status,
      WorkoutSessionStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CoreJourneyWorkoutPage(
          controller: controller,
          plan: plan,
          sessionId: session.id,
        ),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Concluir serie'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Concluir serie'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '55');
    await tester.enterText(fields.at(1), '10');
    await tester.tap(find.text('Concluir serie'));
    await tester.pump();
    expect(controller.setsFor(session.id), hasLength(1));

    await tester.ensureVisible(find.text('Finalizar treino'));
    await tester.tap(find.text('Finalizar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();

    expect(find.text('Treino concluido'), findsOneWidget);
    expect(find.text('Ver historico'), findsOneWidget);
    expect(controller.completedSessions, hasLength(1));
  });
}

Future<CoreJourneyController> _controller() async {
  final store = _MemoryStore();
  final controller = CoreJourneyController(
    identityResolver: () async => const CoreJourneyIdentity(
      userId: 'test-user',
      name: 'Teste',
      isAuthenticated: true,
    ),
    planLoader: () async => DevFixtures.workouts,
    repositoryFactory: (_) async => WorkoutVerticalRepository(
      localStore: store,
      transport: DebugWorkoutSyncTransport(),
    ),
  );
  await controller.initialize();
  return controller;
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot _snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => _snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
