import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import '../controllers/plan_day_data.dart';
import '../controllers/plan_progress_snapshot.dart';
import '../workout_day_page.dart';
import 'official_plan_ui.dart';

class OfficialPlanProgressPage extends StatelessWidget {
  const OfficialPlanProgressPage({
    super.key,
    required this.plan,
    required this.progress,
  });

  final TreinoModel plan;
  final PlanProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final days = buildPlanDays(plan);
    final total = days.isEmpty ? 1 : days.length;
    final completed = progress.weeklyCompletedWorkouts.clamp(0, total);
    final progressValue = total <= 0 ? 0.0 : completed / total;
    return Scaffold(
      backgroundColor: OfficialPlanColors.background,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: OfficialPlanPrimaryButton(
          label: 'Continuar Plano',
          onPressed: days.isEmpty ? null : () => _openNext(context, days),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: OfficialPlanViewport(
          child: Column(
            children: [
              OfficialPlanHeader(
                title: plan.nome,
                onBack: () => Navigator.maybePop(context),
                trailing: OfficialPlanIconButton(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'Mais opções',
                  onPressed: () {},
                ),
              ),
              OfficialPlanTabs(
                labels: const ['Treinos', 'Progresso'],
                selectedIndex: 1,
                onSelected: (index) {
                  if (index == 0) Navigator.maybePop(context);
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  children: [
                    Text(
                      'Progresso geral',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: OfficialPlanColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OfficialPlanProgressRing(
                          value: progressValue,
                          size: 68,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$completed de $total treinos concluídos',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progressValue,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(99),
                                color: OfficialPlanColors.green,
                                backgroundColor: OfficialPlanColors.border,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Estatísticas',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: OfficialPlanColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _stat(context, 'Treinos', '$completed'),
                        const SizedBox(width: 8),
                        _stat(
                          context,
                          'Exercícios',
                          '${plan.exercicios.length}/24',
                        ),
                        const SizedBox(width: 8),
                        _stat(context, 'Volume (kg)', _volumeLabel()),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Últimos treinos',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: OfficialPlanColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OfficialPlanSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: List.generate(days.length, (index) {
                          final day = days[index];
                          final done = index < completed;
                          return Container(
                            constraints: const BoxConstraints(minHeight: 50),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: index == days.length - 1
                                ? null
                                : const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: OfficialPlanColors.border,
                                      ),
                                    ),
                                  ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${day.label} - ${day.title}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: OfficialPlanColors.text,
                                            ),
                                      ),
                                      Text(
                                        '${day.workout.exercicios.length} exercícios',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  done
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: done
                                      ? OfficialPlanColors.green
                                      : OfficialPlanColors.textMuted,
                                  size: 22,
                                ),
                              ],
                            ),
                          );
                        }),
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

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: OfficialPlanSurface(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: OfficialPlanColors.text),
            ),
          ],
        ),
      ),
    );
  }

  String _volumeLabel() {
    final volume = progress.latestWorkout?.volumeTotal ?? 0;
    if (volume <= 0) return '0';
    return volume.round().toString();
  }

  void _openNext(BuildContext context, List<PlanDayData> days) {
    final index = progress.nextDayIndex.clamp(0, days.length - 1);
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayPage(plan: plan, day: days[index]),
      ),
    );
  }
}
