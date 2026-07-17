import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../states/home_state.dart';
import 'home_coach_insight.dart';
import 'home_goal_progress.dart';
import 'home_metrics_summary.dart';
import 'home_offline_banner.dart';
import 'home_quick_actions.dart';
import 'home_recent_achievement.dart';
import 'home_workout_hero.dart';

class HomeReadyContent extends StatelessWidget {
  const HomeReadyContent({
    super.key,
    required this.state,
    required this.steps,
    required this.distance,
    required this.xp,
    required this.runningActive,
    required this.runningSeconds,
    required this.onRefresh,
    required this.onOpenWorkout,
    required this.onCreatePlan,
    required this.onOpenLibrary,
    required this.onOpenRunning,
    required this.onOpenSteps,
    required this.onOpenCoach,
    required this.onOpenGoals,
    required this.onOpenAchievements,
  });

  final HomeState state;
  final int steps;
  final double distance;
  final int xp;
  final bool runningActive;
  final int runningSeconds;
  final VoidCallback onRefresh;
  final VoidCallback onOpenWorkout;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenRunning;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenCoach;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenAchievements;

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
          const SizedBox(height: FitSpacing.s16),
        ],
        if (state.isRefreshing) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: FitSpacing.s12),
        ],
        HomeWorkoutHero(
          selection: state.selection,
          runningActive: runningActive,
          runningDistance: distance,
          runningSeconds: runningSeconds,
          onOpenWorkout: onOpenWorkout,
          onCreatePlan: onCreatePlan,
          onOpenRunning: onOpenRunning,
        ),
        HomeMetricsSummary(
          steps: steps,
          workoutsThisWeek: state.workoutsThisWeek,
          distance: distance,
          xp: xp,
        ),
        HomeCoachInsight(
          insights: state.coachInsights,
          onOpenCoach: onOpenCoach,
        ),
        HomeGoalProgress(goal: state.primaryGoal, onOpenGoals: onOpenGoals),
        HomeQuickActions(
          onCreatePlan: onCreatePlan,
          onOpenLibrary: onOpenLibrary,
          onOpenRunning: onOpenRunning,
          onOpenSteps: onOpenSteps,
        ),
        HomeRecentAchievement(
          achievement: state.latestAchievement,
          onOpenAchievements: onOpenAchievements,
        ),
      ],
    );
  }
}
