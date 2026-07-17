import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeMetricsSummary extends StatelessWidget {
  const HomeMetricsSummary({
    super.key,
    required this.steps,
    required this.workoutsThisWeek,
    required this.distance,
    required this.xp,
  });

  final int steps;
  final int workoutsThisWeek;
  final double distance;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return FitSection(
      title: 'Resumo',
      child: Container(
        padding: const EdgeInsets.all(FitSpacing.s16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: FitRadius.largeBorder,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 500 ? 2 : 4;
            final width =
                (constraints.maxWidth - (columns - 1) * FitSpacing.s16) /
                columns;
            return FitMetricRow(
              runSpacing: FitSpacing.s20,
              children: [
                SizedBox(
                  width: width,
                  child: FitMetric(
                    label: 'Passos',
                    value: '$steps',
                    icon: Icons.directions_walk_rounded,
                    color: FitColors.steps,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FitMetric(
                    label: 'Treinos',
                    value: '$workoutsThisWeek',
                    icon: Icons.fitness_center_rounded,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FitMetric(
                    label: 'Corridas',
                    value: distance.toStringAsFixed(2),
                    unit: 'km',
                    icon: Icons.directions_run_rounded,
                    color: FitColors.running,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FitMetric(
                    label: 'XP',
                    value: '$xp',
                    icon: Icons.bolt_rounded,
                    color: FitColors.achievement,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
