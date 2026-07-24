import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Bloco de skeleton leve para compor estados de carregamento especificos.
class FitSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadiusGeometry borderRadius;
  final String semanticLabel;

  const FitSkeleton({
    super.key,
    this.height = FitSpacing.s12,
    this.width,
    this.borderRadius = FitRadius.smallBorder,
    this.semanticLabel = 'Carregando conteudo',
  }) : assert(height > 0),
       assert(width == null || width > 0);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}
