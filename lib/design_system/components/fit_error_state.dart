import 'package:flutter/material.dart';

import '../tokens/fit_layout.dart';
import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

/// Estado de erro com icone, detalhes tecnicos opcionais e acao de recuperacao.
///
/// Exemplo: `FitErrorState(error: 'Nao foi possivel carregar.', onRetry: reload)`.
class FitErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String error;
  final String? details;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const FitErrorState({
    super.key,
    this.icon = Icons.error_outline_rounded,
    this.title = 'Algo deu errado',
    required this.error,
    this.details,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : assert((secondaryActionLabel == null) == (onSecondaryAction == null));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        label: '$title. $error',
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: FitLayout.iconSizeState, color: colors.error),
              const SizedBox(height: FitSpacing.s16),
              Text(
                title,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FitSpacing.s8),
              Text(
                error,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (details != null) ...[
                const SizedBox(height: FitSpacing.s8),
                Text(
                  details!,
                  style: textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: FitSpacing.s20),
                FitButton(
                  label: retryLabel,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  variant: FitButtonVariant.outlined,
                ),
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
