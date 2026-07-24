import 'package:flutter/material.dart';

import 'fit_colors.dart';
import 'fit_typography.dart';

/// Aliases numéricos para manter valor, unidade e contexto previsíveis.
///
/// Formatação e localização dos números continuam responsabilidade da camada
/// de apresentação; estes tokens definem somente a hierarquia visual.
abstract final class FitNumberStyles {
  static const timer = FitTypography.metric;
  static const pace = FitTypography.metric;
  static const load = FitTypography.metricSmall;
  static const progress = FitTypography.metricSmall;
  static const percentage = FitTypography.metricSmall;
  static const table = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: FitColors.textPrimary,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const unit = FitTypography.label;
}
