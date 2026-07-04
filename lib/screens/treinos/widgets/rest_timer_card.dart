import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class RestTimerCard extends StatelessWidget {
  final int seconds;
  final VoidCallback? onSkip;

  const RestTimerCard({super.key, required this.seconds, this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${seconds}s de repouso',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(onPressed: onSkip, child: const Text('Pular')),
        ],
      ),
    );
  }
}
