import 'package:flutter/material.dart';

import '../../../../../design_system/components/fit_progress.dart';
import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Avatar de perfil com fallback por nome.
class FitProfileAvatar extends StatelessWidget {
  const FitProfileAvatar({
    super.key,
    this.image,
    this.name,
    this.onTap,
    this.semanticLabel,
  });

  final ImageProvider<Object>? image;
  final String? name;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FitAvatar(
      image: image,
      name: name,
      size: FitAvatarSize.large,
      onTap: onTap,
      tooltip: onTap == null ? null : 'Abrir perfil',
      semanticLabel: semanticLabel,
    );
  }
}

/// Badge do nível atual do usuário.
class FitLevelBadge extends StatelessWidget {
  const FitLevelBadge({super.key, required this.label});

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

/// Card de XP e progresso para o próximo nível.
class FitXPProgressCard extends StatelessWidget {
  const FitXPProgressCard({
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
      description: nextLevelLabel,
      color: context.fitColors.xp,
    );
  }
}

/// Card de conquista com estado bloqueado ou concluído.
class FitAchievementCard extends StatelessWidget {
  const FitAchievementCard({super.key, required this.data, this.onTap});

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
      tags: [FitAchievementBadge(unlocked: data.unlocked)],
      onTap: onTap,
    );
  }
}

/// Badge compacto do estado de conquista.
class FitAchievementBadge extends StatelessWidget {
  const FitAchievementBadge({super.key, required this.unlocked, this.label});

  final bool unlocked;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return FitDomainStatusBadge(
      label: label ?? (unlocked ? 'Conquistada' : 'Bloqueada'),
      tone: unlocked ? FitDomainTone.achievement : FitDomainTone.neutral,
      icon: unlocked ? FitIcons.achievement : FitIcons.lock,
    );
  }
}

/// Métrica corporal em card.
class FitBodyMetricCard extends StatelessWidget {
  const FitBodyMetricCard({super.key, required this.data, this.onTap});

  final FitMetricData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitMetricCard(
      label: data.label,
      value: '${data.value}${data.unit == null ? '' : ' ${data.unit}'}',
      icon: data.icon,
      detail: data.detail,
      color: data.color,
      onTap: onTap,
    );
  }
}

/// Evolução de peso com progresso já calculado.
class FitWeightProgressCard extends StatelessWidget {
  const FitWeightProgressCard({
    super.key,
    required this.valueLabel,
    required this.progress,
    this.title = 'Peso',
    this.description,
    this.points = const [],
  });

  final String title;
  final String valueLabel;
  final double progress;
  final String? description;
  final List<FitChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      subtitle: description,
      leading: Icon(FitIcons.weight, color: context.colors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valueLabel, style: context.textTheme.headlineSmall),
          const SizedBox(height: FitSpacing.s12),
          FitProgress(value: progress),
          if (points.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s16),
            FitDomainBarChart(
              points: points,
              semanticLabel: 'Evolução de peso',
            ),
          ],
        ],
      ),
    );
  }
}

/// Linha de uma medida corporal.
class FitMeasurementRow extends StatelessWidget {
  const FitMeasurementRow({
    super.key,
    required this.label,
    required this.valueLabel,
    this.changeLabel,
    this.onTap,
  });

  final String label;
  final String valueLabel;
  final String? changeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: label,
      subtitle: changeLabel,
      leading: Icon(FitIcons.distance, color: context.colors.primary),
      trailing: Text(valueLabel, style: context.textTheme.titleSmall),
      onTap: onTap,
    );
  }
}

/// Foto de progresso fornecida pela aplicação.
class FitProgressPhotoCard extends StatelessWidget {
  const FitProgressPhotoCard({
    super.key,
    required this.dateLabel,
    this.media,
    this.description,
    this.onTap,
  });

  final String dateLabel;
  final Widget? media;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: dateLabel,
      subtitle: description,
      icon: FitIcons.progress,
      media: FitDomainMedia(
        fallbackLabel: 'Foto indisponível',
        fallbackIcon: FitIcons.person,
        child: media,
      ),
      onTap: onTap,
    );
  }
}

/// Recorde pessoal do perfil.
class FitPersonalRecordCard extends StatelessWidget {
  const FitPersonalRecordCard({
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

/// Estatística geral do perfil.
class FitProfileStatisticCard extends StatelessWidget {
  const FitProfileStatisticCard({super.key, required this.data, this.onTap});

  final FitMetricData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitBodyMetricCard(data: data, onTap: onTap);
  }
}

/// Item de menu do perfil.
class FitProfileMenuTile extends StatelessWidget {
  const FitProfileMenuTile({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String? description;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: description,
      leading: Icon(icon, color: context.colors.onSurfaceVariant),
      trailing: trailing ?? const Icon(FitIcons.forward),
      onTap: onTap,
      enabled: enabled,
    );
  }
}

/// Dispositivo ou serviço de saúde conectado.
class FitConnectedDeviceCard extends StatelessWidget {
  const FitConnectedDeviceCard({
    super.key,
    required this.name,
    this.description,
    this.connected = false,
    this.icon = FitIcons.integration,
    this.onTap,
  });

  final String name;
  final String? description;
  final bool connected;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: description,
      icon: icon,
      tags: [
        FitDomainStatusBadge(
          label: connected ? 'Conectado' : 'Desconectado',
          tone: connected ? FitDomainTone.primary : FitDomainTone.neutral,
        ),
      ],
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Cabeçalho de perfil público, sem lógica social.
class FitPublicProfileHeader extends StatelessWidget {
  const FitPublicProfileHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.avatar,
    this.badge,
    this.action,
  });

  final String name;
  final String? subtitle;
  final Widget? avatar;
  final Widget? badge;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Perfil de $name',
      child: Column(
        children: [
          avatar ?? FitProfileAvatar(name: name),
          const SizedBox(height: FitSpacing.s12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: FitSpacing.s4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ],
          if (badge != null) ...[const SizedBox(height: FitSpacing.s8), badge!],
          if (action != null) ...[
            const SizedBox(height: FitSpacing.s12),
            action!,
          ],
        ],
      ),
    );
  }
}
