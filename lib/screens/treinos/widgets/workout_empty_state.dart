import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class WorkoutEmptyState extends StatelessWidget {
  const WorkoutEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppGradientCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary.withAlpha(190),
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum exercicio neste treino',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Volte ao plano e adicione exercicios para iniciar.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
