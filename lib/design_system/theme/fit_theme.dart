import 'package:flutter/material.dart';

import '../tokens/fit_colors.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_typography.dart';

/// Tema opcional do Design System para adocao gradual.
///
/// Ele nao substitui `AppTheme` nesta sprint. Telas futuras poderao adotá-lo
/// quando a migracao visual for planejada.
abstract final class FitTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: FitColors.colorScheme,
      scaffoldBackgroundColor: FitColors.background,
      textTheme: FitTypography.textTheme,
      dividerTheme: const DividerThemeData(
        color: FitColors.outlineSoft,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: FitColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitColors.surface,
        border: OutlineInputBorder(
          borderRadius: FitRadius.mediumBorder,
          borderSide: const BorderSide(color: FitColors.outlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FitRadius.mediumBorder,
          borderSide: const BorderSide(color: FitColors.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FitRadius.mediumBorder,
          borderSide: const BorderSide(color: FitColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
