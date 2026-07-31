import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/auth/presentation/pages/login_page.dart';
import 'package:fitai/features/auth/presentation/pages/onboarding_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_history_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_home_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_plans_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_summary_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_workout_page.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const viewports = <Size>[
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(600, 960),
    Size(768, 1024),
    Size(1024, 768),
    Size(1440, 900),
  ];

  for (final viewport in viewports) {
    testWidgets(
      'VS5 Core V1 nao apresenta overflow em ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        _setViewport(tester, viewport);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = await _controller();
        addTearDown(controller.dispose);
        final plan = DevFixtures.workouts.single;
        final session = await controller.startPlan(plan);
        await _pumpAndExpectNoException(
          tester,
          CoreJourneyHomePage(controller: controller, onOpenPlans: () {}),
        );
        await _pumpAndExpectNoException(
          tester,
          CoreJourneyPlanDetailPage(controller: controller, plan: plan),
        );
        await _pumpAndExpectNoException(
          tester,
          CoreJourneyWorkoutPage(
            controller: controller,
            plan: plan,
            sessionId: session!.id,
          ),
        );

        await controller.registerSet(
          sessionId: session.id,
          exercise: plan.exercicios.first,
          weight: 55,
          reps: 10,
        );
        await controller.finishWorkout(session.id);
        await _pumpAndExpectNoException(
          tester,
          CoreJourneySummaryPage(controller: controller, sessionId: session.id),
        );
        await _pumpAndExpectNoException(
          tester,
          CoreJourneyHistoryPage(controller: controller),
        );
      },
    );
  }

  testWidgets('VS5 Auth e Core V1 preservam scroll em fonte 200%', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 800));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAndExpectNoException(tester, const LoginPage(), textScale: 2);
    await _pumpAndExpectNoException(
      tester,
      const OnboardingPage(),
      textScale: 2,
    );

    final controller = await _controller();
    addTearDown(controller.dispose);
    final plan = DevFixtures.workouts.single;
    final session = await controller.startPlan(plan);
    await _pumpAndExpectNoException(
      tester,
      CoreJourneyWorkoutPage(
        controller: controller,
        plan: plan,
        sessionId: session!.id,
      ),
      textScale: 2,
    );
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('VS5 alto contraste e tema claro nao geram excecao visual', (
    tester,
  ) async {
    _setViewport(tester, const Size(1024, 768));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await _controller();
    addTearDown(controller.dispose);
    await _pumpAndExpectNoException(
      tester,
      CoreJourneyHomePage(controller: controller, onOpenPlans: () {}),
      highContrast: true,
      theme: ThemeData.light(useMaterial3: true),
    );
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

Future<void> _pumpAndExpectNoException(
  WidgetTester tester,
  Widget page, {
  double textScale = 1,
  bool highContrast = false,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            highContrast: highContrast,
          ),
          child: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<CoreJourneyController> _controller() async {
  final store = _MemoryStore();
  final controller = CoreJourneyController(
    identityResolver: () async => const CoreJourneyIdentity(
      userId: 'vs5-responsive',
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
