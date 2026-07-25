import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/treinos/controllers/plan_day_data.dart';
import '../../../../screens/treinos/treino_em_andamento_page.dart';
import '../../../../screens/treinos/workout_day_page.dart';

/// WORK-001. Prévia de um treino pertencente a um plano.
///
/// A página deriva apenas métricas presentes no plano e não cria uma sessão.
class WorkoutPreviewPage extends StatelessWidget {
  const WorkoutPreviewPage({super.key, required this.plan, required this.day});

  final TreinoModel plan;
  final PlanDayData day;

  @override
  Widget build(BuildContext context) {
    final exercises = day.workout.exercicios;
    final sets = exercises.fold<int>(
      0,
      (total, exercise) => total + _setsFor(exercise),
    );
    final minutes = plan.tempoEstimado <= 0 ? 45 : plan.tempoEstimado;

    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s16,
                FitSpacing.s4,
                FitSpacing.s16,
                FitSpacing.s32,
              ),
              children: [
                FitHeader(
                  title: 'Prévia do treino',
                  showBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: FitSpacing.s20),
                Text(
                  day.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  day.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: FitColors.textSecondary,
                  ),
                ),
                const SizedBox(height: FitSpacing.s20),
                FitWorkoutSummaryCard(
                  title: plan.nome,
                  subtitle: plan.objetivo,
                  metrics: [
                    FitMetricData(
                      label: 'Exercícios',
                      value: '${exercises.length}',
                      icon: Icons.fitness_center_rounded,
                    ),
                    FitMetricData(
                      label: 'Séries',
                      value: '$sets',
                      icon: Icons.repeat_rounded,
                    ),
                    FitMetricData(
                      label: 'Duração',
                      value: '$minutes',
                      unit: 'min',
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: FitSpacing.s16),
                FitWorkoutCoachBubble(
                  message:
                      'Priorize técnica e controle. Ajuste a carga apenas quando necessário.',
                ),
                const SizedBox(height: FitSpacing.s24),
                FitSection(
                  title: 'Exercícios do treino',
                  child: exercises.isEmpty
                      ? const FitEmptyState(
                          icon: Icons.fitness_center_rounded,
                          title: 'Treino sem exercícios',
                          description:
                              'Adicione exercícios ao plano antes de iniciar.',
                        )
                      : Column(
                          children: [
                            for (
                              var index = 0;
                              index < exercises.length;
                              index++
                            ) ...[
                              _ExercisePreviewRow(
                                exercise: exercises[index],
                                index: index,
                              ),
                              if (index < exercises.length - 1)
                                const SizedBox(height: FitSpacing.s8),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: FitSpacing.s24),
                FitButton(
                  label: 'Iniciar treino',
                  leadingIcon: Icons.play_arrow_rounded,
                  expand: true,
                  onPressed: exercises.isEmpty
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => TreinoEmAndamentoPage(
                              treino: day.workout,
                              nomeDia: day.label,
                              grupoDia: day.title,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: FitSpacing.s12),
                FitButton(
                  label: 'Ver lista de exercícios',
                  leadingIcon: Icons.format_list_bulleted_rounded,
                  expand: true,
                  variant: FitButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => WorkoutDayPage(plan: plan, day: day),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _setsFor(ExercicioModel exercise) =>
      exercise.series <= 0 ? 3 : exercise.series;
}

class _ExercisePreviewRow extends StatelessWidget {
  const _ExercisePreviewRow({required this.exercise, required this.index});

  final ExercicioModel exercise;
  final int index;

  @override
  Widget build(BuildContext context) {
    final sets = exercise.series <= 0 ? 3 : exercise.series;
    final reps = exercise.repeticoes.trim().isEmpty
        ? '8-12'
        : exercise.repeticoes;
    return FitCard(
      variant: FitCardVariant.outlined,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: FitColors.primary,
            foregroundColor: FitColors.onPrimary,
            child: Text('${index + 1}'),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.nome,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  '$sets séries · $reps reps',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
