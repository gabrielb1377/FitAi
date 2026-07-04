import 'package:flutter/material.dart';

class RestTimerCard extends StatelessWidget {
  final int seconds;
  final int totalSeconds;
  final VoidCallback onSkip;

  const RestTimerCard({
    super.key,
    required this.seconds,
    required this.totalSeconds,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds <= 0
        ? 0.0
        : (seconds / totalSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5C3).withAlpha(70)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor: const Color(0xFF233241),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00E5C3),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descanso',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$seconds segundos restantes',
                  style: TextStyle(
                    color: Colors.white.withAlpha(140),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSkip, child: const Text('Pular')),
        ],
      ),
    );
  }
}
