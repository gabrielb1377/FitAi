import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class RestTimerWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final int totalSeconds;
  final int remainingSeconds;
  final bool showNextButton;
  final VoidCallback onSkip;
  final VoidCallback? onNext;

  const RestTimerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.showNextButton,
    required this.onSkip,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds <= 0
        ? 1.0
        : ((totalSeconds - remainingSeconds) / totalSeconds).clamp(0.0, 1.0);
    final finished = remainingSeconds <= 0;

    return AppGradientCard(
      gradient: finished ? AppColors.gradientPrimary : AppColors.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: finished
                      ? Colors.black.withAlpha(24)
                      : AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  finished
                      ? Icons.check_rounded
                      : Icons.hourglass_bottom_rounded,
                  color: finished ? Colors.black : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finished ? "Descanso concluido" : title,
                      style: TextStyle(
                        color: finished ? Colors.black : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: finished ? Colors.black87 : Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _formatTime(remainingSeconds),
              style: TextStyle(
                color: finished ? Colors.black : Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: finished
                  ? Colors.black26
                  : AppColors.surfaceVariant,
              color: finished ? Colors.black : AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          if (finished && showNextButton && onNext != null)
            ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text("Proximo Exercicio"),
            )
          else
            OutlinedButton.icon(
              onPressed: onSkip,
              icon: const Icon(Icons.double_arrow_rounded),
              label: const Text("Pular descanso"),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = safeSeconds ~/ 60;
    final rest = safeSeconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}";
  }
}
