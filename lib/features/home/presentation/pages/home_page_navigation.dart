part of 'home_page.dart';

extension _HomePageNavigation on _HomePageState {
  Future<void> _openSelectedWorkout() async {
    final workout = _controller.state.selection.treino;
    if (workout == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TreinoEmAndamentoPage(
          treino: workout,
          onXpAtualizado: widget.onXpAtualizado,
        ),
      ),
    );
    await widget.onXpAtualizado?.call();
    await _refresh();
  }

  Future<void> _openCreatePlan() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CriarTreinoPage()));
    await _refresh();
  }

  Future<void> _openRunning() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CorridasPage(
          distancia: widget.distancia,
          velocidadeMedia: widget.velocidadeMedia,
          segundos: widget.segundos,
          corridaIniciada: widget.corridaIniciada,
          iniciarCorrida: widget.iniciarCorrida ?? () {},
          pararCorrida: widget.pararCorrida ?? () {},
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openSteps() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PassosPage(passos: widget.passos),
      ),
    );
  }

  Future<void> _openCoach() {
    final state = _controller.state;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: HomeRoutes.coach),
        builder: (_) => HomeCoachPage(
          initialInsights: state.coachInsights,
          recommendation: state.recommendation,
          isOffline: state.isOffline,
          onReload: const CoachInsightService().gerarInsightsGerais,
          onOpenDailySummary: () => unawaited(_openDailySummary()),
        ),
      ),
    );
  }

  Future<void> _openGoals() {
    final state = _controller.state;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: HomeRoutes.goals),
        builder: (_) => HomeGoalsPage(
          initialGoals: state.goals,
          isOffline: state.isOffline,
          onReload: const MetasService().carregarMetas,
        ),
      ),
    );
  }

  Future<void> _openAchievements() {
    final state = _controller.state;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: HomeRoutes.achievements),
        builder: (_) => HomeAchievementsPage(
          initialAchievements: state.achievements,
          level: widget.nivel,
          xp: widget.xp,
          streak: state.currentStreak,
          isOffline: state.isOffline,
          onReload: const AchievementService().carregarConquistas,
        ),
      ),
    );
  }

  Future<void> _openNotifications() async {
    final service = const NotificationService();
    final state = _controller.state;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: HomeRoutes.notifications),
        builder: (_) => HomeNotificationsPage(
          initialNotifications: state.notifications,
          isOffline: state.isOffline,
          onReload: service.carregarNotificacoes,
          onMarkRead: (item) => service.marcarComoLida(item.id),
          onMarkAllRead: service.marcarTodasComoLidas,
          onOpenAction: _openNotificationAction,
          onOpenSettings: () => unawaited(_openReminders()),
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openNotificationAction(FitaiNotificationModel item) async {
    if (item.acao.startsWith('treino:')) {
      final workout = await _findWorkout(item.acao.substring(7));
      if (!mounted || workout == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TreinoEmAndamentoPage(treino: workout),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (item.acao == 'agenda') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AgendaTreinosPage()),
      );
    } else if (item.acao == 'evolucao') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const EvolucaoPage()));
    } else if (item.acao == 'corrida') {
      await _openRunning();
    }
  }

  Future<TreinoModel?> _findWorkout(String id) async {
    for (final workout in _workouts.treinos) {
      if (workout.id == id) return workout;
    }
    final saved = await StorageService.carregarTreinos();
    for (final workout in saved) {
      if (workout.id == id) return workout;
    }
    return null;
  }
}
