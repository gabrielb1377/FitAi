import 'package:flutter/material.dart';

import '../tokens/fit_colors.dart';
import '../tokens/fit_icons.dart';
import 'fit_card.dart';

/// Superficie base reservada para conteudo do Coach FitIA.
class FitCoachCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final VoidCallback? onTap;

  const FitCoachCard({
    super.key,
    this.title = 'Coach FitIA',
    this.subtitle,
    required this.child,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FitCard(
      title: title,
      subtitle: subtitle,
      leading: const Icon(FitIcons.coach, color: FitColors.ai),
      trailing: action,
      onTap: onTap,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      semanticLabel: title,
      child: child,
    );
  }
}
