import 'package:flutter/material.dart';

/// Paleta central do novo Design System FitIA.
///
/// Os valores preservam a identidade atual do aplicativo. `AppColors` continua
/// disponivel durante a migracao gradual das telas existentes.
abstract final class FitColors {
  /// Acao principal e confirmacao positiva da marca.
  static const primary = Color(0xFF00E676);
  static const primaryDark = Color(0xFF00C853);
  static const primaryLight = Color(0xFF69F0AE);

  static const background = Color(0xFF070808);
  static const surface = Color(0xFF101312);
  static const surfaceVariant = Color(0xFF191D1B);
  static const surfaceElevated = Color(0xFF202622);
  static const outline = Color(0xFF2A332E);
  static const outlineSoft = Color(0xFF1F2823);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB1B8B3);
  static const textHint = Color(0xFF717971);

  static const info = Color(0xFF448AFF);
  static const ai = info;
  static const warning = Color(0xFFFFC857);
  static const danger = Color(0xFFFF5C7A);
  static const success = primary;
  static const running = Color(0xFFFF8A50);
  static const energy = running;
  static const steps = info;
  static const achievement = Color(0xFFFF9F43);

  static const onPrimary = Colors.black;
  static const onInfo = Colors.white;
  static const onAchievement = Colors.black;

  static const colorScheme = ColorScheme.dark(
    primary: primary,
    onPrimary: onPrimary,
    secondary: info,
    onSecondary: onInfo,
    tertiary: achievement,
    onTertiary: onAchievement,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: surfaceVariant,
    outline: outline,
    outlineVariant: outlineSoft,
    error: danger,
    onError: Colors.black,
  );
}
