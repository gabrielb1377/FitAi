import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_card.dart';
import '../../../../design_system/components/fit_empty_state.dart';
import '../../../../design_system/components/fit_skeleton.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Estado vazio delimitado por uma superfície reutilizável.
class FitEmptyStateCard extends StatelessWidget {
  const FitEmptyStateCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.image,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : assert(icon == null || image == null),
       assert((actionLabel == null) == (onAction == null)),
       assert((secondaryActionLabel == null) == (onSecondaryAction == null));

  final String title;
  final String description;
  final IconData? icon;
  final Widget? image;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      child: FitEmptyState(
        title: title,
        description: description,
        icon: icon,
        image: image,
        actionLabel: actionLabel,
        onAction: onAction,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }
}

/// Skeleton genérico para preservar a geometria de cards durante o loading.
class FitLoadingCard extends StatelessWidget {
  const FitLoadingCard({super.key, this.semanticLabel = 'Carregando card'});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      semanticLabel: semanticLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            FitSkeleton(height: FitSpacing.s20),
            SizedBox(height: FitSpacing.s12),
            FitSkeleton(height: FitSpacing.s12),
            SizedBox(height: FitSpacing.s8),
            FitSkeleton(height: FitSpacing.s12),
          ],
        ),
      ),
    );
  }
}
