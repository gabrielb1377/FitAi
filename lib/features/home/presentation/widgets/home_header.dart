import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

/// Cabeçalho de saudacao do HOME-001, alinhado ao prototipo HTML canônico.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.unreadNotifications,
    required this.onOpenNotifications,
    required this.onCustomize,
    required this.now,
  });

  final String name;
  final int unreadNotifications;
  final VoidCallback onOpenNotifications;
  final VoidCallback onCustomize;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().isEmpty
        ? 'Atleta'
        : name.trim().split(RegExp(r'\s+')).first;
    final date = now();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        FitSpacing.s24,
        _horizontalPadding(context),
        FitSpacing.s16,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FitLayout.domainHomeMaxContentWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(date)}, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: FitSpacing.s2),
                    Text(
                      _formattedDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FitSpacing.s16),
              _NotificationAvatar(
                name: firstName,
                count: unreadNotifications,
                onTap: onOpenNotifications,
                onLongPress: onCustomize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= FitBreakpoints.largeTablet) return FitSpacing.s64;
    if (width >= FitBreakpoints.tablet) return FitSpacing.s32;
    return FitSpacing.s20;
  }

  String _greeting(DateTime value) {
    if (value.hour < 12) return 'Bom dia';
    if (value.hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _formattedDate(DateTime value) {
    const weekdays = <String>[
      'Segunda-feira',
      'Terca-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sabado',
      'Domingo',
    ];
    const months = <String>[
      'janeiro',
      'fevereiro',
      'marco',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${weekdays[value.weekday - 1]}, ${value.day} de ${months[value.month - 1]}';
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
      message: 'Notificacoes. Pressione e segure para personalizar.',
      child: Semantics(
        button: true,
        label: count > 0
            ? 'Abrir notificacoes, $count nao lidas'
            : 'Abrir notificacoes',
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
