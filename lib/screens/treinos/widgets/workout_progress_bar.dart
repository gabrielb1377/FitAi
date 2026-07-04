import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class WorkoutProgressBar extends StatelessWidget {
  final double progress;

  const WorkoutProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 260),
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: 6,
            color: AppColors.primary,
            backgroundColor: Colors.white.withAlpha(20),
          );
        },
      ),
    );
  }
}
