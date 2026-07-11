import 'package:flutter/material.dart';

import 'fit_colors.dart';

/// Tipografia sem dependencia de fonte externa para manter o app leve.
abstract final class FitTypography {
  static const display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: FitColors.textPrimary,
    height: 1.1,
  );
  static const headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: FitColors.textPrimary,
    height: 1.2,
  );
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: FitColors.textPrimary,
    height: 1.3,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: FitColors.textSecondary,
    height: 1.45,
  );
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FitColors.textSecondary,
    letterSpacing: 0.4,
  );
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: FitColors.textHint,
    height: 1.3,
  );

  static const textTheme = TextTheme(
    displayLarge: display,
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: FitColors.textPrimary,
      height: 1.12,
    ),
    headlineLarge: headline,
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: FitColors.textPrimary,
      height: 1.25,
    ),
    titleLarge: title,
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: FitColors.textPrimary,
      height: 1.3,
    ),
    bodyLarge: body,
    bodyMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: FitColors.textSecondary,
      height: 1.4,
    ),
    labelLarge: label,
    labelSmall: caption,
  );
}
