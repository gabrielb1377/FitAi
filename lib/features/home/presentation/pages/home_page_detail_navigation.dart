part of 'home_page.dart';

extension _HomePageDetailNavigation on _HomePageState {
  Future<void> _openOverview() {
    final state = _controller.state;
    return _pushHome(
      HomeOverviewPage(
        state: state,
        xp: widget.xp,
        level: widget.nivel,
        onOpenGoals: () => unawaited(_openGoals()),
        onOpenProgress: () => unawaited(_openProgress()),
        onOpenRecords: () => unawaited(_openRecords()),
        onOpenChallenges: () => unawaited(_openWeeklyChallenges()),
      ),
      HomeRoutes.overview,
    );
  }

  Future<void> _openTodayWorkout() {
    final state = _controller.state;
    return _pushHome(
      HomeTodayWorkoutPage(
        workout: state.selection.treino,
        insight: state.coachInsights.firstOrNull,
        onStart: () => unawaited(_openSelectedWorkout()),
        onViewExercises: () {
          final workout = state.selection.treino;
          if (workout != null) unawaited(_openWorkoutDetails(workout));
        },
        onCreatePlan: () => unawaited(_openCreatePlan()),
        onOpenSchedule: () => unawaited(_openUpcomingWorkouts()),
        onOpenSuggestedPlans: () => unawaited(_openSuggestedPlans()),
      ),
      HomeRoutes.todayWorkout,
    );
  }

  Future<void> _openSuggestedPlans() {
    final state = _controller.state;
    return _pushHome(
      HomeSuggestedPlansPage(
        plans: state.workouts,
        onOpenPlan: (plan) => unawaited(_openWorkoutDetails(plan)),
        onExploreAll: () =>
            widget.onSelectTab?.call(AppShellSection.plans.index),
      ),
      HomeRoutes.suggestedPlans,
    );
  }

  Future<void> _openUpcomingWorkouts() {
    final state = _controller.state;
    return _pushHome(
      HomeUpcomingWorkoutsPage(
        plans: state.workouts,
        onOpenWorkout: (workout) => unawaited(_openWorkoutDetails(workout)),
        onOpenCalendar: () => unawaited(_openCalendar()),
      ),
      HomeRoutes.upcomingWorkouts,
    );
  }

  Future<void> _openCalendar() {
    return _pushHome(const HomeCalendarPage(), HomeRoutes.calendar);
  }

  Future<void> _openProgress() {
    return _pushHome(
      HomeProgressPage(
        state: _controller.state,
        xp: widget.xp,
        level: widget.nivel,
      ),
      HomeRoutes.progress,
    );
  }

  Future<void> _openRecentActivity() {
    final state = _controller.state;
    return _pushHome(
      HomeRecentActivityPage(
        history: state.history,
        steps: widget.passos,
        distance: widget.distancia,
        onOpenWorkout: (history) => unawaited(_openWorkoutFromHistory(history)),
        onOpenRunning: () => unawaited(_openRunning()),
        onOpenSteps: () => unawaited(_openSteps()),
      ),
      HomeRoutes.recentActivity,
    );
  }

  Future<void> _openReminders() {
    return _pushHome(
      HomeRemindersPage(
        showDeveloperPlaceholders: _controller.state.isUsingDeveloperData,
      ),
      HomeRoutes.reminders,
    );
  }

  Future<void> _openRecords() {
    return _pushHome(
      HomeRecordsPage(history: _controller.state.history),
      HomeRoutes.records,
    );
  }

  Future<void> _openWeeklyChallenges() {
    final state = _controller.state;
    return _pushHome(
      HomeWeeklyChallengesPage(
        goals: state.goals,
        showDeveloperPlaceholders: state.isUsingDeveloperData,
        onOpenGoals: () => unawaited(_openGoals()),
      ),
      HomeRoutes.weeklyChallenges,
    );
  }

  Future<void> _openDailySummary() {
    return _pushHome(
      HomeDailySummaryPage(
        state: _controller.state,
        steps: widget.passos,
        distance: widget.distancia,
        onOpenOverview: () => unawaited(_openOverview()),
      ),
      HomeRoutes.dailySummary,
    );
  }

  Future<void> _openCustomize() {
    return _pushHome(const HomeCustomizePage(), HomeRoutes.customize);
  }

  Future<void> _openWorkoutDetails(TreinoModel workout) async {
    final shellNavigation = AppShellNavigationScope.maybeOf(context);
    if (shellNavigation != null) {
      await shellNavigation.open<void>(
        AppShellSection.plans,
        AppRoutes.corePlanDetail,
        arguments: workout.id,
      );
      return;
    }

    final journey = CoreJourneyScope.maybeOf(context)?.notifier;
    if (journey == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.corePlanDetail),
        builder: (_) =>
            CoreJourneyPlanDetailPage(controller: journey, plan: workout),
      ),
    );
  }

  Future<void> _openWorkoutFromHistory(HistoricoTreinoModel history) async {
    final match = _controller.state.workouts.where((workout) {
      return workout.nome.toLowerCase() == history.nomeTreino.toLowerCase();
    }).firstOrNull;
    if (match != null) await _openWorkoutDetails(match);
  }

  Future<void> _pushHome(Widget page, String routeName) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }
}
