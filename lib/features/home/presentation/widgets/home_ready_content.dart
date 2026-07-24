import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../states/home_state.dart';
import 'home_coach_insight.dart';
import 'home_dashboard_cards.dart';
import 'home_offline_banner.dart';
import 'home_recent_achievement.dart';

class HomeReadyContent extends StatelessWidget {
  const HomeReadyContent({
    super.key,
    required this.state,
    required this.steps,
    required this.distance,
    required this.xp,
    required this.level,
    required this.runningActive,
    required this.onRefresh,
    required this.onOpenWorkout,
    required this.onCreatePlan,
    required this.onOpenRunning,
    required this.onOpenSteps,
    required this.onOpenCoach,
    required this.onOpenAchievements,
    required this.onOpenOverview,
    required this.onOpenTodayWorkout,
    required this.onOpenRecentActivity,
    required this.onOpenProgress,
  });

  final HomeState state;
  final int steps;
  final double distance;
  final int xp;
  final int level;
  final bool runningActive;
  final VoidCallback onRefresh;
  final VoidCallback onOpenWorkout;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenRunning;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenCoach;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenOverview;
  final VoidCallback onOpenTodayWorkout;
  final VoidCallback onOpenRecentActivity;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isOffline) ...[
          HomeOfflineBanner(
            lastUpdatedAt: state.lastUpdatedAt,
            onRetry: onRefresh,
          ),
          const SizedBox(height: FitSpacing.s12),
        ],
        if (state.isRefreshing) ...[
          const FitLinearLoading(),
          const SizedBox(height: FitSpacing.s12),
        ],
        HomeXpCard(xp: xp, level: level, onTap: onOpenOverview),
        HomeDailyMetrics(
          steps: steps,
          workouts: _workoutsToday(),
          calories: _caloriesToday(),
          onViewAll: onOpenRecentActivity,
          onOpenSteps: onOpenSteps,
          onOpenProgress: onOpenProgress,
        ),
        HomeTodayCards(
          selection: state.selection,
          runningActive: runningActive,
          runningDistance: distance,
          onOpenWorkout: onOpenWorkout,
          onCreatePlan: onCreatePlan,
          onOpenRunning: onOpenRunning,
          onOpenTodayWorkout: onOpenTodayWorkout,
        ),
        HomeCoachInsight(
          insights: state.coachInsights,
          onOpenCoach: onOpenCoach,
        ),
        HomeRecentAchievement(
          achievement: state.latestAchievement,
          onOpenAchievements: onOpenAchievements,
        ),
      ],
    );
  }

  int _workoutsToday() {
    final now = DateTime.now();
    return state.history.where((item) {
      final date = item.dataHora.toLocal();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int _caloriesToday() {
    final now = DateTime.now();
    return state.history
        .where((item) {
          final date = item.dataHora.toLocal();
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<int>(0, (total, item) => total + item.caloriasEstimadas);
  }
}
