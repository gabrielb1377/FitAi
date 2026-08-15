import 'package:flutter/material.dart';

import 'fit_colors.dart';

/// Gradientes centralizados e restritos aos papéis observados no DS3.
///
/// Stops, direção e alpha continuam provisórios. Superfícies sólidas são o
/// padrão; gradientes não devem decorar listas ou substituir hierarquia.
abstract final class FitGradients {
  static const actionPrimary = LinearGradient(
    colors: [FitColors.primary, FitColors.primary],
  );

  static const mediaScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), FitColors.overlay],
  );

  static const chartArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [FitColors.primaryContainer, Color(0x00C9F548)],
  );

  static const aiGlow = LinearGradient(
    colors: [FitColors.aiContainer, FitColors.aiContainer],
  );

  static const premiumGlow = LinearGradient(
    colors: [FitColors.achievementContainer, FitColors.achievementContainer],
  );

  static const surfaceDepth = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [FitColors.surfaceRaised, FitColors.surfaceRaised],
  );

  // Aliases públicos preservados para a biblioteca existente.
  static const primary = actionPrimary;
  static const ai = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [FitColors.ai, FitColors.info],
  );
  static const achievement = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [FitColors.warning, FitColors.energy],
  );
  static const surface = surfaceDepth;

  // Gradientes legados permanecem centralizados até migração das telas.
  static const legacyRun = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6D00), Color(0xFFFFAB40)],
  );
  static const legacyXp = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
  );
  static const legacyCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF202622), Color(0xFF111512)],
  );
  static const legacyCardSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B211E), Color(0xFF0F1210)],
  );
  static const legacySteps = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF448AFF), Color(0xFF7C4DFF)],
  );
  static const legacyWorkout = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE040FB), Color(0xFF7C4DFF)],
  );
}
