import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../features/core_journey/presentation/unified_workout_navigation.dart';
import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import 'controllers/plan_day_data.dart';
import 'exercicio_detalhe_page.dart';
import 'treino_navigation.dart';
import 'widgets/plans/plan_media.dart';

class WorkoutDayPage extends StatelessWidget {
  const WorkoutDayPage({
    super.key,
    required this.plan,
    required this.day,
    this.weekNumber,
  });

  final TreinoModel plan;
  final PlanDayData day;
  final int? weekNumber;

  @override
  Widget build(BuildContext context) {
    final exercises = day.workout.exercicios;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
                if (exercises.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: FitEmptyState(
                      icon: Icons.fitness_center_rounded,
                      title: 'Dia sem exercicios',
                      description:
                          'Adicione exercicios ao plano antes de iniciar.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      FitSpacing.s20,
                      FitSpacing.s20,
                      FitSpacing.s20,
                      120,
                    ),
                    sliver: SliverList.separated(
                      itemCount: exercises.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: FitSpacing.s12),
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return FitExerciseCard(
                          name: exercise.nome,
                          category: '${index + 1}',
                          media: ExerciseMedia(
                            exercise: exercise,
                            width: 72,
                            height: 72,
                          ),
                          tags: [FitTagChip(label: _prescription(exercise))],
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExercicioDetalhePage(exercicio: exercise),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: exercises.isEmpty ? null : _startButton(context),
    );
  }

  Widget _header(BuildContext context) {
    final prefix = weekNumber == null ? day.label : 'Semana $weekNumber';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s8,
        FitSpacing.s20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FitHeader(
            title: '$prefix - ${day.label}',
            showBackButton: true,
            onBack: () => TreinoNavigation.popOrHome(context),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: FitSpacing.s16),
          Text(day.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: FitSpacing.s8),
          Text(
            '${_minutes(plan)} min estimados',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: FitColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _startButton(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s8,
        FitSpacing.s20,
        FitSpacing.s16,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FitButton(
            label: 'Iniciar treino',
            icon: Icons.play_arrow_rounded,
            onPressed: () => UnifiedWorkoutNavigation.startAndOpen(
              context,
              plan: plan,
              workout: day.workout,
              dayName: day.label,
              muscleGroup: day.title,
            ),
            expand: true,
          ),
        ),
      ),
    );
  }

  String _prescription(ExercicioModel exercise) {
    final sets = exercise.series <= 0 ? 3 : exercise.series;
    final reps = exercise.repeticoes.toString().trim().isEmpty
        ? '8-12'
        : exercise.repeticoes.toString();
    return '$sets series - $reps reps';
  }

  int _minutes(TreinoModel value) {
    return value.tempoEstimado <= 0 ? 45 : value.tempoEstimado;
  }
}
