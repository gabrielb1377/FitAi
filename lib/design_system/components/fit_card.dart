import 'package:flutter/material.dart';

import '../tokens/fit_elevation.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Superficie FitIA composta por slots de cabecalho, conteudo e rodape.
///
/// Exemplo: `FitCard(title: 'Resumo', child: const Text('Conteudo'))`.
class FitCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? header;
  final Widget? footer;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final FitCardVariant variant;
  final int elevation;
  final Color? color;
  final String? semanticLabel;

  const FitCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.header,
    this.footer,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.all(FitSpacing.s16),
    this.onTap,
    this.variant = FitCardVariant.standard,
    this.elevation = 0,
    this.color,
    this.semanticLabel,
  }) : assert(elevation >= 0 && elevation <= 3),
       assert(header == null || (title == null && subtitle == null)),
       assert(variant != FitCardVariant.clickable || onTap != null);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clickable = variant == FitCardVariant.clickable || onTap != null;
    final background =
        color ??
        switch (variant) {
          FitCardVariant.filled => colors.surfaceContainerHighest,
          _ => colors.surface,
        };
    final borderColor = switch (variant) {
      FitCardVariant.outlined ||
      FitCardVariant.clickable => colors.outlineVariant,
      _ => Colors.transparent,
    };
    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            header!
          else if (title != null)
            _buildHeader(context),
          if (header != null || title != null)
            const SizedBox(height: FitSpacing.s12),
          child,
          if (footer != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: FitSpacing.s12),
              child: Divider(),
            ),
            footer!,
          ],
        ],
      ),
    );
    return Semantics(
      button: clickable,
      label: semanticLabel ?? title,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.largeBorder,
          side: BorderSide(color: borderColor),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: FitRadius.largeBorder,
            boxShadow: _shadowsFor(elevation),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: FitRadius.largeBorder,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
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
              Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: FitSpacing.s4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  List<BoxShadow> _shadowsFor(int value) => switch (value) {
    0 => FitElevation.level0,
    1 => FitElevation.level1,
    2 => FitElevation.level2,
    _ => FitElevation.level3,
  };
}

enum FitCardVariant { standard, outlined, filled, clickable }
