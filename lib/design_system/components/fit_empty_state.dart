import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

/// Estado vazio reutilizavel com acao opcional para orientar o proximo passo.
class FitEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FitEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FitSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.primary),
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
          ],
        ),
      ),
    );
  }
}
