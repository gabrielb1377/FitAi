import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Agrupamento semântico de preferências.
class FitSettingsSection extends StatelessWidget {
  const FitSettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textTheme.titleMedium),
          if (description != null) ...[
            const SizedBox(height: FitSpacing.s4),
            Text(description!, style: context.textTheme.bodySmall),
          ],
          const SizedBox(height: FitSpacing.s8),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const SizedBox(height: FitSpacing.s4),
          ],
        ],
      ),
    );
  }
}

/// Item base de configuração.
class FitSettingsTile extends StatelessWidget {
  const FitSettingsTile({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: description,
      leading: icon == null
          ? null
          : Icon(icon, color: context.colors.onSurfaceVariant),
      trailing: trailing,
      onTap: onTap,
      enabled: enabled,
      semanticLabel: semanticLabel,
    );
  }
}

/// Preferência binária controlada externamente.
class FitSettingsSwitchTile extends StatelessWidget {
  const FitSettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    this.description,
    this.icon,
    this.enabled = true,
    this.onChanged,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FitSettingsTile(
      title: title,
      description: description,
      icon: icon,
      enabled: enabled,
      semanticLabel: '$title, ${value ? 'ativado' : 'desativado'}',
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}

/// Item que abre uma subseção ou fluxo.
class FitSettingsNavigationTile extends StatelessWidget {
  const FitSettingsNavigationTile({
    super.key,
    required this.title,
    this.description,
    this.valueLabel,
    this.icon,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String? description;
  final String? valueLabel;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final detail = [?description, ?valueLabel].join(' · ');
    return FitSettingsTile(
      title: title,
      description: detail.isEmpty ? null : detail,
      icon: icon,
      onTap: onTap,
      enabled: enabled,
      trailing: const Icon(FitIcons.forward),
    );
  }
}

/// Ação destrutiva de configuração, sem executar ou confirmar a ação.
class FitSettingsDangerTile extends StatelessWidget {
  const FitSettingsDangerTile({
    super.key,
    required this.title,
    this.description,
    this.icon = FitIcons.delete,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: description,
      leading: Icon(icon, color: context.colors.error),
      trailing: Icon(FitIcons.forward, color: context.colors.error),
      onTap: onTap,
      enabled: enabled,
      semanticLabel: 'Ação destrutiva, $title',
    );
  }
}

/// Cabeçalho de conta na área de configurações.
class FitSettingsAccountHeader extends StatelessWidget {
  const FitSettingsAccountHeader({
    super.key,
    required this.name,
    this.email,
    this.avatar,
    this.badge,
    this.onTap,
  });

  final String name;
  final String? email;
  final Widget? avatar;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: onTap,
      child: Row(
        children: [
          avatar ?? FitAvatar(name: name),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium,
                ),
                if (email != null)
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                if (badge != null) ...[
                  const SizedBox(height: FitSpacing.s8),
                  badge!,
                ],
              ],
            ),
          ),
          const Icon(FitIcons.forward),
        ],
      ),
    );
  }
}

/// Integração externa com estado controlado.
class FitIntegrationTile extends StatelessWidget {
  const FitIntegrationTile({
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
    return FitSettingsTile(
      title: name,
      description: description,
      icon: icon,
      onTap: onTap,
      trailing: FitDomainStatusBadge(
        label: connected ? 'Conectado' : 'Desconectado',
        tone: connected ? FitDomainTone.primary : FitDomainTone.neutral,
      ),
    );
  }
}

/// Permissão de sistema com estado controlado.
class FitPermissionTile extends StatelessWidget {
  const FitPermissionTile({
    super.key,
    required this.title,
    required this.granted,
    this.description,
    this.icon = FitIcons.permission,
    this.onTap,
  });

  final String title;
  final String? description;
  final bool granted;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitSettingsTile(
      title: title,
      description: description,
      icon: icon,
      onTap: onTap,
      trailing: FitDomainStatusBadge(
        label: granted ? 'Permitido' : 'Necessário',
        tone: granted ? FitDomainTone.primary : FitDomainTone.warning,
      ),
    );
  }
}

/// Uso de armazenamento com progresso externo.
class FitStorageUsageCard extends StatelessWidget {
  const FitStorageUsageCard({
    super.key,
    required this.valueLabel,
    required this.progress,
    this.title = 'Armazenamento',
    this.description,
    this.onTap,
  });

  final String title;
  final String valueLabel;
  final double progress;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: title,
      value: valueLabel,
      progress: progress,
      icon: FitIcons.storage,
      description: description,
      onTap: onTap,
    );
  }
}

/// Estado de backup informado pela aplicação.
class FitBackupStatusCard extends StatelessWidget {
  const FitBackupStatusCard({
    super.key,
    required this.statusLabel,
    this.title = 'Backup',
    this.description,
    this.synced = false,
    this.loading = false,
    this.onTap,
  });

  final String title;
  final String statusLabel;
  final String? description;
  final bool synced;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: description,
      icon: FitIcons.backup,
      loading: loading,
      tags: [
        FitDomainStatusBadge(
          label: statusLabel,
          tone: synced ? FitDomainTone.primary : FitDomainTone.warning,
        ),
      ],
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}
