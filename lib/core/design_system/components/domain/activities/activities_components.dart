import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../../feedback/feedback.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Tipos visuais de atividade suportados pelo catálogo.
enum FitActivityType { strength, run, walk, cycle, cardio, steps, custom }

/// Linha compacta de atividade para históricos densos.
class FitActivityCompactRow extends StatelessWidget {
  const FitActivityCompactRow({
    super.key,
    required this.title,
    required this.type,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final FitActivityType type;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _activityTypeVisual(context, type);
    return FitListTile(
      title: title,
      subtitle: subtitle,
      leading: Icon(visual.icon, color: visual.color),
      trailing: trailing ?? const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Chip de filtro ou identificação de tipo de atividade.
class FitActivityTypeChip extends StatelessWidget {
  const FitActivityTypeChip({
    super.key,
    required this.type,
    this.selected = false,
    this.onSelected,
  });

  final FitActivityType type;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final visual = _activityTypeVisual(context, type);
    return FilterChip(
      selected: selected,
      label: Text(visual.label),
      avatar: Icon(visual.icon, color: visual.color),
      onSelected: onSelected,
    );
  }
}

/// Métrica unitária de atividade.
class FitActivityMetric extends StatelessWidget {
  const FitActivityMetric({super.key, required this.data});

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

/// Resumo de uma atividade ou período.
class FitActivitySummaryCard extends StatelessWidget {
  const FitActivitySummaryCard({
    super.key,
    required this.title,
    required this.metrics,
    this.subtitle,
    this.type = FitActivityType.custom,
    this.action,
    this.loading = false,
  });

  final String title;
  final String? subtitle;
  final FitActivityType type;
  final List<FitMetricData> metrics;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final visual = _activityTypeVisual(context, type);
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: visual.icon,
      accent: visual.color,
      metrics: metrics,
      footer: action,
      loading: loading,
    );
  }
}

/// Dia de calendário com estado de atividade.
class FitActivityCalendarDay extends StatelessWidget {
  const FitActivityCalendarDay({
    super.key,
    required this.dayLabel,
    this.valueLabel,
    this.selected = false,
    this.completed = false,
    this.onTap,
  });

  final String dayLabel;
  final String? valueLabel;
  final bool selected;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      label:
          '$dayLabel${valueLabel == null ? '' : ', $valueLabel'}${completed ? ', atividade concluída' : ''}',
      child: FitCard(
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.all(FitSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dayLabel, style: context.textTheme.labelMedium),
            if (valueLabel != null) ...[
              const SizedBox(height: FitSpacing.s4),
              Text(valueLabel!, style: context.textTheme.titleSmall),
            ],
            if (completed) ...[
              const SizedBox(height: FitSpacing.s4),
              Icon(
                FitIcons.check,
                color: context.colors.primary,
                size: FitLayout.iconSizeSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Item cronológico do histórico de atividades.
class FitActivityHistoryItem extends StatelessWidget {
  const FitActivityHistoryItem({
    super.key,
    required this.title,
    required this.type,
    required this.dateLabel,
    this.metrics = const [],
    this.onTap,
  });

  final String title;
  final FitActivityType type;
  final String dateLabel;
  final List<FitMetricData> metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _activityTypeVisual(context, type);
    return FitDomainContentCard(
      title: title,
      subtitle: dateLabel,
      icon: visual.icon,
      accent: visual.color,
      metrics: metrics,
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Barra quebrável de filtros para tipos de atividade.
class FitActivityFilterBar extends StatelessWidget {
  const FitActivityFilterBar({
    super.key,
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<FitActivityType> types;
  final FitActivityType? selected;
  final ValueChanged<FitActivityType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FitSpacing.s8,
      runSpacing: FitSpacing.s8,
      children: [
        for (final type in types)
          FitActivityTypeChip(
            type: type,
            selected: type == selected,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}

/// Gráfico semanal de atividade em uma superfície temática.
class FitWeeklyActivityChartCard extends StatelessWidget {
  const FitWeeklyActivityChartCard({
    super.key,
    required this.points,
    this.title = 'Atividade semanal',
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
      child: FitDomainBarChart(points: points, semanticLabel: title),
    );
  }
}

/// Destaque para um recorde de atividade.
class FitActivityRecordCard extends StatelessWidget {
  const FitActivityRecordCard({
    super.key,
    required this.title,
    required this.value,
    this.description,
    this.onTap,
  });

  final String title;
  final String value;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: title,
      value: value,
      progress: 1,
      icon: FitIcons.achievement,
      color: context.fitColors.achievement,
      description: description,
      onTap: onTap,
    );
  }
}

/// Estado vazio contextual da área de atividades.
class FitActivityEmptyState extends StatelessWidget {
  const FitActivityEmptyState({
    super.key,
    this.title = 'Nenhuma atividade',
    this.description = 'Suas atividades aparecerão aqui.',
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FitEmptyState(
      title: title,
      description: description,
      icon: FitIcons.activities,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Aparência resolvida de um tipo de atividade.
@immutable
class _FitActivityTypeVisual {
  const _FitActivityTypeVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// Resolve rótulo, ícone e cor semântica de um tipo.
_FitActivityTypeVisual _activityTypeVisual(
  BuildContext context,
  FitActivityType type,
) {
  return switch (type) {
    FitActivityType.strength => _FitActivityTypeVisual(
      label: 'Musculação',
      icon: FitIcons.workout,
      color: context.colors.primary,
    ),
    FitActivityType.run => _FitActivityTypeVisual(
      label: 'Corrida',
      icon: FitIcons.running,
      color: context.fitColors.running,
    ),
    FitActivityType.walk => _FitActivityTypeVisual(
      label: 'Caminhada',
      icon: FitIcons.walking,
      color: context.fitColors.steps,
    ),
    FitActivityType.cycle => _FitActivityTypeVisual(
      label: 'Ciclismo',
      icon: FitIcons.cycling,
      color: context.fitColors.running,
    ),
    FitActivityType.cardio => _FitActivityTypeVisual(
      label: 'Cardio',
      icon: FitIcons.cardio,
      color: context.fitColors.energy,
    ),
    FitActivityType.steps => _FitActivityTypeVisual(
      label: 'Passos',
      icon: FitIcons.steps,
      color: context.fitColors.steps,
    ),
    FitActivityType.custom => _FitActivityTypeVisual(
      label: 'Outra',
      icon: FitIcons.activities,
      color: context.colors.onSurfaceVariant,
    ),
  };
}
