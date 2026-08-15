import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class ActivitiesSummary extends StatelessWidget {
  final String steps;
  final String distance;
  final String activeTime;

  const ActivitiesSummary({
    super.key,
    required this.steps,
    required this.distance,
    required this.activeTime,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = <FitMetricRailItem>[
      FitMetricRailItem(
        label: 'Passos hoje',
        value: steps,
        icon: Icons.directions_walk_rounded,
      ),
      FitMetricRailItem(
        label: 'Distancia hoje',
        value: distance,
        icon: Icons.route_rounded,
      ),
      FitMetricRailItem(
        label: 'Tempo ativo',
        value: activeTime,
        icon: Icons.timer_outlined,
      ),
    ];
    return FitSection(
      title: 'Resumo de hoje',
      padding: EdgeInsets.zero,
      child: FitMetricRail(items: metrics),
    );
  }
}
