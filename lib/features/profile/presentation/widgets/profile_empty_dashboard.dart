import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

/// Estado inicial do Perfil sem fabricar métricas ou conquistas.
class ProfileEmptyDashboard extends StatelessWidget {
  const ProfileEmptyDashboard({
    super.key,
    required this.displayName,
    required this.onEdit,
    required this.onSettings,
    required this.onPrivacy,
  });

  final String? displayName;
  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final name = _resolvedName(displayName);
    return CustomScrollView(
      key: const PageStorageKey('profile-empty-scroll'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s20,
            FitSpacing.s16,
            FitSpacing.s20,
            FitSpacing.s40,
          ),
          sliver: SliverList.list(
            children: [
              FitHeader(
                title: 'Perfil',
                subtitle: 'Sua identidade e preferencias.',
                padding: EdgeInsets.zero,
                actions: [
                  FitIconButton(
                    icon: FitIcons.settings,
                    tooltip: 'Abrir configuracoes',
                    onPressed: onSettings,
                  ),
                ],
              ),
              const SizedBox(height: FitSpacing.s24),
              FitProfileHeader(
                name: name,
                subtitle: 'Complete seus dados no seu ritmo.',
                padding: EdgeInsets.zero,
                action: FitIconButton(
                  icon: FitIcons.edit,
                  tooltip: 'Editar perfil',
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(height: FitSpacing.s32),
              FitCard(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderColor: Theme.of(context).colorScheme.primary,
                showBorder: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      FitIcons.profile,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: FitSpacing.s16),
                    Text(
                      'Seu Perfil esta pronto para comecar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: FitSpacing.s8),
                    Text(
                      'Adicione apenas os dados que ajudam a acompanhar sua evolucao. Nada aqui bloqueia seu treino.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: FitSpacing.s20),
                    FitButton(
                      label: 'Editar perfil',
                      leadingIcon: FitIcons.edit,
                      expand: true,
                      onPressed: onEdit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FitSpacing.s32),
              const FitSectionHeader(
                title: 'Comece pelo essencial',
                subtitle: 'Ajustes que deixam o FitIA com a sua cara.',
              ),
              const SizedBox(height: FitSpacing.s12),
              FitCard(
                child: Column(
                  children: [
                    FitActionTile(
                      title: 'Dados pessoais',
                      description: 'Nome, foto, peso e altura',
                      icon: FitIcons.edit,
                      onTap: onEdit,
                    ),
                    const FitDivider(verticalSpacing: FitSpacing.s8),
                    FitActionTile(
                      title: 'Configuracoes',
                      description: 'Tema, unidades, notificacoes e saude',
                      icon: FitIcons.settings,
                      onTap: onSettings,
                    ),
                    const FitDivider(verticalSpacing: FitSpacing.s8),
                    FitActionTile(
                      title: 'Privacidade',
                      description: 'Dados, permissoes e seguranca',
                      icon: FitIcons.private,
                      onTap: onPrivacy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _resolvedName(String? value) {
    final normalized = value?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        normalized.toLowerCase() == 'atleta') {
      return 'Seu perfil';
    }
    return normalized;
  }
}
