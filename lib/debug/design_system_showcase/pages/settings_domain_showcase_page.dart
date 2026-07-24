import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Configurações.
class SettingsDomainShowcasePage extends StatelessWidget {
  const SettingsDomainShowcasePage({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return const DomainShowcaseScaffold(
      title: 'Configurações',
      children: [
        FitSettingsSection(
          title: 'Aplicativo',
          description: 'Preferências gerais',
          children: [
            FitSettingsTile(
              title: 'Tema',
              description: 'Escuro',
              icon: FitIcons.settings,
            ),
          ],
        ),
        FitSettingsTile(
          title: 'Sobre',
          description: 'Versão e informações legais',
          icon: FitIcons.info,
          onTap: _noop,
        ),
        FitSettingsSwitchTile(
          title: 'Notificações',
          description: 'Lembretes de treino',
          icon: FitIcons.notification,
          value: true,
          onChanged: _ignoreBool,
        ),
        FitSettingsNavigationTile(
          title: 'Idioma',
          valueLabel: 'Português',
          icon: FitIcons.public,
          onTap: _noop,
        ),
        FitSettingsDangerTile(
          title: 'Excluir conta',
          description: 'A confirmação pertence à aplicação',
          onTap: _noop,
        ),
        FitSettingsAccountHeader(
          name: 'Gabriel',
          email: 'gabriel@fitia.dev',
          onTap: _noop,
        ),
        FitIntegrationTile(
          name: 'Health Connect',
          description: 'Dados de saúde',
          connected: true,
          onTap: _noop,
        ),
        FitPermissionTile(
          title: 'Localização',
          description: 'Necessária durante corridas',
          granted: false,
          onTap: _noop,
        ),
        FitStorageUsageCard(
          valueLabel: '420 MB de 1 GB',
          progress: .42,
          description: 'Mídias e dados offline',
        ),
        FitBackupStatusCard(
          statusLabel: 'Sincronizado',
          description: 'Hoje, 09:41',
          synced: true,
          onTap: _noop,
        ),
        FitSettingsTile(
          title: 'Opção indisponível',
          icon: FitIcons.lock,
          enabled: false,
        ),
        DomainShowcaseStates(emptyTitle: 'Sem configurações'),
      ],
    );
  }
}

void _ignoreBool(bool _) {}
