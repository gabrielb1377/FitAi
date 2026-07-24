import 'dart:async';

import 'package:fitai/core/navigation/app_routes.dart';
import 'package:fitai/core/navigation/app_section.dart';
import 'package:fitai/core/navigation/deep_link.dart';
import 'package:fitai/core/navigation/main_scaffold.dart';
import 'package:fitai/core/navigation/navigation_controller.dart';
import 'package:fitai/core/navigation/root_router.dart';
import 'package:fitai/core/navigation/section_router.dart';
import 'package:fitai/core/navigation/side_navigation.dart';
import 'package:fitai/design_system/components/fit_bottom_navigation.dart';
import 'package:fitai/features/activities/presentation/routes/activities_routes.dart';
import 'package:fitai/features/home/presentation/routes/home_routes.dart';
import 'package:fitai/features/library/presentation/routes/library_routes.dart';
import 'package:fitai/features/plans/presentation/routes/plans_routes.dart';
import 'package:fitai/features/profile/presentation/routes/profile_routes.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seções mantêm ordem, paths e índices oficiais', () {
    expect(AppShellSection.values.map((section) => section.label), [
      'Home',
      'Planos',
      'Atividades',
      'Biblioteca',
      'Perfil',
    ]);
    expect(AppShellSection.activities.index, 2);
    expect(AppShellSection.library.index, 3);
    expect(AppShellSection.fromIndex(-1), isNull);
    expect(AppShellSection.fromIndex(5), isNull);
    expect(HomeRoutes.root, AppShellSection.home.rootRoute);
    expect(PlansRoutes.root, AppShellSection.plans.rootRoute);
    expect(ActivitiesRoutes.root, AppShellSection.activities.rootRoute);
    expect(LibraryRoutes.root, AppShellSection.library.rootRoute);
    expect(ProfileRoutes.root, AppShellSection.profile.rootRoute);
  });

  test('parser prepara deep links do app e da web sem navegar', () {
    final appTarget = AppDeepLinkParser.parse(
      Uri.parse('fitia://planos/detail?id=plan-1'),
    );
    final webTarget = AppDeepLinkParser.parse(
      Uri.parse('https://fitia.app/biblioteca/exercise?id=exercise-1'),
    );

    expect(appTarget?.section, AppShellSection.plans);
    expect(appTarget?.routeName, '/plans/detail');
    expect(appTarget?.uri.queryParameters['id'], 'plan-1');
    expect(webTarget?.section, AppShellSection.library);
    expect(webTarget?.routeName, '/library/exercise');
    expect(AppDeepLinkParser.parse(Uri.parse('fitia://unknown/path')), isNull);
  });

  test('roteador raiz registra os contratos nomeados', () {
    final route = RootRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.login),
    );
    expect(route.settings.name, AppRoutes.login);
  });

  testWidgets('shell usa Bottom Navigation também em viewport largo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = NavigationController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(controller));

    expect(find.byType(FitBottomNavigation), findsOneWidget);
    expect(find.byType(AppSideNavigation), findsNothing);
    expect(
      tester.getSize(find.byType(FitBottomNavigation)).width,
      lessThanOrEqualTo(600),
    );
  });

  testWidgets('cada seção preserva sua pilha aninhada ao trocar de aba', (
    tester,
  ) async {
    final controller = NavigationController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller, includePlanDetail: true));

    controller.selectSection(AppShellSection.plans);
    await tester.pumpAndSettle();
    unawaited(
      controller.pushNamed<void>(AppShellSection.plans, '/plans/detail'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detalhe do plano'), findsOneWidget);

    controller.selectSection(AppShellSection.library);
    await tester.pumpAndSettle();
    expect(find.text('Raiz Biblioteca'), findsOneWidget);

    controller.selectSection(AppShellSection.plans);
    await tester.pumpAndSettle();
    expect(find.text('Detalhe do plano'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Raiz Planos'), findsOneWidget);
  });

  testWidgets('raiz aninhada recebe dados atualizados sem perder o Navigator', (
    tester,
  ) async {
    final controller = NavigationController();
    final value = ValueNotifier<int>(1);
    addTearDown(controller.dispose);
    addTearDown(value.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ValueListenableBuilder<int>(
          valueListenable: value,
          builder: (context, currentValue, _) => MainScaffold(
            navigationController: controller,
            sectionRouters: [
              for (final section in AppShellSection.values)
                SectionRouter(
                  section: section,
                  rootBuilder: (_) => Scaffold(
                    body: Center(
                      child: Text('${section.label}: $currentValue'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home: 1'), findsOneWidget);
    value.value = 2;
    await tester.pump();
    expect(find.text('Home: 2'), findsOneWidget);
  });

  testWidgets('deep link reservado abre placeholder oficial da seção', (
    tester,
  ) async {
    final controller = NavigationController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    expect(
      await controller.openDeepLink(Uri.parse('fitia://planos/detail')),
      isTrue,
    );
    await tester.pumpAndSettle();

    expect(controller.currentSection, AppShellSection.plans);
    expect(find.text('Em desenvolvimento'), findsOneWidget);
    expect(find.text('Próxima etapa do módulo'), findsOneWidget);
  });
}

Widget _host(
  NavigationController controller, {
  bool includePlanDetail = false,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: MainScaffold(
      navigationController: controller,
      sectionRouters: [
        for (final section in AppShellSection.values)
          SectionRouter(
            section: section,
            rootBuilder: (_) => _RootPage(section: section),
            routes: {
              if (includePlanDetail && section == AppShellSection.plans)
                '/plans/detail': (_, _) =>
                    const Center(child: Text('Detalhe do plano')),
            },
            declaredRoutes: {
              if (section == AppShellSection.plans) '/plans/detail',
            },
          ),
      ],
    ),
  );
}

class _RootPage extends StatelessWidget {
  const _RootPage({required this.section});

  final AppShellSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Raiz ${section.label}')));
  }
}
