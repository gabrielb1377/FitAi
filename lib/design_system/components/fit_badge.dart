import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Badge compacto para sinalizar novidades, IA, estado offline e acesso premium.
///
/// Exemplo: `FitBadge.ai()` ou `FitBadge(label: 'Destaque')`.
class FitBadge extends StatelessWidget {
  final String label;
  final FitBadgeTone tone;
  final IconData? icon;

  const FitBadge({
    super.key,
    required this.label,
    this.tone = FitBadgeTone.neutral,
    this.icon,
  });

  const FitBadge.newItem({super.key})
    : label = 'Novo',
      tone = FitBadgeTone.success,
      icon = Icons.fiber_new_rounded;

  const FitBadge.premium({super.key})
    : label = 'Premium',
      tone = FitBadgeTone.warning,
      icon = Icons.workspace_premium_rounded;

  const FitBadge.ai({super.key})
    : label = 'IA',
      tone = FitBadgeTone.info,
      icon = Icons.auto_awesome_rounded;

  const FitBadge.offline({super.key})
    : label = 'Offline',
      tone = FitBadgeTone.neutral,
      icon = Icons.cloud_off_rounded;

  const FitBadge.beta({super.key})
    : label = 'Beta',
      tone = FitBadgeTone.info,
      icon = Icons.science_outlined;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (tone) {
      FitBadgeTone.neutral => colors.secondary,
      FitBadgeTone.success => colors.primary,
      FitBadgeTone.warning => colors.tertiary,
      FitBadgeTone.info => colors.secondary,
      FitBadgeTone.danger => colors.error,
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s8,
          vertical: FitSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: FitRadius.pillBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: FitSpacing.s4),
            ],
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

enum FitBadgeTone { neutral, success, warning, info, danger }
