import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../domain/profile_models.dart';

/// Grid responsivo das principais metricas que ja existem localmente.
class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({super.key, required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final useAccessibleList = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final metrics = <_ProfileMetric>[
      _ProfileMetric('Dias ativos', '${stats.activeDays}', FitIcons.streak),
      _ProfileMetric(
        'Planos',
        stats.completedPlans?.toString() ?? '--',
        FitIcons.plans,
        unavailable: stats.completedPlans == null,
        detail: stats.completedPlans == null ? 'Indisponivel' : null,
      ),
      _ProfileMetric('Corridas', '${stats.totalRuns}', FitIcons.running),
      _ProfileMetric('Passos', '${stats.totalSteps}', FitIcons.steps),
      _ProfileMetric(
        'Favoritos',
        '${stats.favoriteExercises}',
        FitIcons.favorite,
      ),
      _ProfileMetric('Treinos', '${stats.completedWorkouts}', FitIcons.workout),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = useAccessibleList
            ? 1
            : FitBreakpoints.isLargeTablet(constraints.maxWidth)
            ? 4
            : FitBreakpoints.isTablet(constraints.maxWidth)
            ? 3
            : 2;
        final gap = FitSpacing.s12;
        final width = (constraints.maxWidth - (gap * (count - 1))) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: useAccessibleList
                    ? FitCard(
                        child: FitHorizontalMetric(
                          label: metric.label,
                          value: metric.value,
                          icon: metric.icon,
                          detail: metric.detail,
                          unavailable: metric.unavailable,
                          color: metric.unavailable
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : null,
                        ),
                      )
                    : FitMetricCard(
                        label: metric.label,
                        value: metric.value,
                        icon: metric.icon,
                        detail: metric.detail,
                        color: metric.unavailable
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileMetric {
  const _ProfileMetric(
    this.label,
    this.value,
    this.icon, {
    this.detail,
    this.unavailable = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final bool unavailable;
}
