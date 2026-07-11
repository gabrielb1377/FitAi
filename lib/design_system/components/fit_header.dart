import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Cabecalho de conteudo com titulo, subtitulo e acoes opcionais.
class FitHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const FitHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(
      FitSpacing.s20,
      FitSpacing.s16,
      FitSpacing.s20,
      FitSpacing.s12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: FitSpacing.s12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: FitSpacing.s4),
                  Text(subtitle!, style: textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
