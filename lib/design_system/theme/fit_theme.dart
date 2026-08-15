import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/fit_colors.dart';
import '../tokens/fit_elevation.dart';
import '../tokens/fit_layout.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import '../tokens/fit_states.dart';
import '../tokens/fit_typography.dart';
import 'fit_theme_extensions.dart';

/// Tema global oficial do FitIA Design System 3.0.
///
/// Os temas claro e escuro possuem paletas próprias e compartilham apenas os
/// papéis semânticos, a escala tipográfica e as regras estruturais.
abstract final class FitTheme {
  /// Tema claro desenhado como paleta propria, sem inverter o tema escuro.
  static ThemeData light() {
    final darkTheme = dark();
    final textTheme = FitTypography.textTheme.apply(
      bodyColor: FitLightColors.textPrimary,
      displayColor: FitLightColors.textPrimary,
    );
    final lightInputBorder = OutlineInputBorder(
      borderRadius: FitRadius.mediumBorder,
      borderSide: const BorderSide(
        color: FitLightColors.borderSubtle,
        width: FitLayout.borderThin,
      ),
    );

    return darkTheme.copyWith(
      brightness: Brightness.light,
      colorScheme: FitLightColors.colorScheme,
      scaffoldBackgroundColor: FitLightColors.background,
      textTheme: textTheme,
      extensions: const [FitSemanticColors.light(), FitThemeGradients.light()],
      iconTheme: const IconThemeData(
        color: FitLightColors.textSecondary,
        size: FitLayout.iconSize,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FitLightColors.background,
        foregroundColor: FitLightColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: FitElevation.materialBackground,
        scrolledUnderElevation: FitElevation.materialBackground,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: FitLightColors.textPrimary),
      ),
      cardTheme: const CardThemeData(
        color: FitLightColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: FitElevation.materialCard,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitLightColors.primary,
          foregroundColor: FitLightColors.colorScheme.onPrimary,
          disabledBackgroundColor: FitLightColors.borderSubtle,
          disabledForegroundColor: FitLightColors.textDisabled,
          minimumSize: const Size(0, FitLayout.minimumTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.button,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FitLightColors.primary,
          foregroundColor: FitLightColors.colorScheme.onPrimary,
          disabledBackgroundColor: FitLightColors.borderSubtle,
          disabledForegroundColor: FitLightColors.textDisabled,
          minimumSize: const Size(0, FitLayout.minimumTouchTarget),
          elevation: FitElevation.materialBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FitLightColors.textPrimary,
          disabledForegroundColor: FitLightColors.textDisabled,
          minimumSize: const Size(0, FitLayout.minimumTouchTarget),
          side: const BorderSide(color: FitLightColors.borderStrong),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FitLightColors.primary,
          disabledForegroundColor: FitLightColors.textDisabled,
          minimumSize: const Size(
            FitLayout.minimumTouchTarget,
            FitLayout.minimumTouchTarget,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: FitLightColors.textPrimary,
          disabledForegroundColor: FitLightColors.textDisabled,
          minimumSize: const Size(
            FitLayout.compactTouchTarget,
            FitLayout.compactTouchTarget,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
        ),
      ),
      inputDecorationTheme: darkTheme.inputDecorationTheme.copyWith(
        fillColor: FitLightColors.surfaceRaised,
        border: lightInputBorder,
        enabledBorder: lightInputBorder,
        focusedBorder: lightInputBorder.copyWith(
          borderSide: const BorderSide(
            color: FitLightColors.primary,
            width: FitLayout.borderFocused,
          ),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: FitLightColors.textSecondary,
        ),
        hintStyle: textTheme.bodySmall?.copyWith(
          color: FitLightColors.textTertiary,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: FitLightColors.textSecondary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: FitLightColors.error),
        prefixIconColor: FitLightColors.textSecondary,
        suffixIconColor: FitLightColors.textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FitLightColors.card,
        selectedColor: FitLightColors.primaryContainer,
        disabledColor: FitLightColors.backgroundSubtle,
        side: const BorderSide(color: FitLightColors.borderSubtle),
        shape: const RoundedRectangleBorder(borderRadius: FitRadius.pillBorder),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s8),
      ),
      dividerTheme: const DividerThemeData(
        color: FitLightColors.borderSubtle,
        thickness: FitLayout.borderThin,
        space: FitLayout.borderThin,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FitLightColors.surfaceRaised,
        modalBackgroundColor: FitLightColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: FitLightColors.textTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.bottomSheetBorder,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: FitLightColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: FitElevation.materialDialog,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.xLargeBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FitLightColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: FitLightColors.surface,
        ),
        actionTextColor: FitLightColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        elevation: FitElevation.materialFloatingControl,
        shape: const RoundedRectangleBorder(
          borderRadius: FitRadius.mediumBorder,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FitLightColors.primary,
        linearTrackColor: FitLightColors.borderSubtle,
        circularTrackColor: FitLightColors.borderSubtle,
        linearMinHeight: FitLayout.progressThickness,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: FitLightColors.primary,
        inactiveTrackColor: FitLightColors.borderSubtle,
        thumbColor: FitLightColors.primary,
        overlayColor: FitLightColors.primaryContainer,
        valueIndicatorColor: FitLightColors.textPrimary,
        trackHeight: FitLayout.sliderTrackHeight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return FitLightColors.textDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return FitLightColors.primary;
          }
          return FitLightColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return FitLightColors.backgroundSubtle;
          }
          if (states.contains(WidgetState.selected)) {
            return FitLightColors.primaryContainer;
          }
          return FitLightColors.cardInner;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(
          FitLightColors.borderStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FitLightColors.primary;
          }
          return FitLightColors.surfaceRaised;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: FitLightColors.borderStrong),
        shape: const RoundedRectangleBorder(
          borderRadius: FitRadius.smallBorder,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return FitLightColors.textDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return FitLightColors.primary;
          }
          return FitLightColors.textSecondary;
        }),
      ),
      navigationBarTheme: darkTheme.navigationBarTheme.copyWith(
        backgroundColor: FitLightColors.surface,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? FitLightColors.primary
                : FitLightColors.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? FitLightColors.primary
                : FitLightColors.textTertiary,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FitLightColors.surface,
        selectedItemColor: FitLightColors.primary,
        unselectedItemColor: FitLightColors.textTertiary,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: FitLightColors.surface,
        selectedIconTheme: const IconThemeData(color: FitLightColors.primary),
        unselectedIconTheme: const IconThemeData(
          color: FitLightColors.textTertiary,
        ),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: FitLightColors.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: FitLightColors.textTertiary,
        ),
        indicatorColor: FitLightColors.primaryContainer,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FitLightColors.primary,
        foregroundColor: Colors.white,
        elevation: FitElevation.materialFloatingControl,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s16,
          vertical: FitSpacing.s4,
        ),
        minVerticalPadding: FitSpacing.s8,
        iconColor: FitLightColors.textSecondary,
        textColor: FitLightColors.textPrimary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
      ),
      disabledColor: FitLightColors.textDisabled,
      hoverColor: FitLightColors.primaryContainer,
      focusColor: FitLightColors.primaryContainer,
      highlightColor: FitLightColors.primaryContainer,
      splashColor: FitLightColors.primaryContainer,
    );
  }

  static ThemeData dark() {
    final inputBorder = OutlineInputBorder(
      borderRadius: FitRadius.mediumBorder,
      borderSide: const BorderSide(
        color: FitColors.outlineSoft,
        width: FitLayout.borderThin,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: FitColors.colorScheme,
      scaffoldBackgroundColor: FitColors.background,
      textTheme: FitTypography.textTheme,
      visualDensity: VisualDensity.standard,
      extensions: const [FitSemanticColors.dark(), FitThemeGradients.dark()],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      iconTheme: const IconThemeData(
        color: FitColors.textSecondary,
        size: FitLayout.iconSize,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FitColors.background,
        foregroundColor: FitColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: FitElevation.materialBackground,
        scrolledUnderElevation: FitElevation.materialBackground,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: FitColors.textPrimary),
        titleTextStyle: FitTypography.title,
      ),
      dividerTheme: const DividerThemeData(
        color: FitColors.divider,
        thickness: FitLayout.borderThin,
        space: FitLayout.borderThin,
      ),
      cardTheme: const CardThemeData(
        color: FitColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: FitElevation.materialCard,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
        margin: EdgeInsets.symmetric(vertical: FitSpacing.legacyXs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, FitLayout.minimumTouchTarget),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: WidgetStateProperty.resolveWith(
            FitStateTokens.primaryControlBackground,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            FitStateTokens.primaryControlForeground,
          ),
          overlayColor: const WidgetStatePropertyAll(
            FitColors.primaryContainer,
          ),
          elevation: const WidgetStatePropertyAll(
            FitElevation.materialBackground,
          ),
          textStyle: const WidgetStatePropertyAll(FitTypography.button),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: FitRadius.mediumBorder),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, FitLayout.minimumTouchTarget),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: WidgetStateProperty.resolveWith(
            FitStateTokens.primaryControlBackground,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            FitStateTokens.primaryControlForeground,
          ),
          overlayColor: const WidgetStatePropertyAll(
            FitColors.primaryContainer,
          ),
          elevation: const WidgetStatePropertyAll(
            FitElevation.materialBackground,
          ),
          textStyle: const WidgetStatePropertyAll(FitTypography.button),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: FitRadius.mediumBorder),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FitColors.primary,
          disabledForegroundColor: FitColors.textDisabled,
          minimumSize: const Size(0, FitLayout.minimumTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
          side: const BorderSide(
            color: FitColors.outline,
            width: FitLayout.borderThin,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.button,
          overlayColor: FitColors.primaryContainer,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FitColors.primary,
          disabledForegroundColor: FitColors.textDisabled,
          minimumSize: const Size(
            FitLayout.minimumTouchTarget,
            FitLayout.minimumTouchTarget,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          textStyle: FitTypography.button,
          overlayColor: FitColors.primaryContainer,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: FitColors.textPrimary,
          disabledForegroundColor: FitColors.textDisabled,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(
            FitLayout.compactTouchTarget,
            FitLayout.compactTouchTarget,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
          hoverColor: FitColors.primaryContainer,
          focusColor: FitColors.primaryContainer,
          highlightColor: FitColors.primaryContainer,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s16,
          vertical: FitSpacing.s12,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: FitColors.borderSubtle,
            width: FitLayout.borderThin,
          ),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: FitColors.focus,
            width: FitLayout.borderFocused,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: FitColors.error,
            width: FitLayout.borderThin,
          ),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: FitColors.error,
            width: FitLayout.borderFocused,
          ),
        ),
        labelStyle: FitTypography.label,
        hintStyle: FitTypography.caption,
        helperStyle: FitTypography.caption,
        errorStyle: FitTypography.caption.copyWith(color: FitColors.error),
        prefixIconColor: FitColors.textSecondary,
        suffixIconColor: FitColors.textSecondary,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: FitColors.card,
        selectedColor: FitColors.surfaceSelected,
        disabledColor: FitColors.surfaceDisabled,
        side: BorderSide(
          color: FitColors.outlineSoft,
          width: FitLayout.borderThin,
        ),
        shape: RoundedRectangleBorder(borderRadius: FitRadius.pillBorder),
        labelStyle: FitTypography.chip,
        padding: EdgeInsets.symmetric(horizontal: FitSpacing.s8),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: FitColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: FitElevation.materialDialog,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.xLargeBorder,
          side: BorderSide(
            color: FitColors.outline,
            width: FitLayout.borderThin,
          ),
        ),
        titleTextStyle: FitTypography.heading,
        contentTextStyle: FitTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FitColors.surfaceRaised,
        modalBackgroundColor: FitColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: FitElevation.materialBottomSheet,
        modalElevation: FitElevation.materialBottomSheet,
        showDragHandle: true,
        dragHandleColor: FitColors.textTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.bottomSheetBorder,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: FitColors.surfaceRaised,
        contentTextStyle: FitTypography.body,
        actionTextColor: FitColors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: FitElevation.materialFloatingControl,
        insetPadding: EdgeInsets.fromLTRB(
          FitSpacing.s16,
          0,
          FitSpacing.s16,
          FitSpacing.s20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.mediumBorder,
          side: BorderSide(
            color: FitColors.outline,
            width: FitLayout.borderThin,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FitColors.primary,
        linearTrackColor: FitColors.outlineSoft,
        circularTrackColor: FitColors.outlineSoft,
        linearMinHeight: FitLayout.progressThickness,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: FitColors.primary,
        inactiveTrackColor: FitColors.outlineSoft,
        thumbColor: FitColors.primary,
        overlayColor: FitColors.primaryContainer,
        valueIndicatorColor: FitColors.surfaceRaised,
        valueIndicatorTextStyle: FitTypography.label,
        trackHeight: FitLayout.sliderTrackHeight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return FitColors.textDisabled;
          }
          if (states.contains(WidgetState.selected)) return FitColors.primary;
          return FitColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return FitColors.surfaceDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return FitColors.primaryContainer;
          }
          return FitColors.surfaceRaised;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(FitColors.outlineSoft),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return FitColors.surfaceDisabled;
          }
          if (states.contains(WidgetState.selected)) return FitColors.primary;
          return FitColors.surfaceRaised;
        }),
        checkColor: const WidgetStatePropertyAll(FitColors.onPrimary),
        side: const BorderSide(
          color: FitColors.outline,
          width: FitLayout.borderThin,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: FitRadius.smallBorder,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return FitColors.textDisabled;
          }
          if (states.contains(WidgetState.selected)) return FitColors.primary;
          return FitColors.textSecondary;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: FitLayout.navigationBarHeight,
        elevation: FitElevation.materialSurface,
        backgroundColor: FitColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: FitColors.surfaceSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? FitColors.primary : FitColors.textTertiary,
            size: selected ? FitLayout.selectedIconSize : FitLayout.iconSize,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return FitTypography.navigation.copyWith(
            color: selected ? FitColors.primary : FitColors.textTertiary,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: FitColors.primary,
        unselectedItemColor: FitColors.textTertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: FitElevation.materialSurface,
        selectedLabelStyle: FitTypography.navigation,
        unselectedLabelStyle: FitTypography.navigation,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: FitColors.surface,
        elevation: FitElevation.materialSurface,
        selectedIconTheme: IconThemeData(
          color: FitColors.primary,
          size: FitLayout.selectedIconSize,
        ),
        unselectedIconTheme: IconThemeData(
          color: FitColors.textTertiary,
          size: FitLayout.iconSize,
        ),
        selectedLabelTextStyle: FitTypography.navigation,
        unselectedLabelTextStyle: FitTypography.navigation,
        indicatorColor: FitColors.surfaceSelected,
        useIndicator: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FitColors.primary,
        foregroundColor: FitColors.onPrimary,
        elevation: FitElevation.materialFloatingControl,
        focusElevation: FitElevation.materialFloatingControl,
        hoverElevation: FitElevation.materialFloatingControl,
        highlightElevation: FitElevation.materialFloatingControl,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: FitSpacing.s16,
          vertical: FitSpacing.s4,
        ),
        minVerticalPadding: FitSpacing.s8,
        iconColor: FitColors.textSecondary,
        textColor: FitColors.textPrimary,
        titleTextStyle: FitTypography.title,
        subtitleTextStyle: FitTypography.subtitle,
      ),
      disabledColor: FitColors.textDisabled,
      hoverColor: FitColors.primaryContainer,
      focusColor: FitColors.primaryContainer,
      highlightColor: FitColors.primaryContainer,
      splashColor: FitColors.primaryContainer,
    );
  }
}
