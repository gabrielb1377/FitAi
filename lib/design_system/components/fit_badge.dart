import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Marcador compacto de estado, categoria ou informacao curta.
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (tone) {
      FitBadgeTone.neutral => colors.secondary,
      FitBadgeTone.success => colors.primary,
      FitBadgeTone.warning => colors.tertiary,
      FitBadgeTone.danger => colors.error,
    };
    return Container(
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
    );
  }
}

enum FitBadgeTone { neutral, success, warning, danger }
