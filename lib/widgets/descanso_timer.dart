import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DescansoTimer extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final VoidCallback onSkip;
  final VoidCallback onAdd15;
  final VoidCallback onRemove15;

  const DescansoTimer({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.onSkip,
    required this.onAdd15,
    required this.onRemove15,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds <= 0
        ? 0.0
        : (remainingSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descanso',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Respire e prepare a proxima serie',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatar(remainingSeconds),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: onRemove15, child: const Text('-15s')),
              ElevatedButton(onPressed: onSkip, child: const Text('Pular')),
              OutlinedButton(onPressed: onAdd15, child: const Text('+15s')),
            ],
          ),
        ],
      ),
    );
  }

  String _formatar(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final rest = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${rest.toString().padLeft(2, '0')}';
  }
}
