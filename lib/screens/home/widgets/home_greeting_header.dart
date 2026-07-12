import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import 'home_notification_bell.dart';

/// Cabecalho sem card para orientar o usuario antes do conteudo da Home.
class HomeGreetingHeader extends StatelessWidget {
  final String name;
  final int level;
  final int unreadNotifications;
  final VoidCallback? onOpenNotifications;

  const HomeGreetingHeader({
    super.key,
    required this.name,
    required this.level,
    required this.unreadNotifications,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().isEmpty
        ? 'Atleta'
        : name.trim().split(' ').first;
    final greeting = _greeting();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        FitSpacing.s20,
        MediaQuery.paddingOf(context).top + FitSpacing.s16,
        FitSpacing.s20,
        FitSpacing.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: context.textTheme.bodyMedium),
                const SizedBox(height: FitSpacing.s2),
                Text(firstName, style: context.textTheme.headlineLarge),
              ],
            ),
          ),
          HomeNotificationBell(
            count: unreadNotifications,
            onTap: onOpenNotifications,
          ),
          const SizedBox(width: FitSpacing.s8),
          CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.surfaceContainerHighest,
            child: Text(
              firstName[0].toUpperCase(),
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.primary,
              ),
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          FitBadge(
            label: 'Nv. $level',
            icon: Icons.bolt_rounded,
            tone: FitBadgeTone.success,
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}
