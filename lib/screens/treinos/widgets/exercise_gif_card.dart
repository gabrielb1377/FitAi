import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/exercicio_gif_viewer.dart';

class ExerciseGifCard extends StatelessWidget {
  final String canonicalExerciseId;
  final String title;
  final VoidCallback? onTap;

  const ExerciseGifCard({
    super.key,
    required this.canonicalExerciseId,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canOpen = canonicalExerciseId.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: canOpen ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(minHeight: 230, maxHeight: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: ExercicioGifImage(
            canonicalExerciseId: canonicalExerciseId,
            titulo: title,
            fit: BoxFit.contain,
            cacheHeight: 620,
            placeholder: _fallback(60),
          ),
        ),
      ),
    );
  }

  Widget _fallback(double size) {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: AppColors.primary,
        size: size,
      ),
    );
  }
}
