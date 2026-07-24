import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/design_system/fit_design_system.dart';
import 'package:fitai/features/home/presentation/pages/pages.dart';
import 'package:fitai/features/home/presentation/states/home_state.dart';
import 'package:fitai/features/home/presentation/widgets/home_dashboard_content.dart';
import 'package:fitai/models/fitai_recorde_model.dart';
import 'package:fitai/services/agenda_treinos_service.dart';
import 'package:fitai/services/treino_do_dia_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';

const homeGoldenRootKey = ValueKey('home-golden-root');

Widget homeTestHost(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: RepaintBoundary(key: homeGoldenRootKey, child: child),
  );
}

Map<String, Widget Function()> homeOfficialScreens() {
  final state = homeFixtureState();
  final workout = DevFixtures.workouts.first;
  return {
    'HOME-001': () => Scaffold(
      backgroundColor: FitColors.background,
      body: HomeDashboardContent(
        state: state,
        name: DevFixtures.user.name,
        level: DevFixtures.user.level,
        xp: DevFixtures.user.xp,
        steps: DevFixtures.steps,
        distance: DevFixtures.running.distanceKm,
        runningActive: false,
        runningSeconds: DevFixtures.running.elapsedSeconds,
        onRefresh: () async {},
        onOpenWorkout: () {},
        onCreatePlan: () {},
        onOpenLibrary: () {},
        onOpenRunning: () {},
        onOpenSteps: () {},
        onOpenCoach: () {},
        onOpenGoals: () {},
        onOpenAchievements: () {},
        onOpenNotifications: () {},
        onCustomize: () {},
        onOpenOverview: () {},
        onOpenTodayWorkout: () {},
        onOpenRecentActivity: () {},
        onOpenProgress: () {},
      ),
    ),
    'HOME-002': () => HomeOverviewPage(
      state: state,
      xp: DevFixtures.user.xp,
      level: DevFixtures.user.level,
      onOpenGoals: () {},
      onOpenProgress: () {},
      onOpenRecords: () {},
      onOpenChallenges: () {},
    ),
    'HOME-003': () => HomeTodayWorkoutPage(
      workout: workout,
      insight: state.coachInsights.first,
      onStart: () {},
      onViewExercises: () {},
      onCreatePlan: () {},
      onOpenSchedule: () {},
      onOpenSuggestedPlans: () {},
    ),
    'HOME-004': () => HomeSuggestedPlansPage(
      plans: state.workouts,
      onOpenPlan: (_) {},
      onExploreAll: () {},
    ),
    'HOME-005': () => HomeUpcomingWorkoutsPage(
      plans: state.workouts,
      onOpenWorkout: (_) {},
      onOpenCalendar: () {},
    ),
    'HOME-006': () => HomeAchievementsPage(
      initialAchievements: state.achievements,
      level: DevFixtures.user.level,
      xp: DevFixtures.user.xp,
      streak: state.currentStreak,
    ),
    'HOME-007': () => HomeCalendarPage(
      initialDate: homeFixtureDate,
      loader: (month) async => homeFixtureAgenda(month),
    ),
    'HOME-008': () => HomeProgressPage(
      state: state,
      xp: DevFixtures.user.xp,
      level: DevFixtures.user.level,
    ),
    'HOME-009': () => HomeRecentActivityPage(
      history: state.history,
      steps: DevFixtures.steps,
      distance: DevFixtures.running.distanceKm,
      onOpenWorkout: (_) {},
      onOpenRunning: () {},
      onOpenSteps: () {},
    ),
    'HOME-010': () => const HomeRemindersPage(showDeveloperPlaceholders: true),
    'HOME-011': () => HomeGoalsPage(initialGoals: state.goals),
    'HOME-012': () =>
        HomeNotificationsPage(initialNotifications: state.notifications),
    'HOME-013': () => HomeRecordsPage(
      history: state.history,
      loader: () async => [homeFixtureRecord()],
    ),
    'HOME-014': () => HomeWeeklyChallengesPage(
      goals: state.goals,
      showDeveloperPlaceholders: true,
      onOpenGoals: () {},
    ),
    'HOME-015': () => HomeCoachPage(
      initialInsights: state.coachInsights,
      recommendation: state.recommendation,
      onOpenDailySummary: () {},
    ),
    'HOME-016': () => HomeDailySummaryPage(
      state: state,
      steps: DevFixtures.steps,
      distance: DevFixtures.running.distanceKm,
      onOpenOverview: () {},
    ),
    'HOME-017': () => const HomeCustomizePage(),
  };
}

HomeState homeFixtureState() {
  final workouts = DevFixtures.workouts;
  final selection = const TreinoDoDiaService().selecionarTreinoDoDiaDetalhado(
    workouts,
    DevFixtures.workoutHistory,
  );
  return HomeState(
    status: HomeLoadStatus.ready,
    selection: selection,
    history: DevFixtures.workoutHistory,
    coachInsights: DevFixtures.coachInsights,
    goals: DevFixtures.goals,
    achievements: DevFixtures.achievements,
    notifications: DevFixtures.notifications,
    workouts: workouts,
    recommendation: DevFixtures.recommendation(workouts.first),
    workoutsThisWeek: 2,
    weeklyXp: 360,
    currentStreak: 7,
    isUsingDeveloperData: true,
  );
}

final homeFixtureDate = DateTime(2026, 7, 12);

AgendaTreinosMes homeFixtureAgenda([DateTime? month]) {
  final now = month ?? homeFixtureDate;
  final days = List.generate(
    DateTime(now.year, now.month + 1, 0).day,
    (index) => AgendaDiaTreino(
      data: DateTime(now.year, now.month, index + 1),
      status: index % 3 == 0
          ? AgendaTreinoStatus.programado
          : AgendaTreinoStatus.descanso,
      planoId: index % 3 == 0 ? 'dev-upper-a' : '',
      planoNome: index % 3 == 0 ? 'Upper A' : '',
      diaNome: index % 3 == 0 ? 'Peito e Costas' : '',
      quantidadeExercicios: index % 3 == 0 ? 6 : 0,
      tempoPrevisto: index % 3 == 0 ? 45 : 0,
    ),
  );
  return AgendaTreinosMes(
    mes: DateTime(now.year, now.month),
    dias: days,
    resumo: const AgendaResumoTreinos(
      sequenciaAtual: 7,
      maiorSequencia: 12,
      treinosMes: 8,
      diasPerdidos: 1,
    ),
    sugestao: null,
  );
}

FitaiRecordeModel homeFixtureRecord() {
  return FitaiRecordeModel(
    id: 'record-1',
    titulo: 'Maior volume',
    descricao: 'Melhor volume em um treino',
    categoria: FitaiRecordeCategoria.volume,
    valor: 5240,
    unidade: 'kg',
    data: homeFixtureDate,
    treinoNome: 'Upper A',
  );
}
