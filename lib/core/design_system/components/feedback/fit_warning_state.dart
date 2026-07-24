import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_icons.dart';
import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Estado de atenção para situações recuperáveis que exigem decisão.
class FitWarningState extends StatelessWidget {
  const FitWarningState({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : assert((actionLabel == null) == (onAction == null)),
       assert((secondaryActionLabel == null) == (onSecondaryAction == null));

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: '$title. $description',
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FitIcons.warning,
                size: FitLayout.iconSizeState,
                color: FitColors.warning,
              ),
              const SizedBox(height: FitSpacing.s16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: FitSpacing.s8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (onAction != null) ...[
                const SizedBox(height: FitSpacing.s20),
                FitButton(label: actionLabel!, onPressed: onAction),
              ],
              if (onSecondaryAction != null) ...[
                const SizedBox(height: FitSpacing.s8),
                FitButton(
                  label: secondaryActionLabel!,
                  onPressed: onSecondaryAction,
                  variant: FitButtonVariant.ghost,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
