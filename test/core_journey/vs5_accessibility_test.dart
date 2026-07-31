import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/design_system/components/fit_inputs.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_history_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_summary_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_workout_page.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VS5 Treino expoe progresso, midia, campos e acao principal', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    final plan = DevFixtures.workouts.single;
    final session = await controller.startPlan(plan);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        CoreJourneyWorkoutPage(
          controller: controller,
          plan: plan,
          sessionId: session!.id,
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('Exercicio 1 de')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Midia')), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Carga (kg)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .getSemantics(find.byType(FitNumberField).first)
          .flagsCollection
          .isTextField,
      isTrue,
    );
    expect(
      tester
          .getSemantics(find.byType(FitNumberField).at(1))
          .flagsCollection
          .isTextField,
      isTrue,
    );
    expect(
      tester.getSemantics(find.text('Concluir serie')).flagsCollection.isButton,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('VS5 Treino recebe foco por teclado e dialogo fecha por Escape', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    final plan = DevFixtures.workouts.single;
    final session = await controller.startPlan(plan);

    await tester.pumpWidget(
      _host(
        CoreJourneyWorkoutPage(
          controller: controller,
          plan: plan,
          sessionId: session!.id,
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final firstFocus = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNot(same(firstFocus)));

    await tester.scrollUntilVisible(
      find.text('Finalizar treino'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Finalizar treino'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('VS5 Resumo e historico possuem rotulos de leitura completos', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    final plan = DevFixtures.workouts.single;
    final session = await controller.startPlan(plan);
    await controller.registerSet(
      sessionId: session!.id,
      exercise: plan.exercicios.first,
      weight: 55,
      reps: 10,
    );
    await controller.finishWorkout(session.id);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        CoreJourneySummaryPage(controller: controller, sessionId: session.id),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Resumo da sessao.')), findsOneWidget);
    expect(find.bySemanticsLabel('Ver historico'), findsWidgets);

    await tester.pumpWidget(
      _host(CoreJourneyHistoryPage(controller: controller)),
    );
    expect(find.bySemanticsLabel(RegExp('Abrir resumo.')), findsOneWidget);
    semantics.dispose();
  });
}

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

Future<CoreJourneyController> _controller() async {
  final store = _MemoryStore();
  final controller = CoreJourneyController(
    identityResolver: () async => const CoreJourneyIdentity(
      userId: 'vs5-a11y',
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
