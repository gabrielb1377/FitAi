import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

/// Cabeçalho compacto do HOME-001.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.currentStreak,
    required this.unreadNotifications,
    required this.onOpenNotifications,
    required this.onCustomize,
  });

  final String name;
  final int currentStreak;
  final int unreadNotifications;
  final VoidCallback onOpenNotifications;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().isEmpty
        ? 'Atleta'
        : name.trim().split(RegExp(r'\s+')).first;
    final compact =
        FitBreakpoints.isSmallMobile(MediaQuery.sizeOf(context).width) ||
        MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        FitSpacing.s12,
        _horizontalPadding(context),
        FitSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: FitColors.primary,
                size: FitLayout.iconSizeMedium,
              ),
              const SizedBox(width: FitSpacing.s4),
              Expanded(
                child: Text(
                  'FitIA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: FitSpacing.s8),
              _StreakPill(days: currentStreak, showLabel: !compact),
              SizedBox(width: compact ? FitSpacing.s8 : FitSpacing.s12),
              _NotificationAvatar(
                name: firstName,
                count: unreadNotifications,
                onTap: onOpenNotifications,
                onLongPress: onCustomize,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s20),
          Text(
            '${_greeting()}, $firstName!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.headlineMedium,
          ),
          const SizedBox(height: FitSpacing.s4),
          Text(
            'Pronto para evoluir hoje?',
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= FitBreakpoints.largeTablet) return FitSpacing.s64;
    if (width >= FitBreakpoints.tablet) return FitSpacing.s32;
    return FitSpacing.s20;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days, required this.showLabel});

  final int days;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$days dias de sequência',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            FitIcons.streak,
            size: FitLayout.iconSizeCompact,
            color: FitColors.achievement,
          ),
          const SizedBox(width: FitSpacing.s4),
          Text(
            '$days',
            style: context.textTheme.labelLarge?.copyWith(
              color: FitColors.textPrimary,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: FitSpacing.s4),
            Text('dias', style: context.textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({
    required this.name,
    required this.count,
    required this.onTap,
    required this.onLongPress,
  });

  final String name;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notificações. Pressione e segure para personalizar.',
      child: Semantics(
        button: true,
        label: count > 0
            ? 'Abrir notificações, $count não lidas'
            : 'Abrir notificações',
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FitAvatar(name: name, size: FitAvatarSize.medium),
              if (count > 0)
                Positioned(
                  top: FitLayout.none,
                  right: FitLayout.none,
                  child: Container(
                    width: FitSpacing.s12,
                    height: FitSpacing.s12,
                    decoration: BoxDecoration(
                      color: FitColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FitColors.background,
                        width: FitLayout.borderThin,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
