import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../services/running_session_service.dart';
import '../../../services/steps_service.dart';

/// Resumo compacto das atividades que mantem os detalhes de passos acessiveis.
class HomeActivitySummary extends StatelessWidget {
  final double storedDistance;
  final int storedSteps;
  final int workoutsThisWeek;

  const HomeActivitySummary({
    super.key,
    required this.storedDistance,
    required this.storedSteps,
    required this.workoutsThisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final running = RunningSessionService.instance;
    final steps = StepsService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([running, steps]),
      builder: (context, _) {
        final distance = running.hasActiveSession
            ? running.distanceKm
            : storedDistance;
        final shownSteps = steps.initialized ? steps.stepsToday : storedSteps;
        return FitSection(
          title: 'Atividade de hoje',
          child: FitCard(
            variant: FitCardVariant.outlined,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 420 ? 2 : 3;
                    final width =
                        (constraints.maxWidth -
                            (columns - 1) * FitSpacing.s16) /
                        columns;
                    return Wrap(
                      spacing: FitSpacing.s16,
                      runSpacing: FitSpacing.s16,
                      children: [
                        SizedBox(
                          width: width,
                          child: FitMetric(
                            label: 'Passos',
                            value: '$shownSteps',
                            icon: Icons.directions_walk_rounded,
                            color: context.colors.secondary,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: FitMetric(
                            label: 'Treinos semana',
                            value: '$workoutsThisWeek',
                            icon: Icons.fitness_center_rounded,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: FitMetric(
                            label: running.hasActiveSession
                                ? 'Corrida ativa'
                                : 'Distancia',
                            value: '${distance.toStringAsFixed(2)} km',
                            icon: Icons.route_outlined,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: FitSpacing.s20),
                FitProgress(
                  value: steps.initialized
                      ? steps.progressToday
                      : (shownSteps / 8000),
                  label: 'Meta de passos',
                  trailing:
                      '$shownSteps/${steps.initialized ? steps.dailyGoal : 8000}',
                ),
                const SizedBox(height: FitSpacing.s8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Detalhes dos passos'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Restantes: ${steps.remainingSteps}  •  Media 7d: ${steps.weeklyAverage}  •  Melhor 7d: ${steps.bestDayThisWeek?.steps ?? '--'}',
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: FitSpacing.s8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: steps.syncing
                            ? null
                            : () => steps.syncNow(requestPermission: true),
                        icon: steps.syncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: const Text('Sincronizar agora'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
