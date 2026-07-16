import 'package:flutter/material.dart';

import '../tokens/fit_colors.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import '../tokens/fit_typography.dart';
import 'fit_theme_extensions.dart';

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
      extensions: const [FitSemanticColors.dark()],
      iconTheme: const IconThemeData(color: FitColors.textSecondary, size: 22),
      appBarTheme: const AppBarTheme(
        backgroundColor: FitColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: FitColors.textPrimary),
        titleTextStyle: FitTypography.title,
      ),
      dividerTheme: const DividerThemeData(
        color: FitColors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: FitColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.largeBorder,
          side: BorderSide(color: FitColors.outlineSoft),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitColors.surfaceElevated,
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
        errorBorder: OutlineInputBorder(
          borderRadius: FitRadius.mediumBorder,
          borderSide: const BorderSide(color: FitColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: FitRadius.mediumBorder,
          borderSide: const BorderSide(color: FitColors.error, width: 1.5),
        ),
        labelStyle: FitTypography.body,
        hintStyle: FitTypography.caption,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitColors.primary,
          foregroundColor: FitColors.onPrimary,
          disabledBackgroundColor: FitColors.surfaceElevated,
          disabledForegroundColor: FitColors.textDisabled,
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FitColors.primary,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: FitColors.outline),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FitColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: FitTypography.label,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: FitColors.textPrimary,
          minimumSize: const Size(44, 44),
          overlayColor: FitColors.primaryContainer,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: FitColors.surfaceVariant,
        selectedColor: FitColors.primaryContainer,
        side: BorderSide(color: FitColors.outlineSoft),
        shape: RoundedRectangleBorder(borderRadius: FitRadius.pillBorder),
        labelStyle: FitTypography.caption,
        padding: EdgeInsets.symmetric(horizontal: FitSpacing.s8),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: FitColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.xLargeBorder,
          side: BorderSide(color: FitColors.outline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FitColors.surface,
        modalBackgroundColor: FitColors.surface,
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
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
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FitColors.primary,
        linearTrackColor: FitColors.outlineSoft,
        linearMinHeight: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: FitColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: FitColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? FitColors.primary : FitColors.textHint,
            size: selected ? 24 : 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return FitTypography.caption.copyWith(
            color: selected ? FitColors.primary : FitColors.textHint,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: FitColors.primary,
        unselectedItemColor: FitColors.textHint,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FitColors.primary,
        foregroundColor: FitColors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? FitColors.primary
              : FitColors.surfaceElevated;
        }),
        checkColor: const WidgetStatePropertyAll(FitColors.onPrimary),
        side: const BorderSide(color: FitColors.outline),
        shape: const RoundedRectangleBorder(
          borderRadius: FitRadius.smallBorder,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? FitColors.primary
              : FitColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? FitColors.primaryContainer
              : FitColors.surfaceElevated;
        }),
      ),
      disabledColor: FitColors.textDisabled,
      hoverColor: FitColors.primaryContainer,
      focusColor: FitColors.primaryContainer,
      highlightColor: FitColors.primaryContainer,
      splashColor: FitColors.primaryContainer,
    );
  }
}
