import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Skeleton simples e sem animacao para listas durante carregamento inicial.
///
/// Exemplo: `FitListSkeleton(itemCount: 4)`.
class FitListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const FitListSkeleton({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 72,
    this.padding = const EdgeInsets.all(FitSpacing.s16),
    this.spacing = FitSpacing.s12,
  }) : assert(itemCount > 0),
       assert(itemHeight > 0);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Carregando lista',
      liveRegion: true,
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: spacing),
        itemBuilder: (_, index) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: FitRadius.mediumBorder,
          ),
        ),
      ),
    );
  }
}
