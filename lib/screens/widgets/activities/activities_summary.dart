import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class ActivitiesSummary extends StatelessWidget {
  final String steps;
  final String distance;
  final String activeTime;
  final String workouts;

  const ActivitiesSummary({
    super.key,
    required this.steps,
    required this.distance,
    required this.activeTime,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      FitMetric(
        label: 'Passos hoje',
        value: steps,
        icon: Icons.directions_walk_rounded,
      ),
      FitMetric(
        label: 'Distancia hoje',
        value: distance,
        icon: Icons.route_rounded,
      ),
      FitMetric(
        label: 'Tempo ativo',
        value: activeTime,
        icon: Icons.timer_outlined,
      ),
      FitMetric(
        label: 'Treinos',
        value: workouts,
        icon: Icons.check_circle_outline_rounded,
      ),
    ];
    return FitSection(
      title: 'Resumo de hoje',
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 4 : 2;
          final spacing = FitSpacing.s16;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: FitSpacing.s20,
            children: [
              for (final metric in metrics)
                SizedBox(width: width, child: metric),
            ],
          );
        },
      ),
    );
  }
}
