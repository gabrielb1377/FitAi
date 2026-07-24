import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../../navigation/navigation.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Cabeçalho de saudação da Home com identidade e ações do usuário.
class FitGreetingHeader extends StatelessWidget {
  const FitGreetingHeader({
    super.key,
    required this.greeting,
    required this.name,
    this.contextLabel,
    this.avatar,
    this.actions = const [],
  });

  final String greeting;
  final String name;
  final String? contextLabel;
  final Widget? avatar;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '$greeting, $name',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar ?? FitAvatar(name: name),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: context.textTheme.bodyMedium),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall,
                ),
                if (contextLabel != null)
                  Text(
                    contextLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium,
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: FitSpacing.s8),
            ...actions,
          ],
        ],
      ),
    );
  }
}

/// Resumo compacto das métricas mais importantes do dia.
class FitDailySummaryCard extends StatelessWidget {
  const FitDailySummaryCard({
    super.key,
    required this.metrics,
    this.title = 'Resumo do dia',
    this.subtitle,
    this.loading = false,
    this.onTap,
  });

  final List<FitMetricData> metrics;
  final String title;
  final String? subtitle;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.progress,
      metrics: metrics,
      loading: loading,
      onTap: onTap,
    );
  }
}

/// Destaque do treino previsto ou em andamento na Home.
class FitTodayWorkoutCard extends StatelessWidget {
  const FitTodayWorkoutCard({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.media,
    this.metrics = const [],
    this.progress,
    this.loading = false,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget? media;
  final List<FitMetricData> metrics;
  final double? progress;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: FitIcons.workout,
      media: media,
      metrics: metrics,
      progress: progress,
      loading: loading,
      enabled: enabled,
      footer: FitPrimaryButton(
        label: actionLabel,
        icon: FitIcons.play,
        onPressed: onAction,
        enabled: enabled,
        fullWidth: true,
      ),
    );
  }
}

/// Faixa responsiva das estatísticas rápidas da Home.
class FitQuickStatsRow extends StatelessWidget {
  const FitQuickStatsRow({
    super.key,
    required this.metrics,
    this.compact = true,
  });

  final List<FitMetricData> metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FitDomainMetricStrip(metrics: metrics, compact: compact);
  }
}

/// Card de sequência atual com melhor marca opcional.
class FitStreakCard extends StatelessWidget {
  const FitStreakCard({
    super.key,
    required this.value,
    this.label = 'Sequência',
    this.bestLabel,
    this.onTap,
  });

  final String value;
  final String label;
  final String? bestLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: label,
      value: value,
      progress: FitLayout.navigationSelectedScale,
      icon: FitIcons.streak,
      description: bestLabel,
      color: context.fitColors.achievement,
      onTap: onTap,
    );
  }
}

/// Meta diária com progresso já calculado pelo consumidor.
class FitDailyGoalCard extends StatelessWidget {
  const FitDailyGoalCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
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
      description: description,
      onTap: onTap,
    );
  }
}

/// Registro resumido de uma atividade recente.
class FitRecentActivityCard extends StatelessWidget {
  const FitRecentActivityCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: subtitle,
      leading: Icon(icon, color: context.colors.primary),
      trailing: trailing ?? const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Prévia de notificação com estado de leitura.
class FitNotificationPreview extends StatelessWidget {
  const FitNotificationPreview({
    super.key,
    required this.title,
    this.message,
    this.timeLabel,
    this.unread = false,
    this.onTap,
  });

  final String title;
  final String? message;
  final String? timeLabel;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: message,
      selected: unread,
      leading: Icon(
        FitIcons.notification,
        color: unread
            ? context.colors.primary
            : context.colors.onSurfaceVariant,
      ),
      trailing: timeLabel == null
          ? const Icon(FitIcons.forward)
          : Text(timeLabel!, style: context.textTheme.labelSmall),
      onTap: onTap,
      semanticLabel: unread ? '$title, não lida' : title,
    );
  }
}

/// Cabeçalho semântico das seções do dashboard.
class FitHomeSectionHeader extends FitSectionHeader {
  const FitHomeSectionHeader({
    super.key,
    required super.title,
    super.subtitle,
    super.action,
    super.badge,
    super.onViewAll,
    super.viewAllLabel,
  });
}

/// Item usado para ativar, ocultar ou ordenar blocos do dashboard.
class FitDashboardCustomizerTile extends StatelessWidget {
  const FitDashboardCustomizerTile({
    super.key,
    required this.title,
    required this.enabled,
    this.subtitle,
    this.leading,
    this.onChanged,
    this.dragHandle,
  });

  final String title;
  final String? subtitle;
  final bool enabled;
  final Widget? leading;
  final ValueChanged<bool>? onChanged;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: enabled, onChanged: onChanged),
          if (dragHandle != null) ...[
            const SizedBox(width: FitSpacing.s8),
            dragHandle!,
          ],
        ],
      ),
      semanticLabel: '$title, ${enabled ? 'visível' : 'oculto'}',
    );
  }
}
