import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import 'controllers/plan_day_data.dart';
import 'controllers/plan_progress_snapshot.dart';
import 'exercicio_detalhe_page.dart';
import 'workout_day_page.dart';
import 'treino_navigation.dart';
import 'widgets/plans/plan_media.dart';

class PlanWeeksPage extends StatefulWidget {
  const PlanWeeksPage({super.key, required this.plan, required this.progress});

  final TreinoModel plan;
  final PlanProgressSnapshot progress;

  @override
  State<PlanWeeksPage> createState() => _PlanWeeksPageState();
}

class _PlanWeeksPageState extends State<PlanWeeksPage> {
  var _tabIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                FitHeader(
                  title: widget.plan.nome,
                  showBackButton: true,
                  onBack: () => TreinoNavigation.popOrHome(context),
                ),
                _PlanDetailTabs(
                  selectedIndex: _tabIndex,
                  onSelected: (index) {
                    if (index == 0) {
                      TreinoNavigation.popOrHome(context);
                    } else {
                      setState(() => _tabIndex = index);
                    }
                  },
                ),
                const FitDivider(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: FitDuration.normal,
                    child: _tabIndex == 1 ? _weeks() : _exercises(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _weeks() {
    final weeks = widget.progress.weeks;
    return ListView.separated(
      key: const ValueKey('plan-weeks'),
      padding: const EdgeInsets.all(FitSpacing.s20),
      itemCount: weeks.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: FitSpacing.s12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Semanas do plano',
            style: Theme.of(context).textTheme.titleLarge,
          );
        }
        final week = weeks[index - 1];
        return _PlanWeekTile(
          week: week,
          onTap: week.isFuture ? null : () => _openWeek(week),
        );
      },
    );
  }

  Widget _exercises() {
    final exercises = widget.plan.exercicios;
    if (exercises.isEmpty) {
      return const FitEmptyState(
        icon: Icons.fitness_center_rounded,
        title: 'Nenhum exercicio salvo',
        description: 'Este plano ainda nao possui exercicios completos.',
      );
    }
    return ListView.separated(
      key: const ValueKey('plan-exercises'),
      padding: const EdgeInsets.all(FitSpacing.s20),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: FitSpacing.s12),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return FitExerciseCard(
          name: exercise.nome,
          category: exercise.categoria,
          media: ExerciseMedia(exercise: exercise, width: 64, height: 64),
          tags: [FitTagChip(label: _setsAndReps(exercise))],
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => ExercicioDetalhePage(exercicio: exercise),
            ),
          ),
        );
      },
    );
  }

  void _openWeek(PlanWeekSnapshot week) {
    final days = buildPlanDays(widget.plan);
    if (days.isEmpty) return;
    final index = week.isCurrent
        ? widget.progress.nextDayIndex.clamp(0, days.length - 1).toInt()
        : 0;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayPage(
          plan: widget.plan,
          day: days[index],
          weekNumber: week.number,
        ),
      ),
    );
  }

  String _setsAndReps(ExercicioModel exercise) {
    final sets = exercise.series <= 0 ? 3 : exercise.series;
    final reps = exercise.repeticoes.toString().trim().isEmpty
        ? '8-12'
        : exercise.repeticoes.toString();
    return '$sets series - $reps reps';
  }
}

class _PlanDetailTabs extends StatelessWidget {
  const _PlanDetailTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Visao geral', 'Semanas', 'Exercicios'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = selectedIndex == index;
        return Expanded(
          child: InkWell(
            onTap: () => onSelected(index),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? FitColors.primary
                          : FitColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s12),
                  Container(
                    height: 2,
                    color: selected ? FitColors.primary : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PlanWeekTile extends StatelessWidget {
  const _PlanWeekTile({required this.week, required this.onTap});

  final PlanWeekSnapshot week;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (week.progress * 100).round();
    return FitCard(
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: _semanticLabel(percent),
      child: Row(
        children: [
          Container(
            width: 64,
            constraints: const BoxConstraints(minHeight: 112),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: week.isCurrent
                  ? FitColors.primaryContainer
                  : Colors.transparent,
              border: const Border(
                right: BorderSide(color: FitColors.outlineSoft),
              ),
            ),
            child: Text(
              '${week.number}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: week.isFuture ? FitColors.textHint : FitColors.primary,
              ),
            ),
          ),
          const SizedBox(width: FitSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semana ${week.number}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  week.isFuture
                      ? 'Disponivel em ${_date(week.startsAt)}'
                      : '${week.completedWorkouts} de ${week.targetWorkouts} treinos',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (week.isCurrent && !week.isCompleted) ...[
                  const SizedBox(height: FitSpacing.s12),
                  SizedBox(
                    width: 100,
                    child: FitProgress(value: week.progress),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(FitSpacing.s16),
            child: Icon(
              week.isCompleted
                  ? Icons.check_circle_rounded
                  : week.isFuture
                  ? Icons.lock_outline_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: week.isCompleted
                  ? FitColors.primary
                  : FitColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }

  String _semanticLabel(int percent) {
    if (week.isFuture) return 'Semana ${week.number}, bloqueada';
    return 'Semana ${week.number}, $percent por cento concluida';
  }
}
