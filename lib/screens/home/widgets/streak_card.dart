import 'package:flutter/material.dart';

import '../../../services/streak_service.dart';
import '../../../theme/app_theme.dart';

class StreakCard extends StatelessWidget {
  final StreakResumo streak;
  final bool historicoVazio;

  const StreakCard({
    super.key,
    required this.streak,
    required this.historicoVazio,
  });

  @override
  Widget build(BuildContext context) {
    final subtitulo = historicoVazio
        ? 'Finalize um treino para iniciar sua sequência.'
        : streak.treinouHoje
        ? 'Você treinou hoje. Sequência protegida.'
        : 'Treine hoje para manter ou iniciar uma nova sequência.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: AppGradientCard(
          gradient: AppColors.gradientRun,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(28),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SEQUÊNCIA',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${streak.atual} dia${streak.atual == 1 ? '' : 's'} em sequência',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Melhor',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${streak.melhor}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
