import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class WorkoutBottomActions extends StatelessWidget {
  final bool canGoBack;
  final bool canGoNext;
  final bool finishedExercise;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback onPrimary;

  const WorkoutBottomActions({
    super.key,
    required this.canGoBack,
    required this.canGoNext,
    required this.finishedExercise,
    required this.onPrimary,
    this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(238),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: canGoBack ? onBack : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: onPrimary,
                child: Text(
                  finishedExercise ? 'Proximo exercicio' : 'Registrar serie',
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
