import 'dart:async';
import 'dart:io';

import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/core/navigation/app_routes.dart';
import 'package:fitai/core/navigation/app_section.dart';
import 'package:fitai/core/navigation/app_shell_navigation_scope.dart';
import 'package:fitai/core/navigation/main_scaffold.dart';
import 'package:fitai/core/navigation/navigation_controller.dart';
import 'package:fitai/core/navigation/section_router.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_plans_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_scope.dart';
import 'package:fitai/features/core_journey/presentation/unified_workout_navigation.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_library_page.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_plan_pages.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_wizards.dart';
import 'package:fitai/features/plans/presentation/routes/plans_routes.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('R2.2 - contratos de rotas de musculacao', () {
    testWidgets('ROUTE-01: Home inicia a execucao canonica', (tester) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));

      unawaited(
        UnifiedWorkoutNavigation.startAndOpen(
          tester.element(find.byKey(const ValueKey('route-home-anchor'))),
          plan: DevFixtures.workouts.single,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TreinoEmAndamentoPage), findsOneWidget);
      expect(controller.activeSession, isNotNull);
    });

    testWidgets('ROUTE-02: continuar reutiliza o sessionId existente', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));
      final plan = DevFixtures.workouts.single;

      final first = await controller.startPlan(plan);
      final existingId = first!.id;
      unawaited(
        UnifiedWorkoutNavigation.startAndOpen(
          tester.element(find.byKey(const ValueKey('route-home-anchor'))),
          plan: plan,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.activeSession?.id, existingId);
      expect(controller.snapshot.sessions, hasLength(1));
    });

    testWidgets('ROUTE-03: Planos abre detalhe oficial do plano', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));

      unawaited(
        navigation.pushNamed<void>(
          AppShellSection.plans,
          AppRoutes.corePlanDetail,
          arguments: DevFixtures.workouts.single.id,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CoreJourneyPlanDetailPage), findsOneWidget);
      await tester.tap(find.text('Iniciar treino'));
      await tester.pumpAndSettle();
      expect(find.byType(TreinoEmAndamentoPage), findsOneWidget);
    });

    testWidgets('ROUTE-04: calendario recebe o plano correto', (tester) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));

      unawaited(
        navigation.pushNamed<void>(
          AppShellSection.plans,
          PlansRoutes.calendar,
          arguments: PlanRouteArguments(planId: DevFixtures.workouts.single.id),
        ),
      );
      await tester.pumpAndSettle();

      final calendar = tester.widget<PlanosCalendarPage>(
        find.byType(PlanosCalendarPage),
      );
      expect(calendar.plan?.id, DevFixtures.workouts.single.id);
    });

    testWidgets('ROUTE-05: planos prontos mantem destino oficial', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));

      unawaited(
        navigation.pushNamed<void>(
          AppShellSection.plans,
          PlansRoutes.readyPlans,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlanosReadyLibraryPage), findsOneWidget);
    });

    testWidgets('ROUTE-06: criar com IA abre fluxo oficial', (tester) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));

      unawaited(
        navigation.pushNamed<void>(
          AppShellSection.plans,
          PlansRoutes.createWithAi,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlanosAiGoalPage), findsOneWidget);
    });

    testWidgets('ROUTE-07: acesso cruzado abre criação manual em Planos', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation, withBridge: true));

      await tester.tap(find.text('Abrir criacao em Planos'));
      await tester.pumpAndSettle();

      expect(navigation.currentSection, AppShellSection.plans);
      expect(find.byType(PlanosManualGoalPage), findsOneWidget);
    });

    testWidgets('ROUTE-08: trocar contexto do treino abre a sessão ativa', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));
      final session = await controller.startPlan(DevFixtures.workouts.single);

      unawaited(
        UnifiedWorkoutNavigation.openSession(
          tester.element(find.byKey(const ValueKey('route-home-anchor'))),
          sessionId: session!.id,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TreinoEmAndamentoPage), findsOneWidget);
      expect(controller.snapshot.sessions, hasLength(1));
    });

    testWidgets('ROUTE-09: deep link de sessão existente abre o treino', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      final session = await controller.startPlan(DevFixtures.workouts.single);
      await tester.pumpWidget(_host(controller, navigation));

      expect(
        await navigation.openDeepLink(
          Uri.parse('fitia://workout/${session!.id}'),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();

      expect(find.byType(TreinoEmAndamentoPage), findsOneWidget);
    });

    testWidgets('ROUTE-10: deep link inválido não cria sessão', (tester) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));

      expect(
        await navigation.openDeepLink(Uri.parse('fitia://workout/inexistente')),
        isTrue,
      );
      await tester.pumpAndSettle();

      expect(controller.snapshot.sessions, isEmpty);
      expect(find.text('Sessao nao encontrada'), findsWidgets);
    });

    testWidgets('ROUTE-11: toque duplo não cria sessão paralela', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));
      final context = tester.element(
        find.byKey(const ValueKey('route-home-anchor')),
      );

      unawaited(
        Future.wait([
          UnifiedWorkoutNavigation.startAndOpen(
            context,
            plan: DevFixtures.workouts.single,
          ),
          UnifiedWorkoutNavigation.startAndOpen(
            context,
            plan: DevFixtures.workouts.single,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(controller.snapshot.sessions, hasLength(1));
      expect(find.byType(TreinoEmAndamentoPage), findsOneWidget);
    });

    test('ROUTE-12: callers oficiais não importam telas legadas', () {
      const root = 'lib';
      final home = File(
        '$root/features/home/presentation/pages/home_page.dart',
      ).readAsStringSync();
      final library = File(
        '$root/screens/exercicios/biblioteca/library_plan_actions.dart',
      ).readAsStringSync();
      final router = File('$root/core/app_router.dart').readAsStringSync();

      expect(home, isNot(contains('criar_treino_page.dart')));
      expect(home, isNot(contains('treino_detalhes_page.dart')));
      expect(library, isNot(contains('criar_treino_page.dart')));
      expect(router, isNot(contains('treinos_page.dart')));
    });

    testWidgets('ROUTE-13: voltar retorna para a raiz de Planos', (
      tester,
    ) async {
      final controller = await _controller();
      final navigation = NavigationController();
      addTearDown(controller.dispose);
      addTearDown(navigation.dispose);
      await tester.pumpWidget(_host(controller, navigation));

      unawaited(
        navigation.pushNamed<void>(AppShellSection.plans, PlansRoutes.create),
      );
      await tester.pumpAndSettle();
      await navigation.maybePopCurrent();
      await tester.pumpAndSettle();

      expect(find.text('Planos'), findsWidgets);
      expect(find.byType(PlanosCreateChoicePage), findsNothing);
    });

    test(
      'ROUTE-14: troca de conta não recupera sessão de outro usuário',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final first = await _controller(
          store: SharedPreferencesWorkoutVerticalLocalStore(
            preferences,
            userScope: 'user-a',
          ),
          userId: 'user-a',
        );
        addTearDown(first.dispose);
        final session = await first.startPlan(DevFixtures.workouts.single);
        expect(session, isNotNull);

        final second = await _controller(
          store: SharedPreferencesWorkoutVerticalLocalStore(
            preferences,
            userScope: 'user-b',
          ),
          userId: 'user-b',
        );
        addTearDown(second.dispose);

        expect(second.sessionById(session!.id), isNull);
        expect(second.activeSession, isNull);
      },
    );
  });
}

Future<CoreJourneyController> _controller({
  WorkoutVerticalLocalStore? store,
  String userId = 'route-test-user',
}) async {
  final controller = CoreJourneyController(
    identityResolver: () async => CoreJourneyIdentity(
      userId: userId,
      name: userId,
      isAuthenticated: true,
    ),
    planLoader: () async => DevFixtures.workouts,
    repositoryFactory: (_) async => WorkoutVerticalRepository(
      localStore: store ?? _MemoryStore(),
      transport: DebugWorkoutSyncTransport(),
    ),
  );
  await controller.initialize();
  return controller;
}

Widget _host(
  CoreJourneyController journey,
  NavigationController navigation, {
  bool withBridge = false,
}) => MaterialApp(
  theme: AppTheme.dark,
  home: CoreJourneyScope(
    controller: journey,
    onOpenHome: () => navigation.selectSection(AppShellSection.home),
    onOpenPlanWorkoutHistory: (_) async {},
    child: AppShellNavigationScope(
      navigationController: navigation,
      child: MainScaffold(
        navigationController: navigation,
        sectionRouters: [
          SectionRouter(
            section: AppShellSection.home,
            rootBuilder: (context) => Scaffold(
              body: Center(
                child: withBridge
                    ? TextButton(
                        onPressed: () =>
                            AppShellNavigationScope.maybeOf(
                              context,
                            )!.open<void>(
                              AppShellSection.plans,
                              AppRoutes.plansCreateManual,
                            ),
                        child: const Text('Abrir criacao em Planos'),
                      )
                    : const Text('Home', key: ValueKey('route-home-anchor')),
              ),
            ),
          ),
          PlansRoutes.createRouter(
            rootBuilder: (_) =>
                const Scaffold(body: Center(child: Text('Planos'))),
          ),
          for (final section in [
            AppShellSection.activities,
            AppShellSection.library,
            AppShellSection.profile,
          ])
            SectionRouter(
              section: section,
              rootBuilder: (_) =>
                  Scaffold(body: Center(child: Text(section.label))),
            ),
        ],
      ),
    ),
  ),
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
