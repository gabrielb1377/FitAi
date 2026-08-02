import 'package:flutter/material.dart';

import '../../../services/running_session_service.dart';
import '../../../services/steps_service.dart';
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
    final stepsService = StepsService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([runningSession, stepsService]),
      builder: (context, _) {
        final active = runningSession.hasActiveSession;
        final shownDistance = active ? runningSession.distanceKm : distancia;
        final shownSteps = stepsService.initialized
            ? stepsService.stepsToday
            : passos;
        final bestDay = stepsService.bestDayThisWeek;
        final goal = stepsService.dailyGoal;
        final progress = stepsService.progressToday;
        final estimatedDistanceKm = stepsService.estimatedDistanceKm;
        final estimatedCalories = stepsService.estimatedCalories;

        return Column(
          children: [
            Row(
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
                    value: '$shownSteps',
                    icon: Icons.directions_walk_outlined,
                    iconColor: AppColors.accent1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HomeStepMiniMetric(
                  label: 'Meta',
                  value: '$goal',
                  icon: Icons.flag_rounded,
                ),
                _HomeStepMiniMetric(
                  label: 'Progresso',
                  value: '${(progress * 100).round()}%',
                  icon: Icons.donut_large_rounded,
                ),
                _HomeStepMiniMetric(
                  label: 'Media 7d',
                  value: '${stepsService.weeklyAverage}',
                  icon: Icons.query_stats_rounded,
                ),
                _HomeStepMiniMetric(
                  label: 'Melhor 7d',
                  value: bestDay == null ? '--' : '${bestDay.steps}',
                  icon: Icons.emoji_events_rounded,
                ),
                _HomeStepMiniMetric(
                  label: 'Restantes',
                  value: '${stepsService.remainingSteps}',
                  icon: Icons.trending_up_rounded,
                ),
                if (estimatedDistanceKm != null)
                  _HomeStepMiniMetric(
                    label: 'Distância estimada',
                    value: '${estimatedDistanceKm.toStringAsFixed(2)} km',
                    icon: Icons.route_rounded,
                  ),
                if (estimatedCalories != null)
                  _HomeStepMiniMetric(
                    label: 'Calorias estimadas',
                    value: '${estimatedCalories.toStringAsFixed(0)} kcal',
                    icon: Icons.local_fire_department_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: stepsService.syncing
                    ? null
                    : () => stepsService.syncNow(),
                icon: stepsService.syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: const Text('Sincronizar agora'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeStepMiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HomeStepMiniMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent1, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
