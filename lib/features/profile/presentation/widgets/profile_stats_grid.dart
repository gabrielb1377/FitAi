import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../domain/profile_models.dart';

/// Faixa responsiva das metricas agregadas pelas fontes canonicas do Perfil.
class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({super.key, required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return FitMetricRail(
      items: [
        FitMetricRailItem(
          label: 'Dias ativos',
          value: '${stats.activeDays}',
          icon: FitIcons.streak,
        ),
        FitMetricRailItem(
          label: 'Planos',
          value: stats.completedPlans?.toString() ?? '--',
          icon: FitIcons.plans,
        ),
        FitMetricRailItem(
          label: 'Corridas',
          value: '${stats.totalRuns}',
          icon: FitIcons.running,
          color: context.fitColors.running,
        ),
        FitMetricRailItem(
          label: 'Passos',
          value: '${stats.totalSteps}',
          icon: FitIcons.steps,
          color: context.fitColors.steps,
        ),
        FitMetricRailItem(
          label: 'Favoritos',
          value: '${stats.favoriteExercises}',
          icon: FitIcons.favorite,
        ),
        FitMetricRailItem(
          label: 'Treinos',
          value: '${stats.completedWorkouts}',
          icon: FitIcons.workout,
        ),
      ],
    );
  }
}
