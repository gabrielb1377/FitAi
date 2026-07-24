import 'package:flutter/material.dart';

import '../../../../core/xp/xp_config.dart';
import '../../../../design_system/fit_design_system.dart';
import '../../../../models/treino_model.dart';
import '../../../../services/treino_do_dia_service.dart';

class HomeXpCard extends StatelessWidget {
  const HomeXpCard({
    super.key,
    required this.xp,
    required this.level,
    required this.onTap,
  });

  final int xp;
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = XpConfig.xpParaProximoNivel(level);
    final current = XpConfig.normalizarXp(xp).clamp(0, target).toInt();
    final progress = target <= 0 ? 0.0 : current / target;
    return FitCard(
      key: const ValueKey('home-xp-card'),
      onTap: onTap,
      variant: FitCardVariant.clickable,
      semanticLabel:
          'XP do dia, $current de $target, ${(progress * 100).round()} por cento',
      header: Row(
        children: [
          Expanded(
            child: Text('XP do dia', style: context.textTheme.titleMedium),
          ),
          const Icon(
            FitIcons.forward,
            size: FitLayout.iconSizeCompact,
            color: FitColors.textSecondary,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _XpRing(
                value: progress.clamp(0, 1).toDouble(),
                current: current,
                target: target,
              ),
            ),
          ),
          const SizedBox(width: FitSpacing.s16),
          Text(
            '${(progress * 100).round()}%',
            style: context.textTheme.titleLarge?.copyWith(
              color: FitColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpRing extends StatelessWidget {
  const _XpRing({
    required this.value,
    required this.current,
    required this.target,
  });

  final double value;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: FitLayout.domainProgressRingLarge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: FitLayout.domainProgressRingLarge,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: FitLayout.domainProgressRingStroke,
              strokeCap: StrokeCap.round,
              color: FitColors.primary,
              backgroundColor: FitColors.cardInner,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(FitSpacing.s16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$current', style: context.textTheme.headlineLarge),
                  Text('/ $target XP', style: context.textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeDailyMetrics extends StatelessWidget {
  const HomeDailyMetrics({
    super.key,
    required this.steps,
    required this.workouts,
    required this.calories,
    required this.onViewAll,
    required this.onOpenSteps,
    required this.onOpenProgress,
  });

  final int steps;
  final int workouts;
  final int calories;
  final VoidCallback onViewAll;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Treino',
        value: '$workouts/1',
        detail: 'treinos',
        progress: workouts.clamp(0, 1).toDouble(),
        onTap: onOpenProgress,
      ),
      _MetricData(
        label: 'Passos',
        value: _compactNumber(steps),
        detail: 'passos',
        progress: (steps / 10000).clamp(0, 1).toDouble(),
        onTap: onOpenSteps,
      ),
      _MetricData(
        label: 'Calorias',
        value: _compactNumber(calories),
        detail: 'kcal',
        progress: (calories / 1800).clamp(0, 1).toDouble(),
        onTap: onOpenProgress,
      ),
    ];
    return FitSection(
      title: 'Atividades de hoje',
      onViewAll: onViewAll,
      viewAllLabel: 'Ver todas',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = !FitBreakpoints.isSmallMobile(
            MediaQuery.sizeOf(context).width,
          );
          if (compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(child: _HomeMetricCard(data: metrics[index])),
                  if (index < metrics.length - 1)
                    const SizedBox(width: FitSpacing.s8),
                ],
              ],
            );
          }
          return Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: (constraints.maxWidth - FitSpacing.s8) / 2,
                  child: _HomeMetricCard(data: metric),
                ),
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
    required this.progress,
    required this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final double progress;
  final VoidCallback onTap;
}

class _HomeMetricCard extends StatelessWidget {
  const _HomeMetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: data.onTap,
      variant: FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s12),
      semanticLabel:
          '${data.label}: ${data.value} ${data.detail}, ${(data.progress * 100).round()} por cento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.label, style: context.textTheme.labelSmall),
          const SizedBox(height: FitSpacing.s4),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: FitSpacing.s2),
          Text(data.detail, style: context.textTheme.labelSmall),
          const SizedBox(height: FitSpacing.s8),
          FitProgressBar(value: data.progress),
        ],
      ),
    );
  }
}

class HomeTodayCards extends StatelessWidget {
  const HomeTodayCards({
    super.key,
    required this.selection,
    required this.runningActive,
    required this.runningDistance,
    required this.onOpenWorkout,
    required this.onCreatePlan,
    required this.onOpenRunning,
    required this.onOpenTodayWorkout,
  });

  final TreinoDoDiaSelecao selection;
  final bool runningActive;
  final double runningDistance;
  final VoidCallback onOpenWorkout;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenRunning;
  final VoidCallback onOpenTodayWorkout;

  @override
  Widget build(BuildContext context) {
    final workout = selection.treino;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = !FitBreakpoints.isSmallMobile(
          MediaQuery.sizeOf(context).width,
        );
        final cards = [
          _WorkoutPreviewCard(
            workout: workout,
            onOpen: workout == null ? onCreatePlan : onOpenTodayWorkout,
            onAction: workout == null ? onCreatePlan : onOpenWorkout,
          ),
          _RunningPreviewCard(
            active: runningActive,
            distance: runningDistance,
            onOpen: onOpenRunning,
          ),
        ];
        if (!sideBySide) {
          return Column(
            children: [
              cards.first,
              const SizedBox(height: FitSpacing.s12),
              cards.last,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: FitSpacing.s12),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}

class _WorkoutPreviewCard extends StatelessWidget {
  const _WorkoutPreviewCard({
    required this.workout,
    required this.onOpen,
    required this.onAction,
  });

  final TreinoModel? workout;
  final VoidCallback onOpen;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final item = workout;
    return FitCard(
      onTap: onOpen,
      variant: FitCardVariant.clickable,
      padding: EdgeInsets.zero,
      semanticLabel: item == null
          ? 'Criar primeiro plano'
          : 'Treino de hoje, ${item.nome}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreviewMedia(
            assetPath: item?.exercicios.firstOrNull?.imagem,
            fallbackIcon: FitIcons.workout,
          ),
          Padding(
            padding: const EdgeInsets.all(FitSpacing.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Treino de hoje', style: context.textTheme.labelSmall),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  item?.nome ?? 'Novo plano',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: FitSpacing.s8),
                FitPrimaryButton(
                  label: item == null ? 'Criar plano' : 'Iniciar treino',
                  size: FitButtonSize.small,
                  fullWidth: true,
                  onPressed: onAction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningPreviewCard extends StatelessWidget {
  const _RunningPreviewCard({
    required this.active,
    required this.distance,
    required this.onOpen,
  });

  final bool active;
  final double distance;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: onOpen,
      variant: FitCardVariant.clickable,
      padding: EdgeInsets.zero,
      semanticLabel: 'Corrida, ${distance.toStringAsFixed(1)} quilômetros',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PreviewMedia(fallbackIcon: FitIcons.running),
          Padding(
            padding: const EdgeInsets.all(FitSpacing.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Corrida', style: context.textTheme.labelSmall),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: FitSpacing.s8),
                FitPrimaryButton(
                  label: active ? 'Continuar' : 'Iniciar corrida',
                  size: FitButtonSize.small,
                  fullWidth: true,
                  onPressed: onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMedia extends StatelessWidget {
  const _PreviewMedia({this.assetPath, required this.fallbackIcon});

  final String? assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final path = assetPath?.trim() ?? '';
    return AspectRatio(
      aspectRatio: FitLayout.domainCompactMediaAspectRatio,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FitRadius.large),
        ),
        child: path.isEmpty
            ? ColoredBox(
                color: FitColors.cardInner,
                child: Center(
                  child: Icon(
                    fallbackIcon,
                    size: FitLayout.iconSizeState,
                    color: FitColors.primary,
                  ),
                ),
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: FitColors.cardInner,
                  child: Center(
                    child: Icon(
                      fallbackIcon,
                      size: FitLayout.iconSizeState,
                      color: FitColors.primary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
