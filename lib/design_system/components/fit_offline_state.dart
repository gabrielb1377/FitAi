import 'package:flutter/material.dart';

import '../tokens/fit_breakpoints.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

/// Aviso offline reutilizavel. Pode ser usado de forma compacta sobre dados em
/// cache ou como estado completo quando nenhum dado local estiver disponivel.
class FitOfflineState extends StatelessWidget {
  const FitOfflineState({
    super.key,
    this.title = 'Sem conexao',
    this.description = 'Mostrando dados salvos neste dispositivo.',
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
    this.compact = false,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  }) : assert((secondaryActionLabel == null) == (onSecondaryAction == null));

  final String title;
  final String description;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.cloud_off_rounded, color: colors.secondary),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: FitSpacing.s4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
              if (!compact && onRetry != null) ...[
                const SizedBox(height: FitSpacing.s12),
                FitButton(
                  label: retryLabel,
                  onPressed: onRetry,
                  variant: FitButtonVariant.outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return Semantics(
      liveRegion: true,
      label: '$title. $description',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final action = TextButton(
            onPressed: onRetry,
            child: Text(retryLabel),
          );
          final compactActionBelow =
              compact &&
              onRetry != null &&
              FitBreakpoints.isSmallMobile(constraints.maxWidth);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(FitSpacing.s12),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: FitRadius.mediumBorder,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact && onRetry != null && !compactActionBelow)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: message),
                      action,
                    ],
                  )
                else
                  message,
                if (compactActionBelow) ...[
                  const SizedBox(height: FitSpacing.s8),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
                if (!compact && onSecondaryAction != null) ...[
                  const SizedBox(height: FitSpacing.s8),
                  FitButton(
                    label: secondaryActionLabel!,
                    onPressed: onSecondaryAction,
                    variant: FitButtonVariant.ghost,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
