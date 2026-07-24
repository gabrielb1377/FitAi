import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_card.dart';
import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Papel semântico de uma mensagem apresentada por [FitInfoCard].
enum FitInfoCardTone { neutral, info, success, warning, danger }

/// Mensagem contextual curta com ícone e ação opcional.
class FitInfoCard extends StatelessWidget {
  const FitInfoCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.tone = FitInfoCardTone.neutral,
    this.action,
    this.semanticLabel,
  });

  final String title;
  final String description;
  final IconData? icon;
  final FitInfoCardTone tone;
  final Widget? action;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      FitInfoCardTone.neutral => Theme.of(context).colorScheme.onSurfaceVariant,
      FitInfoCardTone.info => FitColors.info,
      FitInfoCardTone.success => FitColors.success,
      FitInfoCardTone.warning => FitColors.warning,
      FitInfoCardTone.danger => Theme.of(context).colorScheme.error,
    };
    return FitCard(
      variant: FitCardVariant.outlined,
      semanticLabel: semanticLabel ?? '$title. $description',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent),
            const SizedBox(width: FitSpacing.s12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: FitSpacing.s8),
            action!,
          ],
        ],
      ),
    );
  }
}
