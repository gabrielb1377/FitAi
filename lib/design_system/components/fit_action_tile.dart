import 'package:flutter/material.dart';

import '../tokens/fit_icons.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Linha de acao para configuracoes, menus e listas operacionais.
class FitActionTile extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  final bool destructive;

  const FitActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.description,
    this.trailing,
    this.color,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = destructive ? colors.error : color ?? colors.primary;
    return Semantics(
      button: onTap != null,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.mediumBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FitSpacing.s12,
                vertical: FitSpacing.s8,
              ),
              child: Row(
                children: [
                  Icon(icon, color: accent, size: 22),
                  const SizedBox(width: FitSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: destructive ? accent : null),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: FitSpacing.s2),
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
                  const SizedBox(width: FitSpacing.s8),
                  trailing ??
                      Icon(FitIcons.forward, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
