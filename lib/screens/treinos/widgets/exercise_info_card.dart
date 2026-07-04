import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ExerciseInfoCard extends StatelessWidget {
  final String name;
  final String recommendation;

  const ExerciseInfoCard({
    super.key,
    required this.name,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.04,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          recommendation,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
