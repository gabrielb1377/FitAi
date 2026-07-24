import '../../../../models/achievement_model.dart';
import '../../../../models/coach_insight_model.dart';
import '../../../../models/fitai_meta_model.dart';
import '../../../../models/fitai_notification_model.dart';
import '../../../../models/historico_treino_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../services/ia_evolutiva_service.dart';
import '../../../../services/treino_do_dia_service.dart';

enum HomeLoadStatus { loading, ready, error }

class HomeState {
  const HomeState({
    required this.status,
    required this.selection,
    this.history = const [],
    this.coachInsights = const [],
    this.goals = const FitaiMetasResumo(metas: []),
    this.achievements = const [],
    this.notifications = const [],
    this.workouts = const [],
    this.recommendation,
    this.workoutsThisWeek = 0,
    this.weeklyXp = 0,
    this.currentStreak = 0,
    this.isOffline = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isUsingDeveloperData = false,
  });

  factory HomeState.initial(TreinoDoDiaSelecao selection) {
    return HomeState(status: HomeLoadStatus.loading, selection: selection);
  }

  final HomeLoadStatus status;
  final TreinoDoDiaSelecao selection;
  final List<HistoricoTreinoModel> history;
  final List<CoachInsightModel> coachInsights;
  final FitaiMetasResumo goals;
  final List<AchievementModel> achievements;
  final List<FitaiNotificationModel> notifications;
  final List<TreinoModel> workouts;
  final IaEvolutivaRecomendacao? recommendation;
  final int workoutsThisWeek;
  final int weeklyXp;
  final int currentStreak;
  final bool isOffline;
  final bool isRefreshing;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isUsingDeveloperData;

  int get unreadNotifications =>
      notifications.where((notification) => !notification.lida).length;

  FitaiMetaModel? get primaryGoal {
    final active = goals.metas.where((goal) {
      return goal.status == FitaiMetaStatus.emAndamento ||
          goal.status == FitaiMetaStatus.pendente;
    }).toList()..sort((a, b) => b.progresso.compareTo(a.progresso));
    if (active.isNotEmpty) return active.first;
    return goals.metas.isEmpty ? null : goals.metas.first;
  }

  AchievementModel? get latestAchievement {
    final unlocked =
        achievements.where((achievement) => achievement.desbloqueada).toList()
          ..sort(
            (a, b) => (b.data ?? DateTime(0)).compareTo(a.data ?? DateTime(0)),
          );
    return unlocked.isEmpty ? null : unlocked.first;
  }

  bool get hasLocalContent =>
      selection.treino != null ||
      history.isNotEmpty ||
      coachInsights.isNotEmpty ||
      goals.metas.isNotEmpty ||
      achievements.isNotEmpty ||
      notifications.isNotEmpty ||
      workouts.isNotEmpty;

  HomeState copyWith({
    HomeLoadStatus? status,
    TreinoDoDiaSelecao? selection,
    List<HistoricoTreinoModel>? history,
    List<CoachInsightModel>? coachInsights,
    FitaiMetasResumo? goals,
    List<AchievementModel>? achievements,
    List<FitaiNotificationModel>? notifications,
    List<TreinoModel>? workouts,
    IaEvolutivaRecomendacao? recommendation,
    int? workoutsThisWeek,
    int? weeklyXp,
    int? currentStreak,
    bool? isOffline,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdatedAt,
    bool? isUsingDeveloperData,
  }) {
    return HomeState(
      status: status ?? this.status,
      selection: selection ?? this.selection,
      history: history ?? this.history,
      coachInsights: coachInsights ?? this.coachInsights,
      goals: goals ?? this.goals,
      achievements: achievements ?? this.achievements,
      notifications: notifications ?? this.notifications,
      workouts: workouts ?? this.workouts,
      recommendation: recommendation ?? this.recommendation,
      workoutsThisWeek: workoutsThisWeek ?? this.workoutsThisWeek,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      currentStreak: currentStreak ?? this.currentStreak,
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isUsingDeveloperData: isUsingDeveloperData ?? this.isUsingDeveloperData,
    );
  }
}
