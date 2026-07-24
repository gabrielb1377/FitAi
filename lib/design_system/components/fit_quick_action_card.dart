import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_layout.dart';
import '../tokens/fit_opacity.dart';
import '../tokens/fit_spacing.dart';

/// Atalho compacto para uma acao clara como IA, manual ou biblioteca.
class FitQuickActionCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool selected;

  const FitQuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.description,
    this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? accent.withValues(alpha: FitOpacity.selected)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.largeBorder,
          side: BorderSide(color: selected ? accent : colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.largeBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FitLayout.domainQuickActionMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(FitSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: accent),
                  const SizedBox(height: FitSpacing.s16),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: FitSpacing.s4),
                    Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
