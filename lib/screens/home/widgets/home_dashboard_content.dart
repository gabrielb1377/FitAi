import 'package:flutter/material.dart';

import '../../../core/xp/xp_config.dart';
import '../../../design_system/fit_design_system.dart';
import '../../../models/coach_insight_model.dart';
import '../../../models/treino_model.dart';
import '../../../services/ia_evolutiva_service.dart';
import '../../../services/treino_do_dia_service.dart';
import 'home_activity_summary.dart';
import 'home_coach_insight.dart';
import 'home_goal_progress.dart';
import 'home_goal_resolver.dart';
import 'home_greeting_header.dart';
import 'home_primary_action.dart';
import 'home_secondary_content.dart';

/// Composicao visual da Home; recebe apenas dados prontos e callbacks existentes.
class HomeDashboardContent extends StatelessWidget {
  final String name;
  final int level;
  final int unreadNotifications;
  final TreinoDoDiaSelecao selection;
  final bool isLoading;
  final double distance;
  final int steps;
  final int workoutsThisWeek;
  final int weeklyXp;
  final int currentStreak;
  final int rawXp;
  final int recordCount;
  final bool workoutCompletedToday;
  final IaEvolutivaRecomendacao? recommendation;
  final Future<List<CoachInsightModel>> coachInsightsFuture;
  final Future<void> Function(TreinoModel workout) onOpenWorkout;
  final Future<void> Function() onCreateWorkout;
  final Future<void> Function() onGenerateWithAi;
  final VoidCallback? onOpenNotifications;

  const HomeDashboardContent({
    super.key,
    required this.name,
    required this.level,
    required this.unreadNotifications,
    required this.selection,
    required this.isLoading,
    required this.distance,
    required this.steps,
    required this.workoutsThisWeek,
    required this.weeklyXp,
    required this.currentStreak,
    required this.rawXp,
    required this.recordCount,
    required this.workoutCompletedToday,
    required this.recommendation,
    required this.coachInsightsFuture,
    required this.onOpenWorkout,
    required this.onCreateWorkout,
    required this.onGenerateWithAi,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final xpForNextLevel = XpConfig.xpParaProximoNivel(level);
    final xpInLevel = XpConfig.normalizarXp(
      rawXp,
    ).clamp(0, xpForNextLevel).toInt();
    final goal = HomeGoalResolver.nextGoal(
      selection: selection,
      steps: steps,
      weeklyXp: weeklyXp,
    );
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HomeGreetingHeader(
            name: name,
            level: level,
            unreadNotifications: unreadNotifications,
            onOpenNotifications: onOpenNotifications,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            _horizontalPadding(context),
            0,
            _horizontalPadding(context),
            FitSpacing.s64,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              HomePrimaryAction(
                selection: selection,
                isLoading: isLoading,
                onOpenWorkout: onOpenWorkout,
                onCreateWorkout: onCreateWorkout,
                onGenerateWithAi: onGenerateWithAi,
              ),
              const SizedBox(height: FitSpacing.s16),
              HomeActivitySummary(
                storedDistance: distance,
                storedSteps: steps,
                workoutsThisWeek: workoutsThisWeek,
              ),
              const SizedBox(height: FitSpacing.s16),
              HomeCoachInsight(insightsFuture: coachInsightsFuture),
              const SizedBox(height: FitSpacing.s16),
              HomeGoalProgress(
                goal: goal,
                xp: xpInLevel,
                xpForNextLevel: xpForNextLevel,
                level: level,
                currentStreak: currentStreak,
                recordCount: recordCount,
              ),
              const SizedBox(height: FitSpacing.s8),
              HomeSecondaryContent(
                selection: selection,
                recommendation: recommendation,
                isLoading: isLoading,
                workoutCompletedToday: workoutCompletedToday,
                steps: steps,
                workoutsThisWeek: workoutsThisWeek,
                weeklyXp: weeklyXp,
                onOpenWorkout: onOpenWorkout,
                onCreateWorkout: onCreateWorkout,
                onGenerateWithAi: onGenerateWithAi,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return FitSpacing.s20;
  }
}
