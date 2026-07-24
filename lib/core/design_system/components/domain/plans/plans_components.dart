import 'package:flutter/material.dart';

import '../../../../../design_system/components/components.dart'
    show FitChip, FitProgress;
import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Estados visuais suportados pelos componentes de plano.
enum FitPlanStatus {
  active,
  paused,
  completed,
  archived,
  public,
  private,
  locked,
  loading,
}

/// Card compacto para listas densas de planos.
class FitPlanCompactCard extends StatelessWidget {
  const FitPlanCompactCard({
    super.key,
    required this.name,
    this.subtitle,
    this.status = FitPlanStatus.active,
    this.progress,
    this.onTap,
    this.enabled = true,
  });

  final String name;
  final String? subtitle;
  final FitPlanStatus status;
  final double? progress;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: name,
      subtitle: subtitle,
      enabled: enabled,
      leading: Icon(FitIcons.plans, color: context.colors.primary),
      trailing: FitPlanStatusBadge(status: status),
      onTap: onTap,
      semanticLabel: 'Plano $name',
    );
  }
}

/// Cabeçalho de plano com identidade, status e ação contextual.
class FitPlanHeader extends StatelessWidget {
  const FitPlanHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.status = FitPlanStatus.active,
    this.leading,
    this.action,
  });

  final String name;
  final String? subtitle;
  final FitPlanStatus status;
  final Widget? leading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Plano $name',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading ??
              Icon(
                FitIcons.plans,
                size: FitLayout.iconSizeLarge,
                color: context.colors.primary,
              ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: FitSpacing.s4),
                  Text(subtitle!, style: context.textTheme.bodyMedium),
                ],
                const SizedBox(height: FitSpacing.s8),
                FitPlanStatusBadge(status: status),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: FitSpacing.s8),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Progresso rotulado do plano.
class FitPlanProgress extends StatelessWidget {
  const FitPlanProgress({
    super.key,
    required this.value,
    this.label = 'Progresso do plano',
    this.trailing,
  });

  final double value;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return FitProgress(
      value: value,
      label: label,
      trailing: trailing,
      animate: true,
    );
  }
}

/// Badge semântico para status, visibilidade e bloqueio de plano.
class FitPlanStatusBadge extends StatelessWidget {
  const FitPlanStatusBadge({super.key, required this.status});

  final FitPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (status) {
      FitPlanStatus.active => ('Ativo', FitDomainTone.primary, FitIcons.play),
      FitPlanStatus.paused => (
        'Pausado',
        FitDomainTone.warning,
        FitIcons.pause,
      ),
      FitPlanStatus.completed => (
        'Concluído',
        FitDomainTone.primary,
        FitIcons.success,
      ),
      FitPlanStatus.archived => (
        'Arquivado',
        FitDomainTone.neutral,
        FitIcons.archive,
      ),
      FitPlanStatus.public => ('Público', FitDomainTone.info, FitIcons.public),
      FitPlanStatus.private => (
        'Privado',
        FitDomainTone.neutral,
        FitIcons.private,
      ),
      FitPlanStatus.locked => (
        'Bloqueado',
        FitDomainTone.neutral,
        FitIcons.lock,
      ),
      FitPlanStatus.loading => (
        'Carregando',
        FitDomainTone.neutral,
        FitIcons.time,
      ),
    };
    return FitDomainStatusBadge(label: label, tone: tone, icon: icon);
  }
}

/// Seletor horizontal ou quebrável de semanas do plano.
class FitPlanWeekSelector extends StatelessWidget {
  const FitPlanWeekSelector({super.key, required this.weeks, this.onSelected});

  final List<FitPlanWeekData> weeks;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FitSpacing.s8,
      runSpacing: FitSpacing.s8,
      children: [
        for (var index = 0; index < weeks.length; index++)
          FitChip(
            label: weeks[index].label,
            selected: weeks[index].current,
            enabled: !weeks[index].locked,
            icon: weeks[index].locked
                ? FitIcons.lock
                : weeks[index].completed
                ? FitIcons.check
                : null,
            onSelected: weeks[index].locked || onSelected == null
                ? null
                : (_) => onSelected!(index),
          ),
      ],
    );
  }
}

/// Card de um dia de treino dentro do plano.
class FitWorkoutDayCard extends StatelessWidget {
  const FitWorkoutDayCard({
    super.key,
    required this.name,
    this.subtitle,
    this.metrics = const [],
    this.completed = false,
    this.locked = false,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final List<FitMetricData> metrics;
  final bool completed;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: subtitle,
      icon: locked
          ? FitIcons.lock
          : completed
          ? FitIcons.success
          : FitIcons.workout,
      metrics: metrics,
      enabled: !locked,
      onTap: onTap,
      trailing: const Icon(FitIcons.forward),
    );
  }
}

/// Linha de exercício na composição de um plano.
class FitPlanExerciseRow extends StatelessWidget {
  const FitPlanExerciseRow({
    super.key,
    required this.name,
    this.details,
    this.media,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String name;
  final String? details;
  final Widget? media;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: name,
      subtitle: details,
      enabled: enabled,
      leading:
          media ??
          Icon(FitIcons.exercise, color: context.colors.onSurfaceVariant),
      trailing: trailing ?? const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Opção de origem para o fluxo de criação de plano.
class FitPlanCreationOptionCard extends StatelessWidget {
  const FitPlanCreationOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.tone = FitDomainTone.primary,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String description;
  final IconData icon;
  final FitDomainTone tone;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: description,
      icon: icon,
      accent: resolveFitDomainTone(context, tone),
      enabled: enabled,
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Resumo do plano antes de confirmar criação ou importação.
class FitPlanSummaryCard extends StatelessWidget {
  const FitPlanSummaryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.metrics = const [],
    this.tags = const [],
    this.action,
    this.loading = false,
  });

  final String title;
  final String? subtitle;
  final List<FitMetricData> metrics;
  final List<Widget> tags;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.plans,
      tags: tags,
      metrics: metrics,
      footer: action,
      loading: loading,
    );
  }
}

/// Estatística isolada do plano em uma superfície compacta.
class FitPlanStatisticCard extends StatelessWidget {
  const FitPlanStatisticCard({super.key, required this.metric, this.onTap});

  final FitMetricData metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitMetricCard(
      label: metric.label,
      value: '${metric.value}${metric.unit == null ? '' : ' ${metric.unit}'}',
      icon: metric.icon,
      detail: metric.detail,
      color: metric.color,
      onTap: onTap,
    );
  }
}

/// Comparação visual entre duas propriedades ou versões de plano.
class FitPlanComparisonCard extends StatelessWidget {
  const FitPlanComparisonCard({
    super.key,
    required this.title,
    required this.currentLabel,
    required this.comparisonLabel,
    this.description,
    this.positive = true,
  });

  final String title;
  final String currentLabel;
  final String comparisonLabel;
  final String? description;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      subtitle: description,
      child: Row(
        children: [
          Expanded(
            child: Text(currentLabel, style: context.textTheme.titleMedium),
          ),
          Icon(FitIcons.forward, color: context.colors.onSurfaceVariant),
          const SizedBox(width: FitSpacing.s8),
          Expanded(
            child: Text(
              comparisonLabel,
              textAlign: TextAlign.end,
              style: context.textTheme.titleMedium?.copyWith(
                color: positive ? context.colors.primary : context.colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Template reutilizável para iniciar um novo plano.
class FitPlanTemplateCard extends StatelessWidget {
  const FitPlanTemplateCard({
    super.key,
    required this.name,
    this.description,
    this.media,
    this.tags = const [],
    this.onTap,
  });

  final String name;
  final String? description;
  final Widget? media;
  final List<Widget> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: description,
      icon: FitIcons.plans,
      media: media,
      tags: tags,
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Plano arquivado com ação explícita de restauração.
class FitArchivedPlanCard extends StatelessWidget {
  const FitArchivedPlanCard({
    super.key,
    required this.name,
    this.description,
    this.restoreLabel = 'Restaurar',
    this.onRestore,
    this.onTap,
  });

  final String name;
  final String? description;
  final String restoreLabel;
  final VoidCallback? onRestore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: description,
      icon: FitIcons.archive,
      tags: const [
        FitDomainStatusBadge(
          label: 'Arquivado',
          tone: FitDomainTone.neutral,
          icon: FitIcons.archive,
        ),
      ],
      trailing: const Icon(FitIcons.forward),
      footer: FitGhostButton(
        label: restoreLabel,
        icon: FitIcons.retry,
        onPressed: onRestore,
      ),
      onTap: onTap,
    );
  }
}
