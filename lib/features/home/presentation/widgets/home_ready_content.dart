import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../states/home_state.dart';
import 'home_coach_insight.dart';
import 'home_dashboard_cards.dart';
import 'home_offline_banner.dart';
import 'home_recent_achievement.dart';
import 'home_week_timeline.dart';

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
    required this.now,
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
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final currentTime = now();
    final workoutsToday = _workoutsToday(currentTime);
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
        HomeTodayWorkoutHero(
          selection: state.selection,
          onOpenWorkout: onOpenWorkout,
          onCreatePlan: onCreatePlan,
          onOpenTodayWorkout: onOpenTodayWorkout,
        ),
        const SizedBox(height: FitSpacing.s24),
        HomeDailyProgressCard(
          xp: xp,
          level: level,
          currentStreak: state.currentStreak,
          steps: steps,
          workoutsToday: workoutsToday,
          primaryGoal: state.primaryGoal,
          onTap: onOpenOverview,
        ),
        const SizedBox(height: FitSpacing.s20),
        HomeDailyMetrics(
          steps: steps,
          distance: distance,
          workouts: workoutsToday,
          weeklyXp: state.weeklyXp,
          runningActive: runningActive,
          onOpenSteps: onOpenSteps,
          onOpenRunning: onOpenRunning,
          onOpenProgress: onOpenProgress,
          onOpenOverview: onOpenOverview,
        ),
        const SizedBox(height: FitSpacing.s32),
        HomeWeekTimeline(
          history: state.history,
          onOpenHistory: onOpenRecentActivity,
          now: now,
        ),
        const SizedBox(height: FitSpacing.s24),
        HomeCoachInsight(
          insights: state.coachInsights,
          onOpenCoach: onOpenCoach,
        ),
        const SizedBox(height: FitSpacing.s16),
        HomeRecentAchievement(
          achievement: state.latestAchievement,
          onOpenAchievements: onOpenAchievements,
        ),
      ],
    );
  }

  int _workoutsToday(DateTime now) {
    return state.history.where((item) {
      final date = item.dataHora.toLocal();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }
}
