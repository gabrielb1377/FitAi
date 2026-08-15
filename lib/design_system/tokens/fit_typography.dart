import 'package:flutter/material.dart';

import 'fit_colors.dart';

/// Escala tipográfica semântica do FitIA Design System Next.
///
/// Os tamanhos preservam a escala já usada pelo app e permanecem provisórios
/// até medição controlada. A família é o fallback da plataforma; nenhuma fonte
/// externa é exigida nesta sprint.
abstract final class FitTypography {
  static const display = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: FitColors.textPrimary,
    height: 1.1,
  );
  static const heading = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: FitColors.textPrimary,
    height: 1.2,
  );
  static const headline = heading;
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: FitColors.textPrimary,
    height: 1.3,
  );
  static const subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: FitColors.textSecondary,
    height: 1.4,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: FitColors.textPrimary,
    height: 1.45,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: FitColors.textSecondary,
    height: 1.3,
    letterSpacing: 0,
  );
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: FitColors.textHint,
    height: 1.3,
  );
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0,
  );
  static const chip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FitColors.textSecondary,
    height: 1.2,
    letterSpacing: 0,
  );
  static const navigation = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: FitColors.textSecondary,
    height: 1.2,
    letterSpacing: 0,
  );
  static const metric = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: FitColors.textPrimary,
    height: 1.12,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const metricSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: FitColors.textPrimary,
    height: 1.15,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: FitColors.textSecondary,
    height: 1.2,
    letterSpacing: 0,
  );

  static const textTheme = TextTheme(
    displayLarge: display,
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: FitColors.textPrimary,
      height: 1.12,
    ),
    displaySmall: metric,
    headlineLarge: heading,
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: FitColors.textPrimary,
      height: 1.25,
    ),
    headlineSmall: title,
    titleLarge: title,
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: FitColors.textPrimary,
      height: 1.3,
    ),
    bodyLarge: body,
    bodyMedium: subtitle,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: FitColors.textSecondary,
      height: 1.2,
      letterSpacing: 0,
    ),
    labelSmall: caption,
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: FitColors.textPrimary,
      height: 1.3,
    ),
  );
}
