import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Agrupa conteudo com titulo, subtitulo e acao opcional de "Ver tudo".
///
/// Exemplo: `FitSection(title: 'Recentes', onViewAll: openAll, child: list)`.
class FitSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onViewAll;
  final String viewAllLabel;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double contentSpacing;

  const FitSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.onViewAll,
    this.viewAllLabel = 'Ver tudo',
    this.padding = const EdgeInsets.symmetric(vertical: FitSpacing.s16),
    this.contentSpacing = FitSpacing.s12,
  }) : assert(action == null || onViewAll == null);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trailing =
        action ??
        (onViewAll == null
            ? null
            : TextButton(onPressed: onViewAll, child: Text(viewAllLabel)));
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleLarge)),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: FitSpacing.s4),
            Text(subtitle!, style: textTheme.bodyMedium),
          ],
          SizedBox(height: contentSpacing),
          child,
        ],
      ),
    );
  }
}
