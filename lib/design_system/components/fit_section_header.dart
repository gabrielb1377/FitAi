import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Cabecalho de secao sem impor layout ao conteudo que vem depois.
class FitSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? badge;
  final VoidCallback? onViewAll;
  final String viewAllLabel;

  const FitSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.badge,
    this.onViewAll,
    this.viewAllLabel = 'Ver tudo',
  }) : assert(action == null || onViewAll == null);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: FitSpacing.s4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        if (badge != null) ...[const SizedBox(width: FitSpacing.s8), badge!],
        if (action != null || onViewAll != null) ...[
          const SizedBox(width: FitSpacing.s12),
          action ?? TextButton(onPressed: onViewAll, child: Text(viewAllLabel)),
        ],
      ],
    );
  }
}
