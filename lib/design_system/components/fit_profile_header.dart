import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Identidade do usuario fora de card, com avatar, contexto e acao opcional.
class FitProfileHeader extends StatelessWidget {
  final String name;
  final String? subtitle;
  final Widget? avatar;
  final Widget? badge;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const FitProfileHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.avatar,
    this.badge,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: FitSpacing.s20),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      label: name,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            avatar ??
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: FitRadius.largeBorder,
                  ),
                  child: Icon(Icons.person_rounded, color: colors.primary),
                ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: FitSpacing.s4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (badge != null) ...[
                    const SizedBox(height: FitSpacing.s8),
                    badge!,
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: FitSpacing.s8),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
