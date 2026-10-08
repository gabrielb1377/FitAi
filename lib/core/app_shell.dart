import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config/dev_data.dart';
import '../core/config/dev_fixtures.dart';
import '../core/auth/local_account_data_boundary.dart';
import '../core/widgets/dev_mode_banner.dart';
import '../features/core_journey/presentation/core_journey_controller.dart';
import '../features/core_journey/presentation/core_journey_scope.dart';
import '../features/progression/progression.dart';
import '../services/running_session_service.dart';
import '../services/steps_service.dart';
import '../services/storage_service.dart';
import 'app_router.dart';
import 'navigation/app_section.dart';
import 'navigation/app_routes.dart';
import 'navigation/app_shell_navigation_scope.dart';
import 'navigation/main_scaffold.dart';
import 'navigation/navigation_controller.dart';
import 'navigation/section_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.navigationController,
    this.initialDeepLink,
    this.coreJourney,
  });

  final NavigationController? navigationController;
  final Uri? initialDeepLink;
  final CoreJourneyController? coreJourney;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final runningSession = RunningSessionService.instance;
  final stepsService = StepsService.instance;
  final progressionEngine = ProgressionEngine.instance;

  late final NavigationController _navigationController;
  late final bool _ownsNavigationController;

  String nome = "Atleta";
  String peso = "70 kg";
  String altura = "175 cm";
  String idade = "18";

  int passos = 0;

  int segundos = 0;
  double distancia = 0.0;
  double velocidadeMedia = 0.0;

  int xp = 0;
  int nivel = 1;

  bool conquistaPrimeiraCorrida = false;
  bool conquista10Km = false;
  bool corridaIniciada = false;
  DevRuntimeData _devData = const DevRuntimeData.disabled();

  @override
  void initState() {
    super.initState();
    _ownsNavigationController = widget.navigationController == null;
    _navigationController =
        widget.navigationController ?? NavigationController();
    runningSession.addListener(_onRunningSessionChanged);
    stepsService.addListener(_onStepsChanged);
    AccountSessionLifecycle.revision.addListener(_onAccountChanged);
    unawaited(runningSession.initialize());
    unawaited(stepsService.initialize());
    unawaited(carregarDados());
    final initialDeepLink = widget.initialDeepLink;
    if (initialDeepLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_navigationController.openDeepLink(initialDeepLink));
      });
    }
  }

  @override
  void dispose() {
    runningSession.removeListener(_onRunningSessionChanged);
    stepsService.removeListener(_onStepsChanged);
    AccountSessionLifecycle.revision.removeListener(_onAccountChanged);
    if (_ownsNavigationController) _navigationController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    _devData = await const DevDataService().resolve();
    final progression = await progressionEngine.load();
    _applyProgress(progression.balance);

    final perfil = await StorageService.carregarPerfilUsuario();
    if (_devData.useFakeUser) {
      nome = DevFixtures.user.name;
    } else {
      nome = perfil['nome'] ?? nome;
      peso = perfil['peso'] ?? peso;
      altura = perfil['altura'] ?? altura;
      idade = perfil['idade'] ?? idade;
    }

    await stepsService.initialize();
    passos = _effectiveSteps(stepsService.stepsToday);
    conquistaPrimeiraCorrida = await StorageService.carregarPrimeiraCorrida();
    conquista10Km = await StorageService.carregar10Km();

    await runningSession.initialize();
    _syncRunningState();

    if (!mounted) return;
    setState(() {});
    unawaited(_refreshRemoteProgression(progression.userId));
  }

  Future<void> _refreshRemoteProgression(String userId) async {
    final result = await progressionEngine.syncRemote(userId: userId);
    if (!result.changed || !mounted) return;
    final activeUserId = AccountSessionLifecycle.activeUserId;
    if (activeUserId != null && activeUserId != userId) return;
    setState(() => _applyProgress(result.snapshot.balance));
  }

  void _onRunningSessionChanged() {
    if (!mounted) return;

    setState(_syncRunningState);
  }

  void _onStepsChanged() {
    if (!mounted) return;

    unawaited(_refreshStepsAndProgress());
  }

  void _onAccountChanged() => unawaited(carregarDados());

  Future<void> _refreshStepsAndProgress() async {
    final progression = await progressionEngine.load();

    if (!mounted) return;

    setState(() {
      passos = _effectiveSteps(stepsService.stepsToday);
      _applyProgress(progression.balance);
    });
  }

  void _syncRunningState() {
    distancia = runningSession.distanceKm;
    segundos = runningSession.elapsedSeconds;
    velocidadeMedia = runningSession.averageSpeed;
    corridaIniciada = runningSession.hasActiveSession;
    if (!corridaIniciada && distancia <= 0 && _devData.useFakeRunning) {
      distancia = DevFixtures.running.distanceKm;
      segundos = DevFixtures.running.elapsedSeconds;
      velocidadeMedia = DevFixtures.running.averageSpeed;
    }
  }

  void _applyProgress(XpBalance balance) {
    final value = AppShellProgression.fromBalance(balance);
    if (_devData.useFakeProgress && value.xp <= 0 && value.level <= 1) {
      xp = DevFixtures.user.xp;
      nivel = DevFixtures.user.level;
      return;
    }
    xp = value.xp;
    nivel = value.level;
  }

  int _effectiveSteps(int realSteps) {
    if (_devData.useFakeSteps && realSteps <= 0) return DevFixtures.steps;
    return realSteps;
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
      onSelectTab: _navigationController.selectIndex,
    );
    final sectionRouters = AppRouter.buildSectionRouters(routeState);

    final shell = AppShellNavigationScope(
      navigationController: _navigationController,
      child: MainScaffold(
        navigationController: _navigationController,
        sectionRouters: sectionRouters,
      ),
    );
    final scopedShell = widget.coreJourney == null
        ? shell
        : CoreJourneyScope(
            controller: widget.coreJourney!,
            onOpenHome: () =>
                _navigationController.selectSection(AppShellSection.home),
            onOpenPlanWorkoutHistory: (sessionId) async {
              await _navigationController.pushNamed<void>(
                AppShellSection.plans,
                AppRoutes.corePlanWorkoutHistory,
                arguments: sessionId,
              );
            },
            child: shell,
          );
    // Ferramentas de desenvolvimento ficam em Configuracoes > Developer Mode.
    // A shell oficial nunca recebe controles que alterem sua composicao visual.
    return DevModeBanner(child: scopedShell);
  }
}

/// Presentation projection derived exclusively from the canonical balance.
///
/// Home still receives XP within the current level for visual compatibility,
/// while Profile consumes the complete [XpBalance] from the same snapshot.
class AppShellProgression {
  const AppShellProgression({required this.xp, required this.level});

  final int xp;
  final int level;

  factory AppShellProgression.fromBalance(XpBalance balance) =>
      AppShellProgression(
        xp: balance.xpIntoCurrentLevel,
        level: balance.currentLevel,
      );
}

/// Adapter compatível para consumidores da shell anterior.
@Deprecated('Use MainScaffold com NavigationController e SectionRouter.')
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
  late final NavigationController _navigationController;

  @override
  void initState() {
    super.initState();
    _navigationController = NavigationController(
      initialSection:
          AppShellSection.fromIndex(widget.selectedIndex) ??
          AppShellSection.home,
    )..addListener(_forwardSelection);
  }

  @override
  void didUpdateWidget(covariant AppNavigationFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _navigationController.selectIndex(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _navigationController
      ..removeListener(_forwardSelection)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.pages.isNotEmpty);
    assert(widget.pages.length == widget.destinations.length);
    assert(widget.pages.length == AppShellSection.values.length);
    final routers = [
      for (var index = 0; index < AppShellSection.values.length; index++)
        SectionRouter(
          section: AppShellSection.values[index],
          rootBuilder: (_) => widget.pages[index],
        ),
    ];

    return MainScaffold(
      navigationController: _navigationController,
      sectionRouters: routers,
    );
  }

  void _forwardSelection() {
    final index = _navigationController.selectedIndex;
    if (index != widget.selectedIndex) widget.onDestinationSelected(index);
  }
}
