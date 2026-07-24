import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_layout.dart';

/// Indicador circular acessível para carregamentos locais.
class FitCircularLoading extends StatelessWidget {
  const FitCircularLoading({
    super.key,
    this.label = 'Carregando',
    this.size = FitLayout.loadingSizeInline,
    this.strokeWidth = FitLayout.loadingStroke,
    this.color,
  }) : assert(size > FitLayout.none),
       assert(strokeWidth > FitLayout.none);

  final String label;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Indicador linear determinado ou indeterminado com semântica de progresso.
class FitLinearLoading extends StatelessWidget {
  const FitLinearLoading({
    super.key,
    this.value,
    this.label = 'Carregando',
    this.color,
  }) : assert(value == null || (value >= 0 && value <= 1));

  final double? value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: label,
      value: normalized == null ? null : '${(normalized * 100).round()}%',
      liveRegion: true,
      child: ExcludeSemantics(
        child: LinearProgressIndicator(
          value: normalized,
          minHeight: FitLayout.progressCompactThickness,
          color: color ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(
            FitLayout.progressCompactThickness,
          ),
        ),
      ),
    );
  }
}
