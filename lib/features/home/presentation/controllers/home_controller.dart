import 'package:flutter/foundation.dart';

import '../../../../core/config/dev_data.dart';
import '../../../../core/config/dev_fixtures.dart';
import '../../../../models/achievement_model.dart';
import '../../../../models/coach_insight_model.dart';
import '../../../../models/fitai_meta_model.dart';
import '../../../../models/fitai_notification_model.dart';
import '../../../../models/historico_treino_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../services/achievement_service.dart';
import '../../../../services/coach_insight_service.dart';
import '../../../../services/ia_evolutiva_service.dart';
import '../../../../services/metas_service.dart';
import '../../../../services/network_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/streak_service.dart';
import '../../../../services/treino_do_dia_service.dart';
import '../../data/home_workout_history_reader.dart';
import '../states/home_state.dart';

typedef HomeHistoryLoader = Future<List<HistoricoTreinoModel>> Function();
typedef HomeCoachLoader = Future<List<CoachInsightModel>> Function();
typedef HomeGoalsLoader = Future<FitaiMetasResumo> Function();
typedef HomeAchievementsLoader = Future<List<AchievementModel>> Function();
typedef HomeNotificationsLoader =
    Future<List<FitaiNotificationModel>> Function();
typedef HomeNetworkCheck = Future<bool> Function();
typedef HomeWorkoutsLoader = Future<List<TreinoModel>> Function();
typedef HomeDevDataLoader = Future<DevRuntimeData> Function();

class HomeController extends ChangeNotifier {
  HomeController({
    HomeHistoryLoader? historyLoader,
    HomeCoachLoader? coachLoader,
    HomeGoalsLoader? goalsLoader,
    HomeAchievementsLoader? achievementsLoader,
    HomeNotificationsLoader? notificationsLoader,
    HomeNetworkCheck? networkCheck,
    HomeWorkoutsLoader? workoutsLoader,
    HomeDevDataLoader? devDataLoader,
  }) : _historyLoader = historyLoader ?? HomeWorkoutHistoryReader().load,
       _coachLoader =
           coachLoader ?? const CoachInsightService().gerarInsightsGerais,
       _goalsLoader = goalsLoader ?? const MetasService().carregarMetas,
       _achievementsLoader =
           achievementsLoader ?? const AchievementService().carregarConquistas,
       _notificationsLoader =
           notificationsLoader ??
           const NotificationService().carregarNotificacoes,
       _networkCheck = networkCheck ?? NetworkService().isBackendAvailable,
       _workoutsLoader = workoutsLoader ?? StorageService.carregarTreinos,
       _devDataLoader = devDataLoader ?? const DevDataService().resolve,
       _state = HomeState.initial(
         const TreinoDoDiaService().selecionarTreinoDoDiaDetalhado(
           const [],
           const [],
         ),
       );

  final HomeHistoryLoader _historyLoader;
  final HomeCoachLoader _coachLoader;
  final HomeGoalsLoader _goalsLoader;
  final HomeAchievementsLoader _achievementsLoader;
  final HomeNotificationsLoader _notificationsLoader;
  final HomeNetworkCheck _networkCheck;
  final HomeWorkoutsLoader _workoutsLoader;
  final HomeDevDataLoader _devDataLoader;
  HomeState _state;
  bool _loading = false;

  HomeState get state => _state;

  Future<void> load({
    required List<TreinoModel> workouts,
    required int xp,
    required int level,
  }) {
    return _load(workouts: workouts, xp: xp, level: level, refresh: false);
  }

  Future<void> refresh({
    required List<TreinoModel> workouts,
    required int xp,
    required int level,
  }) {
    return _load(workouts: workouts, xp: xp, level: level, refresh: true);
  }

  Future<void> _load({
    required List<TreinoModel> workouts,
    required int xp,
    required int level,
    required bool refresh,
  }) async {
    if (_loading) return;
    _loading = true;
    _state = _state.copyWith(
      status: refresh && _state.hasLocalContent
          ? HomeLoadStatus.ready
          : HomeLoadStatus.loading,
      isRefreshing: refresh,
      clearError: true,
    );
    notifyListeners();

    try {
      final history = await _historyLoader();
      final devData = await _devDataLoader();
      final availableWorkouts = await _resolveWorkouts(workouts);
      if (devData.useFixtureHome) {
        _applyFixtures(devData, availableWorkouts, history);
        return;
      }
      final recommendationFuture = IaEvolutivaService.instance
          .gerarRecomendacao(
            treinosDisponiveis: availableWorkouts,
            historico: history,
            xpAtual: xp,
            nivelAtual: level,
          );
      final results = await Future.wait<Object>([
        _coachLoader(),
        _goalsLoader(),
        _achievementsLoader(),
        _networkCheck(),
        recommendationFuture,
      ]);
      final notifications = await _notificationsLoader();
      final streakService = const StreakService();
      final selection = const TreinoDoDiaService()
          .selecionarTreinoDoDiaDetalhado(availableWorkouts, history);

      _state = HomeState(
        status: HomeLoadStatus.ready,
        selection: selection,
        history: history,
        coachInsights: results[0] as List<CoachInsightModel>,
        goals: results[1] as FitaiMetasResumo,
        achievements: results[2] as List<AchievementModel>,
        notifications: notifications,
        workouts: availableWorkouts,
        recommendation: results[4] as IaEvolutivaRecomendacao,
        workoutsThisWeek: streakService.treinosNaSemana(history),
        weeklyXp: streakService.xpTreinosNaSemana(history),
        currentStreak: streakService.calcularStreak(history).atual,
        isOffline: !(results[3] as bool),
        lastUpdatedAt: DateTime.now(),
        isUsingDeveloperData: false,
      );
    } on Object catch (error) {
      _debugLog('Falha ao carregar Home: $error');
      _state = _state.copyWith(
        status: _state.hasLocalContent
            ? HomeLoadStatus.ready
            : HomeLoadStatus.error,
        isOffline: true,
        isRefreshing: false,
        errorMessage: 'Nao foi possivel atualizar a Home agora.',
      );
    } finally {
      _loading = false;
      if (_state.isRefreshing) {
        _state = _state.copyWith(isRefreshing: false);
      }
      notifyListeners();
    }
  }

  Future<List<TreinoModel>> _resolveWorkouts(List<TreinoModel> workouts) async {
    final merged = <String, TreinoModel>{
      for (final workout in workouts) workout.id: workout,
    };
    if (merged.isEmpty) {
      for (final workout in await _workoutsLoader()) {
        merged[workout.id] = workout;
      }
    }
    return merged.values.toList(growable: false);
  }

  void _applyFixtures(
    DevRuntimeData devData,
    List<TreinoModel> availableWorkouts,
    List<HistoricoTreinoModel> existingHistory,
  ) {
    final useFakeWorkout = devData.useFakeWorkout && availableWorkouts.isEmpty;
    final workouts = useFakeWorkout ? DevFixtures.workouts : availableWorkouts;
    final history = existingHistory.isNotEmpty
        ? existingHistory
        : useFakeWorkout
        ? DevFixtures.workoutHistory
        : existingHistory;
    final selection = const TreinoDoDiaService().selecionarTreinoDoDiaDetalhado(
      workouts,
      history,
    );
    final streakService = const StreakService();
    final selectedWorkout = selection.treino;

    _state = HomeState(
      status: HomeLoadStatus.ready,
      selection: selection,
      history: history,
      coachInsights: devData.useFakeCoach
          ? DevFixtures.coachInsights
          : const [],
      goals: devData.useFakeGoals
          ? DevFixtures.goals
          : const FitaiMetasResumo(metas: []),
      achievements: devData.useFakeAchievements
          ? DevFixtures.achievements
          : const [],
      notifications: devData.useFakeNotifications
          ? DevFixtures.notifications
          : const [],
      workouts: workouts,
      recommendation: selectedWorkout == null || !devData.useFakeCoach
          ? null
          : DevFixtures.recommendation(selectedWorkout),
      workoutsThisWeek: streakService.treinosNaSemana(history),
      weeklyXp: streakService.xpTreinosNaSemana(history),
      currentStreak: streakService.calcularStreak(history).atual,
      lastUpdatedAt: DateTime.now(),
      isUsingDeveloperData: true,
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[HomeController] $message');
  }
}
