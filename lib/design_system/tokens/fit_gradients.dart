import 'package:flutter/material.dart';

import 'fit_colors.dart';

/// Gradientes reservados para destaques reais, nunca para listas extensas.
abstract final class FitGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
  );

  static const ai = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [FitColors.info, Color(0xFF3155D9)],
  );

  static const achievement = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [FitColors.achievement, Color(0xFFFF7A45)],
  );

  static const surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [FitColors.surfaceElevated, FitColors.surface],
  );
}
