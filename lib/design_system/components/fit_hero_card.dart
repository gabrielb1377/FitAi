import 'package:flutter/material.dart';

import '../tokens/fit_elevation.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Destaque principal para contexto, resumo e uma unica acao dominante.
///
/// Exemplo: `FitHeroCard(title: 'Treino A', icon: Icons.fitness_center)`.
class FitHeroCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData icon;
  final Color? accentColor;
  final Gradient? gradient;
  final Widget? badge;
  final Widget? child;
  final Widget? action;
  final VoidCallback? onTap;

  const FitHeroCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.eyebrow,
    this.accentColor,
    this.gradient,
    this.badge,
    this.child,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = accentColor ?? colors.primary;
    return Semantics(
      button: onTap != null,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: gradient == null ? colors.surface : null,
            gradient: gradient,
            borderRadius: FitRadius.largeBorder,
            border: Border.all(color: colors.outlineVariant),
            boxShadow: FitElevation.level1,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: FitRadius.largeBorder,
            child: Padding(
              padding: const EdgeInsets.all(FitSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(30),
                          borderRadius: FitRadius.mediumBorder,
                        ),
                        child: Icon(icon, color: accent),
                      ),
                      const SizedBox(width: FitSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null) ...[
                              Text(
                                eyebrow!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: accent),
                              ),
                              const SizedBox(height: FitSpacing.s4),
                            ],
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: FitSpacing.s4),
                              Text(
                                subtitle!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: FitSpacing.s8),
                        badge!,
                      ],
                    ],
                  ),
                  if (child != null) ...[
                    const SizedBox(height: FitSpacing.s20),
                    child!,
                  ],
                  if (action != null) ...[
                    const SizedBox(height: FitSpacing.s20),
                    action!,
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
