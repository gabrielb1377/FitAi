import 'package:flutter/material.dart';

import '../tokens/fit_colors.dart';

/// Cores de dominio que nao cabem no [ColorScheme] sem perder significado.
@immutable
class FitSemanticColors extends ThemeExtension<FitSemanticColors> {
  const FitSemanticColors({
    required this.ai,
    required this.running,
    required this.steps,
    required this.achievement,
    required this.surfaceSubtle,
  });

  const FitSemanticColors.dark()
    : ai = FitColors.ai,
      running = FitColors.running,
      steps = FitColors.steps,
      achievement = FitColors.achievement,
      surfaceSubtle = FitColors.surfaceSubtle;

  final Color ai;
  final Color running;
  final Color steps;
  final Color achievement;
  final Color surfaceSubtle;

  @override
  FitSemanticColors copyWith({
    Color? ai,
    Color? running,
    Color? steps,
    Color? achievement,
    Color? surfaceSubtle,
  }) {
    return FitSemanticColors(
      ai: ai ?? this.ai,
      running: running ?? this.running,
      steps: steps ?? this.steps,
      achievement: achievement ?? this.achievement,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
    );
  }

  @override
  FitSemanticColors lerp(covariant FitSemanticColors? other, double t) {
    if (other == null) return this;

    return FitSemanticColors(
      ai: Color.lerp(ai, other.ai, t)!,
      running: Color.lerp(running, other.running, t)!,
      steps: Color.lerp(steps, other.steps, t)!,
      achievement: Color.lerp(achievement, other.achievement, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
    );
  }
}

extension FitThemeDataExtensions on ThemeData {
  /// Retorna a extensao semantica com fallback seguro durante a migracao.
  FitSemanticColors get fitSemanticColors =>
      extension<FitSemanticColors>() ?? const FitSemanticColors.dark();
}
