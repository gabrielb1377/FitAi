import 'package:flutter/material.dart';

import '../tokens/fit_layout.dart';
import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

/// Estado de sucesso para conclusoes e confirmacoes que merecem contexto.
class FitSuccessState extends StatelessWidget {
  const FitSuccessState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.check_circle_outline_rounded,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : assert((actionLabel == null) == (onAction == null)),
       assert((secondaryActionLabel == null) == (onSecondaryAction == null));

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: '$title. $description',
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: FitLayout.iconSizeState, color: colors.primary),
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
