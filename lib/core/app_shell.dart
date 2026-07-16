import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/components/fit_bottom_navigation.dart';
import '../services/running_session_service.dart';
import '../services/steps_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'app_router.dart';
import 'navigation/side_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final runningSession = RunningSessionService.instance;
  final stepsService = StepsService.instance;

  int currentIndex = 0;

  String nome = "Gabriel";
  String peso = "70 kg";
  String altura = "175 cm";
  String idade = "18";

  int passos = 7542;

  int segundos = 0;
  double distancia = 0.0;
  double velocidadeMedia = 0.0;

  int xp = 0;
  int nivel = 1;

  bool conquistaPrimeiraCorrida = false;
  bool conquista10Km = false;
  bool corridaIniciada = false;

  @override
  void initState() {
    super.initState();
    runningSession.addListener(_onRunningSessionChanged);
    stepsService.addListener(_onStepsChanged);
    unawaited(runningSession.initialize());
    unawaited(stepsService.initialize());
    unawaited(carregarDados());
  }

  @override
  void dispose() {
    runningSession.removeListener(_onRunningSessionChanged);
    stepsService.removeListener(_onStepsChanged);
    super.dispose();
  }

  Future<void> carregarDados() async {
    xp = await StorageService.carregarXp();
    nivel = await StorageService.carregarNivel();

    final perfil = await StorageService.carregarPerfilUsuario();

    nome = perfil['nome'] ?? nome;
    peso = perfil['peso'] ?? peso;
    altura = perfil['altura'] ?? altura;
    idade = perfil['idade'] ?? idade;

    await stepsService.initialize();
    passos = stepsService.stepsToday;
    conquistaPrimeiraCorrida = await StorageService.carregarPrimeiraCorrida();
    conquista10Km = await StorageService.carregar10Km();

    await runningSession.initialize();
    _syncRunningState();

    if (!mounted) return;
    setState(() {});
  }

  void _onRunningSessionChanged() {
    if (!mounted) return;

    setState(_syncRunningState);
  }

  void _onStepsChanged() {
    if (!mounted) return;

    unawaited(_refreshStepsAndProgress());
  }

  Future<void> _refreshStepsAndProgress() async {
    final novoXp = await StorageService.carregarXp();
    final novoNivel = await StorageService.carregarNivel();

    if (!mounted) return;

    setState(() {
      passos = stepsService.stepsToday;
      xp = novoXp;
      nivel = novoNivel;
    });
  }

  void _syncRunningState() {
    distancia = runningSession.distanceKm;
    segundos = runningSession.elapsedSeconds;
    velocidadeMedia = runningSession.averageSpeed;
    corridaIniciada = runningSession.hasActiveSession;
  }

  void iniciarCorrida() {
    unawaited(runningSession.startWithCountdown());
  }

  Future<void> pararCorrida() async {
    await runningSession.finish();
    await carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    final routeState = AppRouteState(
      nome: nome,
      peso: peso,
      altura: altura,
      idade: idade,
      passos: passos,
      distancia: distancia,
      velocidadeMedia: velocidadeMedia,
      segundos: segundos,
      xp: xp,
      nivel: nivel,
      corridaIniciada: corridaIniciada,
      conquistaPrimeiraCorrida: conquistaPrimeiraCorrida,
      conquista10Km: conquista10Km,
      iniciarCorrida: iniciarCorrida,
      pararCorrida: pararCorrida,
      carregarDados: carregarDados,
    );
    final pages = AppRouter.buildPages(routeState);

    return AppNavigationFrame(
      selectedIndex: currentIndex,
      pages: pages,
      destinations: AppRouter.destinations,
      onDestinationSelected: (index) {
        if (index >= pages.length) return;

        setState(() {
          currentIndex = index;
        });
      },
    );
  }
}

class AppNavigationFrame extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppRouteDestination> destinations;
  final List<Widget> pages;

  const AppNavigationFrame({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.pages,
  });

  @override
  State<AppNavigationFrame> createState() => _AppNavigationFrameState();
}

class _AppNavigationFrameState extends State<AppNavigationFrame> {
  int previousIndex = 0;

  @override
  void didUpdateWidget(covariant AppNavigationFrame oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      previousIndex = oldWidget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.pages.isNotEmpty);
    assert(widget.pages.length == widget.destinations.length);
    final index = widget.selectedIndex.clamp(0, widget.pages.length - 1);
    final navigationDestinations = [
      for (final destination in widget.destinations)
        FitNavigationDestination(
          label: destination.label,
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
        ),
    ];

    return PopScope<void>(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && index != 0) {
          widget.onDestinationSelected(0);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSideNavigation = constraints.maxWidth >= 840;
          final page = IndexedStack(index: index, children: widget.pages);

          if (useSideNavigation) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Row(
                children: [
                  AppSideNavigation(
                    selectedIndex: index,
                    destinations: widget.destinations,
                    onDestinationSelected: widget.onDestinationSelected,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: page),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: page,
            bottomNavigationBar: FitBottomNavigation(
              selectedIndex: index,
              destinations: navigationDestinations,
              onSelected: widget.onDestinationSelected,
            ),
          );
        },
      ),
    );
  }
}

// ignore: unused_element
class _AnimatedShellPage extends StatelessWidget {
  final int index;
  final int previousIndex;
  final Widget child;

  const _AnimatedShellPage({
    required this.index,
    required this.previousIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final forward = index >= previousIndex;

    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.curve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: Offset(forward ? 0.035 : -0.035, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(index), child: child),
    );
  }
}
