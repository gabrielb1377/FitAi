import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Indicador de carregamento padrao para blocos ou paginas FitIA.
class FitLoading extends StatelessWidget {
  final String? label;
  final double size;

  const FitLoading({super.key, this.label, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
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
      ),
    );
  }
}
