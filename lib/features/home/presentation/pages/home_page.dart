import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_notification_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/corridas/corridas_page.dart';
import '../../../../screens/passos_page.dart';
import '../../../../screens/perfil/agenda_treinos_page.dart';
import '../../../../screens/perfil/evolucao_page.dart';
import '../../../../screens/treinos/criar_treino_page.dart';
import '../../../../screens/treinos/treino_profissional_page.dart';
import '../../../../services/achievement_service.dart';
import '../../../../services/coach_insight_service.dart';
import '../../../../services/metas_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/treino_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_dashboard_content.dart';
import 'home_achievements_page.dart';
import 'home_coach_page.dart';
import 'home_goals_page.dart';
import 'home_notifications_page.dart';

part 'home_page_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.nome,
    required this.distancia,
    required this.passos,
    required this.xp,
    required this.nivel,
    this.velocidadeMedia = 0,
    this.segundos = 0,
    this.corridaIniciada = false,
    this.iniciarCorrida,
    this.pararCorrida,
    this.onSelectTab,
    this.onXpAtualizado,
    this.controller,
  });

  final String nome;
  final double distancia;
  final int passos;
  final int xp;
  final int nivel;
  final double velocidadeMedia;
  final int segundos;
  final bool corridaIniciada;
  final VoidCallback? iniciarCorrida;
  final VoidCallback? pararCorrida;
  final ValueChanged<int>? onSelectTab;
  final Future<void> Function()? onXpAtualizado;
  final HomeController? controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _workouts = TreinoService.instance;
  late final HomeController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HomeController();
    _workouts.addListener(_onWorkoutsChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _workouts.removeListener(_onWorkoutsChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onWorkoutsChanged() => unawaited(_refresh());

  Future<void> _load() => _controller.load(
    workouts: _workouts.treinos,
    xp: widget.xp,
    level: widget.nivel,
  );

  Future<void> _refresh() => _controller.refresh(
    workouts: _workouts.treinos,
    xp: widget.xp,
    level: widget.nivel,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => HomeDashboardContent(
          state: _controller.state,
          name: widget.nome,
          level: widget.nivel,
          xp: widget.xp,
          steps: widget.passos,
          distance: widget.distancia,
          runningActive: widget.corridaIniciada,
          runningSeconds: widget.segundos,
          onRefresh: _refresh,
          onOpenWorkout: () => unawaited(_openSelectedWorkout()),
          onCreatePlan: () => unawaited(_openCreatePlan()),
          onOpenLibrary: () => widget.onSelectTab?.call(2),
          onOpenRunning: () => unawaited(_openRunning()),
          onOpenSteps: () => unawaited(_openSteps()),
          onOpenCoach: () => unawaited(_openCoach()),
          onOpenGoals: () => unawaited(_openGoals()),
          onOpenAchievements: () => unawaited(_openAchievements()),
          onOpenNotifications: () => unawaited(_openNotifications()),
          onOpenProfile: () => widget.onSelectTab?.call(4),
        ),
      ),
    );
  }
}
