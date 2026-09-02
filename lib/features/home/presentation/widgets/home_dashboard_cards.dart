import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../widgets/exercicio_gif_viewer.dart';
import '../../../../services/treino_do_dia_service.dart';

/// Resumo compacto da evolucao diaria, equivalente ao anel do prototipo Home.
///
/// A prioridade e tornar visivel, sem recalcular progressao de dominio, a meta
/// agregada que ja chegou na Home. Quando ainda nao ha meta, o anel comunica o
/// avanco observavel por treino concluido e passos no dia.
class HomeDailyProgressCard extends StatelessWidget {
  const HomeDailyProgressCard({
    super.key,
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.steps,
    required this.workoutsToday,
    required this.primaryGoal,
    required this.onTap,
  });

  final int xp;
  final int level;
  final int currentStreak;
  final int steps;
  final int workoutsToday;
  final FitaiMetaModel? primaryGoal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final goal = primaryGoal;
    final progress = (goal?.progresso ?? _observedDailyProgress())
        .clamp(0, 1)
        .toDouble();
    final percentage = (progress * 100).round();
    final caption = goal == null
        ? _dailyCaption()
        : '${goal.titulo}: ${goal.progressoPercentual} concluido.';

    return Semantics(
      key: const ValueKey('home-daily-progress-card'),
      button: true,
      label:
          'Progresso ${goal == null ? 'do dia' : 'da meta ${goal.titulo}'}, '
          '$percentage por cento. $currentStreak dias seguidos.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.mediumBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FitSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: FitSpacing.s12,
                  runSpacing: FitSpacing.s8,
                  children: [
                    Text('Ritmo de hoje', style: context.textTheme.titleMedium),
                    _StreakPill(days: currentStreak),
                  ],
                ),
                const SizedBox(height: FitSpacing.s12),
                ClipRRect(
                  borderRadius: FitRadius.smallBorder,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: FitLayout.progressCompactThickness,
                  ),
                ),
                const SizedBox(height: FitSpacing.s8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: FitSpacing.s12),
                    Text(
                      '$percentage%',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  'Nivel $level  /  $xp XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _observedDailyProgress() {
    final workoutProgress = workoutsToday > 0 ? 0.5 : 0.0;
    final stepsProgress = (steps / 10000).clamp(0, 1) * 0.5;
    return workoutProgress + stepsProgress;
  }

  String _dailyCaption() {
    if (workoutsToday > 0 && steps >= 10000) {
      return 'Treino e meta de passos concluidos hoje.';
    }
    if (workoutsToday > 0) {
      return 'Treino registrado. Continue com seus passos.';
    }
    if (steps > 0) {
      return '$steps passos registrados. Seu treino ainda esta disponivel.';
    }
    return 'Registre uma atividade para iniciar seu progresso diario.';
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s8,
        vertical: FitSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: context.fitColors.cardInner,
        borderRadius: FitRadius.smallBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            FitIcons.streak,
            color: FitColors.achievement,
            size: FitLayout.iconSizeSmall,
          ),
          const SizedBox(width: FitSpacing.s4),
          Flexible(
            child: Text(
              '$days dias seguidos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de acesso rapido para dados que a Home ja recebe dos modulos reais.
class HomeDailyMetrics extends StatelessWidget {
  const HomeDailyMetrics({
    super.key,
    required this.steps,
    required this.distance,
    required this.workouts,
    required this.weeklyXp,
    required this.runningActive,
    required this.onOpenSteps,
    required this.onOpenRunning,
    required this.onOpenProgress,
    required this.onOpenOverview,
  });

  final int steps;
  final double distance;
  final int workouts;
  final int weeklyXp;
  final bool runningActive;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenRunning;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context) {
    final metrics = <FitMetricRailItem>[
      FitMetricRailItem(
        label: 'Treinos',
        value: '$workouts',
        icon: FitIcons.workout,
        color: context.colors.primary,
        onTap: onOpenProgress,
      ),
      FitMetricRailItem(
        label: 'Passos',
        value: _compactNumber(steps),
        icon: FitIcons.steps,
        color: context.fitColors.steps,
        onTap: onOpenSteps,
      ),
      FitMetricRailItem(
        label: 'Corrida',
        value: runningActive ? 'Ativa' : '${distance.toStringAsFixed(1)} km',
        icon: FitIcons.running,
        color: context.fitColors.running,
        onTap: onOpenRunning,
      ),
      FitMetricRailItem(
        label: 'XP',
        value: _compactNumber(weeklyXp),
        icon: FitIcons.progress,
        color: context.fitColors.xp,
        onTap: onOpenOverview,
      ),
    ];
    return Semantics(
      container: true,
      label: 'Metricas de hoje',
      child: FitMetricRail(items: metrics),
    );
  }

  String _compactNumber(int value) {
    if (value >= 1000) {
      final result = value / 1000;
      return '${result.toStringAsFixed(result >= 10 ? 0 : 1)}k';
    }
    return '$value';
  }
}

/// Hero funcional do treino do dia. O conteudo e determinado pelo servico
/// existente de selecao, enquanto esta classe cuida somente da apresentacao.
class HomeTodayWorkoutHero extends StatelessWidget {
  const HomeTodayWorkoutHero({
    super.key,
    required this.selection,
    required this.onOpenWorkout,
    required this.onCreatePlan,
    required this.onOpenTodayWorkout,
  });

  final TreinoDoDiaSelecao selection;
  final VoidCallback onOpenWorkout;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenTodayWorkout;

  @override
  Widget build(BuildContext context) {
    final workout = selection.treino;
    final isEmpty = workout == null;
    final isCompleted = selection.treinoConcluidoHoje;
    final isRestDay = selection.diaDeDescanso;
    final action = isEmpty
        ? onCreatePlan
        : isCompleted
        ? onOpenTodayWorkout
        : onOpenWorkout;
    final actionLabel = isEmpty
        ? 'Criar plano'
        : isCompleted
        ? 'Ver treino'
        : 'Iniciar treino';
    final status = isEmpty
        ? 'Seu proximo passo'
        : isCompleted
        ? 'Treino concluido'
        : isRestDay
        ? 'Recuperacao sugerida'
        : workout.criadoPorIA
        ? 'Sugerido pela IA'
        : 'Treino de hoje';
    final title = _titleFor(workout);
    final subtitle = _subtitleFor(workout);

    return FitEditorialHero(
      key: const ValueKey('home-today-workout-hero'),
      onTap: isEmpty ? onCreatePlan : onOpenTodayWorkout,
      eyebrow: status,
      title: title,
      subtitle: subtitle,
      semanticLabel: '$status: $title. $subtitle',
      trailing: workout?.criadoPorIA ?? false
          ? Tooltip(
              message: 'Plano criado com IA',
              child: Icon(FitIcons.ai, color: context.fitColors.ai),
            )
          : isCompleted
          ? Icon(FitIcons.check, color: context.colors.primary)
          : null,
      action: FitPrimaryButton(
        label: actionLabel,
        icon: isCompleted ? FitIcons.check : FitIcons.play,
        fullWidth: true,
        onPressed: action,
      ),
      child: workout == null
          ? Container(
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: FitRadius.mediumBorder,
              ),
              child: Icon(
                FitIcons.plans,
                color: context.colors.primary,
                size: FitLayout.iconSizeLarge,
              ),
            )
          : Column(
              children: [
                _ExercisePreviewStrip(exercises: workout.exercicios),
                const SizedBox(height: FitSpacing.s12),
                FitMetricRail(
                  items: [
                    FitMetricRailItem(
                      label: 'Duracao',
                      value: '${workout.tempoEstimado} min',
                      icon: FitIcons.time,
                    ),
                    FitMetricRailItem(
                      label: 'Exercicios',
                      value: '${workout.exercicios.length}',
                      icon: FitIcons.exercise,
                    ),
                    FitMetricRailItem(
                      label: 'Nivel',
                      value: workout.nivel,
                      icon: FitIcons.progress,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _titleFor(TreinoModel? workout) {
    if (workout != null) return workout.nome;
    final title = selection.titulo.trim();
    return title.isEmpty || title == 'Nenhum treino'
        ? 'Nenhum treino criado ainda'
        : title;
  }

  String _subtitleFor(TreinoModel? workout) {
    if (workout == null) {
      final detail = selection.descricao.trim();
      return detail.isEmpty
          ? 'Crie um plano para receber seu proximo treino.'
          : detail;
    }
    final groups = workout.gruposPrioritarios.where((item) => item.isNotEmpty);
    if (groups.isNotEmpty) return groups.join('  |  ');
    if (workout.grupoDia.trim().isNotEmpty) return workout.grupoDia;
    if (workout.descricao.trim().isNotEmpty) return workout.descricao;
    return '${workout.exercicios.length} exercicios  |  ${workout.nivel}';
  }
}

class _ExercisePreviewStrip extends StatelessWidget {
  const _ExercisePreviewStrip({required this.exercises});

  final List<dynamic> exercises;

  @override
  Widget build(BuildContext context) {
    final exercise = exercises.isEmpty ? null : exercises.first;
    final canonicalExerciseId =
        exercise?.canonicalExerciseId?.toString().trim().isNotEmpty == true
        ? exercise.canonicalExerciseId.toString()
        : exercise?.id?.toString() ?? '';
    final exerciseName = exercise?.nome?.toString() ?? 'Exercicio';
    return Semantics(
      image: true,
      label: exercises.isEmpty
          ? 'Treino sem midia disponivel'
          : 'Previa do primeiro exercicio',
      child: AspectRatio(
        aspectRatio: FitLayout.domainCompactMediaAspectRatio,
        child: ClipRRect(
          borderRadius: FitRadius.mediumBorder,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExercicioGifImage(
                canonicalExerciseId: canonicalExerciseId,
                titulo: exerciseName,
                fit: BoxFit.contain,
                placeholder: _mediaFallback(context),
              ),
              if (exercises.length > 1)
                Positioned(
                  right: FitSpacing.s8,
                  bottom: FitSpacing.s8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.surface.withValues(alpha: 0.9),
                      borderRadius: FitRadius.smallBorder,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FitSpacing.s8,
                        vertical: FitSpacing.s4,
                      ),
                      child: Text(
                        '+${exercises.length - 1} exercicios',
                        style: context.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaFallback(BuildContext context) => ColoredBox(
    color: context.colors.surfaceContainerHighest,
    child: Icon(
      FitIcons.exercise,
      color: context.colors.primary,
      size: FitLayout.iconSizeLarge,
    ),
  );
}
