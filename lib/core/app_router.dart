import 'package:flutter/material.dart';

import '../features/activities/presentation/pages/activities_root_page.dart';
import '../features/activities/presentation/routes/activities_routes.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/routes/home_routes.dart';
import '../features/library/presentation/pages/library_root_page.dart';
import '../features/library/presentation/routes/library_routes.dart';
import '../features/plans/presentation/pages/plans_root_page.dart';
import '../features/plans/presentation/routes/plans_routes.dart';
import '../features/profile/presentation/pages/profile_root_page.dart';
import '../features/profile/presentation/routes/profile_routes.dart';
import 'navigation/app_section.dart';
import 'navigation/section_router.dart';

class AppRouteDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppRouteDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AppRouteState {
  final String nome;
  final String peso;
  final String altura;
  final String idade;
  final int passos;
  final double distancia;
  final double velocidadeMedia;
  final int segundos;
  final int xp;
  final int nivel;
  final bool corridaIniciada;
  final bool conquistaPrimeiraCorrida;
  final bool conquista10Km;
  final VoidCallback iniciarCorrida;
  final VoidCallback pararCorrida;
  final Future<void> Function() carregarDados;
  final ValueChanged<int> onSelectTab;

  const AppRouteState({
    required this.nome,
    required this.peso,
    required this.altura,
    required this.idade,
    required this.passos,
    required this.distancia,
    required this.velocidadeMedia,
    required this.segundos,
    required this.xp,
    required this.nivel,
    required this.corridaIniciada,
    required this.conquistaPrimeiraCorrida,
    required this.conquista10Km,
    required this.iniciarCorrida,
    required this.pararCorrida,
    required this.carregarDados,
    required this.onSelectTab,
  });
}

class AppRouter {
  const AppRouter._();

  /// Destinos legados derivados da mesma fonte usada pelo shell oficial.
  static final destinations = List<AppRouteDestination>.unmodifiable(
    AppShellSection.values.map(
      (section) => AppRouteDestination(
        icon: section.icon,
        selectedIcon: section.selectedIcon,
        label: section.label,
      ),
    ),
  );

  static List<Widget> buildPages(AppRouteState state) {
    return [
      _homePage(state),
      _plansPage(state),
      _activitiesPage(state),
      _libraryPage(),
      _profilePage(state),
    ];
  }

  static List<SectionRouter> buildSectionRouters(AppRouteState state) {
    return [
      HomeRoutes.createRouter(rootBuilder: (_) => _homePage(state)),
      PlansRoutes.createRouter(rootBuilder: (_) => _plansPage(state)),
      ActivitiesRoutes.createRouter(rootBuilder: (_) => _activitiesPage(state)),
      LibraryRoutes.createRouter(rootBuilder: (_) => _libraryPage()),
      ProfileRoutes.createRouter(rootBuilder: (_) => _profilePage(state)),
    ];
  }

  static Widget _homePage(AppRouteState state) {
    return HomePage(
      key: const PageStorageKey('tab-home'),
      nome: state.nome,
      distancia: state.distancia,
      passos: state.passos,
      xp: state.xp,
      nivel: state.nivel,
      velocidadeMedia: state.velocidadeMedia,
      segundos: state.segundos,
      corridaIniciada: state.corridaIniciada,
      iniciarCorrida: state.iniciarCorrida,
      pararCorrida: state.pararCorrida,
      onSelectTab: state.onSelectTab,
      onXpAtualizado: state.carregarDados,
    );
  }

  static Widget _plansPage(AppRouteState state) {
    return PlansRootPage(
      key: const PageStorageKey('tab-planos'),
      onXpUpdated: state.carregarDados,
      onBack: () => state.onSelectTab(0),
    );
  }

  static Widget _activitiesPage(AppRouteState state) {
    return ActivitiesRootPage(
      key: const PageStorageKey('tab-atividades'),
      steps: state.passos,
      distance: state.distancia,
      averageSpeed: state.velocidadeMedia,
      elapsedSeconds: state.segundos,
      running: state.corridaIniciada,
      onStartRunning: state.iniciarCorrida,
      onStopRunning: state.pararCorrida,
    );
  }

  static Widget _libraryPage() {
    return const LibraryRootPage(key: PageStorageKey('tab-biblioteca'));
  }

  static Widget _profilePage(AppRouteState state) {
    return ProfileRootPage(
      key: const PageStorageKey('tab-perfil'),
      name: state.nome,
      weight: state.peso,
      height: state.altura,
      age: state.idade,
      level: state.nivel,
      firstRunAchievement: state.conquistaPrimeiraCorrida,
      tenKilometersAchievement: state.conquista10Km,
      onProfileUpdated: state.carregarDados,
    );
  }
}
