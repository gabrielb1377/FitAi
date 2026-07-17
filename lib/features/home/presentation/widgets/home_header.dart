import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.level,
    required this.xp,
    required this.unreadNotifications,
    required this.onOpenNotifications,
    required this.onOpenProfile,
  });

  final String name;
  final int level;
  final int xp;
  final int unreadNotifications;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().isEmpty
        ? 'Atleta'
        : name.trim().split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s16,
        FitSpacing.s20,
        FitSpacing.s20,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $firstName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineMedium,
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  'Nivel $level  -  $xp XP',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _NotificationButton(
            count: unreadNotifications,
            onTap: onOpenNotifications,
          ),
          const SizedBox(width: FitSpacing.s8),
          Tooltip(
            message: 'Abrir perfil',
            child: Semantics(
              button: true,
              label: 'Abrir perfil de $firstName',
              child: InkWell(
                onTap: onOpenProfile,
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: context.colors.primaryContainer,
                  child: Text(
                    firstName.characters.first.toUpperCase(),
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FitIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Abrir notificacoes',
          onPressed: onTap,
          variant: FitIconButtonVariant.outlined,
        ),
        if (count > 0)
          Positioned(
            right: 1,
            top: 1,
            child: Semantics(
              label: '$count notificacoes nao lidas',
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
