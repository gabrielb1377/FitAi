import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';
import '../../../../models/treino_model.dart';
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

    return FitCard(
      key: const ValueKey('home-daily-progress-card'),
      onTap: onTap,
      variant: FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s16),
      semanticLabel:
          'Progresso ${goal == null ? 'do dia' : 'da meta ${goal.titulo}'}, '
          '$percentage por cento. $currentStreak dias seguidos.',
      child: Row(
        children: [
          _DailyProgressRing(value: progress, percentage: percentage),
          const SizedBox(width: FitSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StreakPill(days: currentStreak),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  'Nivel $level  |  $xp XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          const Icon(
            FitIcons.forward,
            color: FitColors.textTertiary,
            size: FitLayout.iconSizeCompact,
          ),
        ],
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

class _DailyProgressRing extends StatelessWidget {
  const _DailyProgressRing({required this.value, required this.percentage});

  final double value;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: FitLayout.progressRingSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: FitLayout.progressRingSize,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: FitLayout.progressRingStroke,
                strokeCap: StrokeCap.round,
                color: FitColors.primary,
                backgroundColor: FitColors.cardInner,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$percentage%', style: context.textTheme.titleMedium),
                  Text('do dia', style: context.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      decoration: const BoxDecoration(
        color: FitColors.achievementContainer,
        borderRadius: FitRadius.pillBorder,
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
    final metrics = <_MetricData>[
      _MetricData(
        label: 'Treinos',
        value: '$workouts',
        detail: 'hoje',
        icon: FitIcons.workout,
        color: FitColors.primary,
        onTap: onOpenProgress,
      ),
      _MetricData(
        label: 'Passos',
        value: _compactNumber(steps),
        detail: 'hoje',
        icon: FitIcons.steps,
        color: FitColors.steps,
        onTap: onOpenSteps,
      ),
      _MetricData(
        label: 'Corrida',
        value: runningActive ? 'Ativa' : '${distance.toStringAsFixed(1)} km',
        detail: runningActive ? 'em andamento' : 'total',
        icon: FitIcons.running,
        color: FitColors.running,
        onTap: onOpenRunning,
      ),
      _MetricData(
        label: 'XP',
        value: _compactNumber(weeklyXp),
        detail: 'semana',
        icon: FitIcons.progress,
        color: FitColors.xp,
        onTap: onOpenOverview,
      ),
    ];
    final useTwoColumns =
        MediaQuery.sizeOf(context).width < FitBreakpoints.smallMobile ||
        MediaQuery.textScalerOf(context).scale(1) > 1.25;

    return Semantics(
      container: true,
      label: 'Metricas de hoje',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (useTwoColumns) {
            return Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: (constraints.maxWidth - FitSpacing.s8) / 2,
                    child: _HomeMetricChip(data: metric),
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(child: _HomeMetricChip(data: metrics[index])),
                if (index < metrics.length - 1)
                  const SizedBox(width: FitSpacing.s8),
              ],
            ],
          );
        },
      ),
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

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _HomeMetricChip extends StatelessWidget {
  const _HomeMetricChip({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: data.onTap,
      variant: FitCardVariant.clickable,
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s4,
        vertical: FitSpacing.s8,
      ),
      semanticLabel: '${data.label}: ${data.value} ${data.detail}',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, color: data.color, size: FitLayout.iconSizeSmall),
            const SizedBox(height: FitSpacing.s4),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall,
            ),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
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

    return FitCard(
      key: const ValueKey('home-today-workout-hero'),
      onTap: isEmpty ? onCreatePlan : onOpenTodayWorkout,
      variant: FitCardVariant.clickable,
      color: FitColors.surfaceRaised,
      borderColor: FitColors.borderSubtle,
      elevation: 1,
      padding: const EdgeInsets.all(FitSpacing.s24),
      semanticLabel: '$status: $title. $subtitle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusBadge(
                  isAi: workout?.criadoPorIA ?? false,
                  label: status,
                ),
              ),
              if (workout != null) ...[
                const SizedBox(width: FitSpacing.s8),
                const Icon(
                  FitIcons.time,
                  color: FitColors.textTertiary,
                  size: FitLayout.iconSizeSmall,
                ),
                const SizedBox(width: FitSpacing.s4),
                Text(
                  '${workout.tempoEstimado} min',
                  style: context.textTheme.labelSmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: FitSpacing.s12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.headlineMedium,
          ),
          const SizedBox(height: FitSpacing.s4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium,
          ),
          if (workout != null) ...[
            const SizedBox(height: FitSpacing.s16),
            _ExercisePreviewStrip(exercises: workout.exercicios),
          ],
          const SizedBox(height: FitSpacing.s24),
          FitPrimaryButton(
            label: actionLabel,
            icon: isCompleted ? FitIcons.check : FitIcons.play,
            fullWidth: true,
            onPressed: action,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isAi, required this.label});

  final bool isAi;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: FitLayout.none),
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s8,
        vertical: FitSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: isAi ? FitColors.aiContainer : FitColors.primaryContainer,
        borderRadius: FitRadius.smallBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAi ? FitIcons.ai : FitIcons.workout,
            color: isAi ? FitColors.ai : FitColors.primary,
            size: FitLayout.iconSizeSmall,
          ),
          const SizedBox(width: FitSpacing.s4),
          Flexible(
            child: Text(
              label,
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

class _ExercisePreviewStrip extends StatelessWidget {
  const _ExercisePreviewStrip({required this.exercises});

  final List<dynamic> exercises;

  @override
  Widget build(BuildContext context) {
    final preview = exercises.take(2).toList();
    final remaining = exercises.length - preview.length;
    return Row(
      children: [
        if (preview.isEmpty) const _ExerciseThumbnail(),
        for (final exercise in preview) ...[
          if (preview.first != exercise) const SizedBox(width: FitSpacing.s8),
          _ExerciseThumbnail(assetPath: exercise.imagem),
        ],
        if (remaining > 0) ...[
          const SizedBox(width: FitSpacing.s8),
          _MoreExercises(count: remaining),
        ],
      ],
    );
  }
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath?.trim() ?? '';
    return ClipRRect(
      borderRadius: FitRadius.mediumBorder,
      child: SizedBox.square(
        dimension: FitLayout.domainThumbnailSmall,
        child: path.isEmpty
            ? const ColoredBox(
                color: FitColors.cardInner,
                child: Icon(
                  FitIcons.exercise,
                  color: FitColors.primary,
                  size: FitLayout.iconSizeCompact,
                ),
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: FitColors.cardInner,
                  child: Icon(
                    FitIcons.exercise,
                    color: FitColors.primary,
                    size: FitLayout.iconSizeCompact,
                  ),
                ),
              ),
      ),
    );
  }
}

class _MoreExercises extends StatelessWidget {
  const _MoreExercises({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FitLayout.domainThumbnailSmall,
      height: FitLayout.domainThumbnailSmall,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: FitColors.cardInner,
        borderRadius: FitRadius.mediumBorder,
      ),
      child: Text('+$count', style: context.textTheme.labelSmall),
    );
  }
}
