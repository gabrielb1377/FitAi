import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import 'activity_card.dart';

class ActivitiesHubCards extends StatelessWidget {
  final String runSubtitle;
  final String runDistance;
  final String runPace;
  final String steps;
  final String stepsGoal;
  final double stepsProgress;
  final VoidCallback onOpenRuns;
  final VoidCallback onOpenSteps;

  const ActivitiesHubCards({
    super.key,
    required this.runSubtitle,
    required this.runDistance,
    required this.runPace,
    required this.steps,
    required this.stepsGoal,
    required this.stepsProgress,
    required this.onOpenRuns,
    required this.onOpenSteps,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      ActivityCard(
        title: 'Corridas',
        subtitle: runSubtitle,
        icon: Icons.directions_run_rounded,
        accent: Theme.of(context).colorScheme.tertiary,
        primaryLabel: 'Distancia',
        primaryValue: runDistance,
        secondaryLabel: 'Pace',
        secondaryValue: runPace,
        actionLabel: 'Abrir Corridas',
        onOpen: onOpenRuns,
      ),
      ActivityCard(
        title: 'Passos',
        subtitle: 'Movimentacao do seu dia.',
        icon: Icons.directions_walk_rounded,
        accent: Theme.of(context).colorScheme.primary,
        primaryLabel: 'Passos hoje',
        primaryValue: steps,
        secondaryLabel: 'Meta',
        secondaryValue: stepsGoal,
        progress: stepsProgress,
        actionLabel: 'Abrir Passos',
        onOpen: onOpenSteps,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards.first),
              const SizedBox(width: FitSpacing.s16),
              Expanded(child: cards.last),
            ],
          );
        }
        return Column(
          children: [
            cards.first,
            const SizedBox(height: FitSpacing.s16),
            cards.last,
          ],
        );
      },
    );
  }
}
