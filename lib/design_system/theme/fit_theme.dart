import 'package:flutter/material.dart';

import '../tokens/fit_colors.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import '../tokens/fit_typography.dart';

/// Tema opcional do Design System para adocao gradual.
///
/// Ele nao substitui `AppTheme` nesta sprint. Telas futuras poderao adota-lo
/// quando a migracao visual for planejada.
abstract final class FitTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: FitColors.colorScheme,
      scaffoldBackgroundColor: FitColors.background,
      textTheme: FitTypography.textTheme,
      iconTheme: const IconThemeData(color: FitColors.textSecondary, size: 22),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s16,
          vertical: FitSpacing.s12,
        ),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: FitColors.outline),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: FitTypography.label),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: FitColors.surfaceVariant,
        selectedColor: Color(0x2400E676),
        side: BorderSide(color: FitColors.outlineSoft),
        shape: RoundedRectangleBorder(borderRadius: FitRadius.pillBorder),
        labelStyle: FitTypography.caption,
        padding: EdgeInsets.symmetric(horizontal: FitSpacing.s8),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: FitColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FitColors.surface,
        modalBackgroundColor: FitColors.surface,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FitRadius.large),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: FitColors.surfaceElevated,
        contentTextStyle: FitTypography.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.mediumBorder),
      ),
    );
  }
}
