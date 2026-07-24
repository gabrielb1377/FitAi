import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Progresso circular da meta de passos.
class FitStepsProgressRing extends StatelessWidget {
  const FitStepsProgressRing({
    super.key,
    required this.progress,
    required this.stepsLabel,
    this.semanticLabel = 'Progresso de passos',
  });

  final double progress;
  final String stepsLabel;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '$semanticLabel, $stepsLabel, ${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: ExcludeSemantics(
        child: FitProgressRing(
          value: progress,
          label: stepsLabel,
          color: context.fitColors.steps,
          size: FitLayout.domainProgressRingLarge,
          strokeWidth: FitLayout.domainProgressRingStroke,
        ),
      ),
    );
  }
}

/// Resumo diário de passos.
class FitStepsSummaryCard extends StatelessWidget {
  const FitStepsSummaryCard({
    super.key,
    required this.stepsLabel,
    required this.progress,
    this.title = 'Passos hoje',
    this.metrics = const [],
    this.loading = false,
  });

  final String title;
  final String stepsLabel;
  final double progress;
  final List<FitMetricData> metrics;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const FitLoadingCard();
    return FitCard(
      title: title,
      leading: Icon(FitIcons.steps, color: context.fitColors.steps),
      child: Column(
        children: [
          FitStepsProgressRing(progress: progress, stepsLabel: stepsLabel),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s16),
            FitDomainMetricStrip(metrics: metrics),
          ],
        ],
      ),
    );
  }
}

/// Linha responsiva de métricas relacionadas a passos.
class FitStepsMetricRow extends StatelessWidget {
  const FitStepsMetricRow({super.key, required this.metrics});

  final List<FitMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return FitDomainMetricStrip(metrics: metrics, compact: true);
  }
}

/// Card de meta de passos.
class FitStepsGoalCard extends StatelessWidget {
  const FitStepsGoalCard({
    super.key,
    required this.value,
    required this.progress,
    this.title = 'Meta diária',
    this.description,
    this.onTap,
  });

  final String title;
  final String value;
  final double progress;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: title,
      value: value,
      progress: progress,
      icon: FitIcons.goal,
      color: context.fitColors.steps,
      description: description,
      onTap: onTap,
    );
  }
}

/// Gráfico semanal de passos.
class FitStepsWeeklyChartCard extends StatelessWidget {
  const FitStepsWeeklyChartCard({
    super.key,
    required this.points,
    this.title = 'Últimos 7 dias',
    this.subtitle,
  });

  final List<FitChartPoint> points;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      subtitle: subtitle,
      child: FitDomainBarChart(
        points: points,
        semanticLabel: 'Gráfico semanal de passos',
        color: context.fitColors.steps,
      ),
    );
  }
}

/// Card de sequência de dias com meta alcançada.
class FitStepsStreakCard extends StatelessWidget {
  const FitStepsStreakCard({
    super.key,
    required this.value,
    this.title = 'Sequência',
    this.description,
  });

  final String title;
  final String value;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: title,
      value: value,
      progress: 1,
      icon: FitIcons.streak,
      color: context.fitColors.achievement,
      description: description,
    );
  }
}

/// Linha diária do histórico de passos.
class FitStepsHistoryRow extends StatelessWidget {
  const FitStepsHistoryRow({
    super.key,
    required this.dateLabel,
    required this.stepsLabel,
    this.distanceLabel,
    this.goalReached = false,
    this.onTap,
  });

  final String dateLabel;
  final String stepsLabel;
  final String? distanceLabel;
  final bool goalReached;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: dateLabel,
      subtitle: distanceLabel,
      leading: Icon(FitIcons.steps, color: context.fitColors.steps),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stepsLabel, style: context.textTheme.titleSmall),
          if (goalReached) ...[
            const SizedBox(width: FitSpacing.s8),
            Icon(FitIcons.success, color: context.colors.primary),
          ],
        ],
      ),
      onTap: onTap,
      semanticLabel:
          '$dateLabel, $stepsLabel${goalReached ? ', meta alcançada' : ''}',
    );
  }
}

/// Posição do usuário em um ranking de passos.
class FitStepsRankingCard extends StatelessWidget {
  const FitStepsRankingCard({
    super.key,
    required this.positionLabel,
    required this.stepsLabel,
    this.title = 'Ranking',
    this.description,
    this.onTap,
  });

  final String title;
  final String positionLabel;
  final String stepsLabel;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: description,
      icon: FitIcons.achievement,
      accent: context.fitColors.achievement,
      metrics: [
        FitMetricData(
          label: 'Posição',
          value: positionLabel,
          icon: FitIcons.achievement,
        ),
        FitMetricData(label: 'Passos', value: stepsLabel, icon: FitIcons.steps),
      ],
      onTap: onTap,
    );
  }
}

/// Conquista específica de passos.
class FitStepsAchievementCard extends StatelessWidget {
  const FitStepsAchievementCard({super.key, required this.data, this.onTap});

  final FitAchievementDisplayData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: data.title,
      subtitle: data.description,
      icon: data.icon,
      accent: data.unlocked
          ? context.fitColors.achievement
          : context.colors.onSurfaceVariant,
      progress: data.progress,
      tags: [
        FitDomainStatusBadge(
          label: data.unlocked ? 'Conquistada' : 'Em progresso',
          tone: data.unlocked
              ? FitDomainTone.achievement
              : FitDomainTone.neutral,
        ),
      ],
      onTap: onTap,
    );
  }
}
