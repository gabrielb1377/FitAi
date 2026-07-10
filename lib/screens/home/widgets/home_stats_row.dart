import 'package:flutter/material.dart';

import '../../../services/running_session_service.dart';
import '../../../theme/app_theme.dart';

class HomeStatsRow extends StatelessWidget {
  final double distancia;
  final int passos;

  const HomeStatsRow({
    super.key,
    required this.distancia,
    required this.passos,
  });

  @override
  Widget build(BuildContext context) {
    final runningSession = RunningSessionService.instance;

    return AnimatedBuilder(
      animation: runningSession,
      builder: (context, _) {
        final active = runningSession.hasActiveSession;
        final shownDistance = active ? runningSession.distanceKm : distancia;

        return Row(
          children: [
            Expanded(
              child: AppStatChip(
                label: active ? 'Corrida ativa' : 'Distancia',
                value: '${shownDistance.toStringAsFixed(2)} km',
                icon: active
                    ? Icons.directions_run_rounded
                    : Icons.route_outlined,
                iconColor: active ? AppColors.accent2 : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppStatChip(
                label: 'Passos',
                value: '$passos',
                icon: Icons.directions_walk_outlined,
                iconColor: AppColors.accent1,
              ),
            ),
          ],
        );
      },
    );
  }
}
