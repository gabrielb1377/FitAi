import 'package:fitai/core/app_shell.dart';
import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/core/navigation/app_section.dart';
import 'package:fitai/core/navigation/navigation_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/plans/presentation/pages/plan_workout_history_pages.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_plan_pages.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/screens/treinos/treino_finalizado_page.dart';
import 'package:fitai/screens/treinos/widgets/plans/official_workout_session.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('VS5 plano, treino offline, resumo e historico funcionam', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    final plan = DevFixtures.workouts.single;
    final navigation = NavigationController(
      initialSection: AppShellSection.plans,
    );
    addTearDown(navigation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AppShell(
          coreJourney: controller,
          navigationController: navigation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(plan.nome), findsOneWidget);
    await tester.tap(find.text('Continuar plano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(buildPlanosPlanDays(plan).first.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comecar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Iniciar treino'));
    await tester.pumpAndSettle();

    // The outer vertical list owns page scrolling, not EditableText's scrollables.
    final workout = find.byType(OfficialWorkoutSession);
    final workoutScroll = find.descendant(
      of: workout,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(workout, findsOneWidget);
    expect(workoutScroll, findsOneWidget);
    final register = find.descendant(
      of: workout,
      matching: find.byTooltip('Registrar serie'),
    );
    await tester.scrollUntilVisible(register, 300, scrollable: workoutScroll);
    Finder input(String label) => find.descendant(
      of: find.descendant(
        of: workout,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        ),
      ),
      matching: find.byType(TextField),
    );
    final weight = input('Carga em quilogramas');
    final reps = input('Quantidade de repeticoes');
    expect(weight, findsOneWidget);
    expect(reps, findsOneWidget);
    await tester.enterText(weight, '55');
    await tester.enterText(reps, '10');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(register);
    await tester.pumpAndSettle();
    expect(register.hitTestable(), findsOneWidget);
    await tester.tap(register);
    await tester.pumpAndSettle();

    final session = controller.activeSession;
    expect(session, isNotNull);
    expect(controller.setsFor(session!.id), hasLength(1));
    expect(session.planId, plan.id);
    expect(controller.setsFor(session.id).single.weight, 55);
    expect(controller.setsFor(session.id).single.reps, 10);
    expect(controller.hasPendingSync, isTrue);

    ScaffoldMessenger.of(tester.element(register)).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    final more = find.descendant(
      of: workout,
      matching: find.byTooltip('Mais opções'),
    );
    await tester.scrollUntilVisible(more, 300, scrollable: workoutScroll);
    await tester.pumpAndSettle();
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    expect(more.hitTestable(), findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    final endWorkout = find.text('Encerrar treino');
    await tester.ensureVisible(endWorkout);
    await tester.pumpAndSettle();
    expect(endWorkout.hitTestable(), findsOneWidget);
    await tester.tap(endWorkout);
    await tester.pumpAndSettle();
    expect(find.text('Encerrar e salvar treino?'), findsOneWidget);
    await tester.tap(find.text('Encerrar e salvar'));
    await tester.pumpAndSettle();

    expect(find.byType(TreinoFinalizadoPage), findsOneWidget);
    expect(find.text('Treino concluido!'), findsOneWidget);
    final summary = find.text('Ver resumo');
    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    expect(summary.hitTestable(), findsOneWidget);
    await tester.tap(summary);
    await tester.pumpAndSettle();
    expect(find.text('Series concluidas'), findsOneWidget);
    await tester.tap(find.text('Voltar para Planos'));
    await tester.pumpAndSettle();
    // Return through the real route stack, then use Plans' existing history entry.
    for (
      var back = 0;
      back < 5 && find.byTooltip('Mais opcoes de planos').evaluate().isEmpty;
      back++
    ) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(find.byTooltip('Mais opcoes de planos'), findsOneWidget);
    await tester.tap(find.byTooltip('Mais opcoes de planos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historico de planos'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanWorkoutHistoryPage), findsOneWidget);
    expect(controller.completedSessions, hasLength(1));
    expect(controller.hasPendingSync, isTrue);
    final history = await controller.loadPlanWorkoutHistory();
    expect(history.workouts, hasLength(1));
    expect(history.workouts.single.id, session.id);
    expect(history.workouts.single.metrics.setCount, 1);
    expect(history.workouts.single.metrics.totalVolume, 550);
  });
}

Future<CoreJourneyController> _controller() async {
  final controller = CoreJourneyController(
    identityResolver: () async => const CoreJourneyIdentity(
      userId: 'vs5-integration-user',
      name: 'Teste VS5',
      isAuthenticated: true,
    ),
    planLoader: () async => DevFixtures.workouts,
    repositoryFactory: (_) async => WorkoutVerticalRepository(
      localStore: _MemoryStore(),
      transport: DebugWorkoutSyncTransport()..online = false,
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
