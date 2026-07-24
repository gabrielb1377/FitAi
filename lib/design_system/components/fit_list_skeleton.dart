import 'package:flutter/material.dart';

import '../tokens/fit_layout.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import 'fit_skeleton.dart';

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
    this.itemHeight = FitLayout.skeletonListItemHeight,
    this.padding = const EdgeInsets.all(FitSpacing.s16),
    this.spacing = FitSpacing.s12,
  }) : assert(itemCount > 0),
       assert(itemHeight > 0);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando lista',
      liveRegion: true,
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: spacing),
        itemBuilder: (_, index) => FitSkeleton(
          height: itemHeight,
          borderRadius: FitRadius.mediumBorder,
          semanticLabel: 'Carregando item ${index + 1}',
        ),
      ),
    );
  }
}
