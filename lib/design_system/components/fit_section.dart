import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Agrupa um titulo, texto auxiliar e conteudo de uma secao de tela.
class FitSection extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FitSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: FitSpacing.s12),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleLarge)),
              ?action,
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: FitSpacing.s4),
            Text(description!, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: FitSpacing.s12),
          child,
        ],
      ),
    );
  }
}
