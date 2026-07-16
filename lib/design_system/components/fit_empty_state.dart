import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

/// Estado vazio com icone ou imagem e uma acao opcional orientada ao usuario.
///
/// Exemplo: `FitEmptyState(icon: Icons.list_alt, title: 'Sem planos', description: '...')`.
class FitEmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? image;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const FitEmptyState({
    super.key,
    this.icon,
    this.image,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : assert(icon == null || image == null),
       assert((actionLabel == null) == (onAction == null)),
       assert((secondaryActionLabel == null) == (onSecondaryAction == null));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        label: '$title. $description',
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image != null)
                image!
              else if (icon != null)
                Icon(icon, size: 40, color: colors.primary),
              if (image != null || icon != null)
                const SizedBox(height: FitSpacing.s16),
              Text(
                title,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FitSpacing.s8),
              Text(
                description,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
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
