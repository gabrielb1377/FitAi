import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class StepsDailyOverview extends StatelessWidget {
  final int steps;
  final int goal;
  final double progress;
  final String status;
  final String sourceMessage;
  final bool isSyncing;
  final VoidCallback onSync;

  const StepsDailyOverview({
    super.key,
    required this.steps,
    required this.goal,
    required this.progress,
    required this.status,
    required this.sourceMessage,
    required this.isSyncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      elevation: 1,
      title: 'Passos de hoje',
      subtitle: status,
      leading: const Icon(Icons.directions_walk_rounded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$steps', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: FitSpacing.s4),
          Text(
            '$goal passos na meta diaria',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FitSpacing.s20),
          FitProgress(
            value: progress,
            label: 'Progresso',
            trailing: '${(progress * 100).round()}%',
          ),
          const SizedBox(height: FitSpacing.s16),
          FitButton(
            label: 'Sincronizar agora',
            icon: Icons.sync_rounded,
            onPressed: isSyncing ? null : onSync,
            isLoading: isSyncing,
            expand: true,
          ),
          const SizedBox(height: FitSpacing.s12),
          Text(sourceMessage, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
