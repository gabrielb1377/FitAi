import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Resumo das métricas produzidas por uma sessão concluída.
class FitWorkoutSummaryCard extends StatelessWidget {
  const FitWorkoutSummaryCard({
    super.key,
    required this.title,
    required this.metrics,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final List<FitMetricData> metrics;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.workout,
      metrics: metrics,
      footer: action,
    );
  }
}

/// Métrica de treino com nomenclatura de domínio.
class FitWorkoutMetric extends StatelessWidget {
  const FitWorkoutMetric({super.key, required this.data});

  final FitMetricData data;

  @override
  Widget build(BuildContext context) {
    return FitStatistic(
      label: data.label,
      value: data.value,
      icon: data.icon,
      unit: data.unit,
      detail: data.detail,
      color: data.color,
    );
  }
}

/// Badge para recorde pessoal alcançado no treino.
class FitPersonalRecordBadge extends StatelessWidget {
  const FitPersonalRecordBadge({super.key, this.label = 'Novo recorde'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FitDomainStatusBadge(
      label: label,
      tone: FitDomainTone.achievement,
      icon: FitIcons.achievement,
    );
  }
}

/// Card de XP recebido; o valor e a progressão chegam prontos.
class FitWorkoutXPCard extends StatelessWidget {
  const FitWorkoutXPCard({
    super.key,
    required this.xpLabel,
    required this.progress,
    this.title = 'Experiência',
    this.nextLevelLabel,
  });

  final String title;
  final String xpLabel;
  final double progress;
  final String? nextLevelLabel;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: title,
      value: xpLabel,
      progress: progress,
      icon: FitIcons.achievement,
      color: context.fitColors.xp,
      description: nextLevelLabel,
    );
  }
}

/// Cabeçalho celebrativo e contido para conclusão do treino.
class FitWorkoutCompletionHeader extends StatelessWidget {
  const FitWorkoutCompletionHeader({
    super.key,
    required this.title,
    this.message,
    this.icon = FitIcons.success,
  });

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      liveRegion: true,
      label: '$title${message == null ? '' : ', $message'}',
      child: Column(
        children: [
          Icon(
            icon,
            size: FitLayout.iconSizeState,
            color: context.colors.primary,
          ),
          const SizedBox(height: FitSpacing.s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall,
          ),
          if (message != null) ...[
            const SizedBox(height: FitSpacing.s8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
