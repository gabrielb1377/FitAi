import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

/// Atalhos de Perfil; cada destino continua pertencendo a sua propria rota.
class ProfileShortcutsSection extends StatelessWidget {
  const ProfileShortcutsSection({
    super.key,
    required this.onEdit,
    required this.onSettings,
    required this.onPrivacy,
    required this.onExport,
    required this.onHelp,
  });

  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final VoidCallback onPrivacy;
  final VoidCallback onExport;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return FitSection(
      title: 'Atalhos',
      child: FitCard(
        child: Column(
          children: [
            FitActionTile(
              title: 'Editar perfil',
              description: 'Nome, foto e dados pessoais',
              icon: FitIcons.edit,
              onTap: onEdit,
            ),
            const FitDivider(verticalSpacing: FitSpacing.s8),
            FitActionTile(
              title: 'Configuracoes',
              description: 'Preferencias e permissoes',
              icon: FitIcons.settings,
              onTap: onSettings,
            ),
            const FitDivider(verticalSpacing: FitSpacing.s8),
            FitActionTile(
              title: 'Privacidade',
              description: 'Dados e visibilidade',
              icon: FitIcons.private,
              onTap: onPrivacy,
            ),
            const FitDivider(verticalSpacing: FitSpacing.s8),
            FitActionTile(
              title: 'Exportar dados',
              description: 'Disponivel em uma proxima etapa',
              icon: FitIcons.share,
              onTap: onExport,
            ),
            const FitDivider(verticalSpacing: FitSpacing.s8),
            FitActionTile(
              title: 'Ajuda',
              description: 'Suporte e orientacoes',
              icon: FitIcons.info,
              onTap: onHelp,
            ),
          ],
        ),
      ),
    );
  }
}
