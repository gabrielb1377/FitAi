import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

/// Estado de erro reutilizavel com tentativa opcional de recuperacao.
class FitErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const FitErrorState({
    super.key,
    this.title = 'Algo deu errado',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
  });

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
            Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
            const SizedBox(height: FitSpacing.s16),
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FitSpacing.s8),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: FitSpacing.s20),
              FitButton(
                label: retryLabel,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                variant: FitButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
