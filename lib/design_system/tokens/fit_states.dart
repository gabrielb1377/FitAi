import 'package:flutter/material.dart';

import 'fit_colors.dart';

/// Tokens semânticos para estados recorrentes do FitIA.
///
/// Estados interativos usam [WidgetState]. Loading, feedback, bloqueio e
/// Premium são papéis semânticos; não formam uma enumeração global artificial.
abstract final class FitStateTokens {
  static const defaultSurface = FitColors.surface;
  static const pressedSurface = FitColors.primaryPressed;
  static const focusedBorder = FitColors.focus;
  static const selectedSurface = FitColors.surfaceSelected;
  static const disabledSurface = FitColors.surfaceDisabled;
  static const disabledContent = FitColors.textDisabled;

  static const loading = FitColors.info;
  static const success = FitColors.success;
  static const warning = FitColors.warning;
  static const error = FitColors.error;
  static const locked = FitColors.textTertiary;
  static const premium = FitColors.premium;

  static Color primaryControlBackground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return disabledSurface;
    if (states.contains(WidgetState.pressed)) return pressedSurface;
    return FitColors.primary;
  }

  static Color primaryControlForeground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return disabledContent;
    return FitColors.onPrimary;
  }
}
