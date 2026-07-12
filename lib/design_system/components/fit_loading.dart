import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Indicador de carregamento FitIA para uso inline, pequeno ou em tela inteira.
///
/// Exemplos: `FitLoading.small()` e `FitLoading.fullScreen(label: 'Carregando')`.
class FitLoading extends StatelessWidget {
  final String? label;
  final double size;
  final FitLoadingLayout layout;

  const FitLoading.inline({super.key, this.label, this.size = 28})
    : layout = FitLoadingLayout.inline;

  const FitLoading.small({super.key, this.label})
    : size = 18,
      layout = FitLoadingLayout.inline;

  const FitLoading.fullScreen({super.key, this.label, this.size = 32})
    : layout = FitLoadingLayout.fullScreen;

  @override
  Widget build(BuildContext context) {
    final content = Semantics(
      label: label ?? 'Carregando',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
          if (label != null) ...[
            const SizedBox(height: FitSpacing.s12),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
    return layout == FitLoadingLayout.fullScreen
        ? SizedBox.expand(child: Center(child: content))
        : Center(child: content);
  }
}

enum FitLoadingLayout { inline, fullScreen }
