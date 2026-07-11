import 'package:flutter/material.dart';

import '../tokens/fit_elevation.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Superficie reutilizavel FitIA para conteudo agrupado, com toque opcional.
class FitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final int elevation;
  final Color? color;

  const FitCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FitSpacing.s16),
    this.onTap,
    this.elevation = 0,
    this.color,
  }) : assert(elevation >= 0 && elevation <= 3);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: FitRadius.largeBorder,
          border: Border.all(color: colors.outlineVariant),
          boxShadow: _shadowsFor(elevation),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.largeBorder,
          child: content,
        ),
      ),
    );
  }

  List<BoxShadow> _shadowsFor(int value) {
    return switch (value) {
      0 => FitElevation.level0,
      1 => FitElevation.level1,
      2 => FitElevation.level2,
      _ => FitElevation.level3,
    };
  }
}
