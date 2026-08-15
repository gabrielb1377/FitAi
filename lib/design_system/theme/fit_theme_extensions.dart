import 'package:flutter/material.dart';

import '../tokens/fit_colors.dart';
import '../tokens/fit_gradients.dart';

/// Cores de domínio e superfícies que não cabem no [ColorScheme].
@immutable
class FitSemanticColors extends ThemeExtension<FitSemanticColors> {
  const FitSemanticColors({
    required this.ai,
    required this.running,
    required this.steps,
    required this.achievement,
    required this.premium,
    required this.energy,
    required this.xp,
    required this.chartProgress,
    required this.chartInformation,
    required this.chartEnergy,
    required this.chartLimit,
    required this.surfaceSubtle,
    required this.surfaceRaised,
    required this.card,
    required this.cardInner,
    required this.overlayScrim,
    required this.selectedSurface,
    required this.disabledSurface,
  });

  const FitSemanticColors.dark()
    : ai = FitColors.ai,
      running = FitColors.running,
      steps = FitColors.steps,
      achievement = FitColors.achievement,
      premium = FitColors.premium,
      energy = FitColors.energy,
      xp = FitColors.xp,
      chartProgress = FitColors.primary,
      chartInformation = FitColors.info,
      chartEnergy = FitColors.energy,
      chartLimit = FitColors.error,
      surfaceSubtle = FitColors.backgroundSubtle,
      surfaceRaised = FitColors.surfaceRaised,
      card = FitColors.card,
      cardInner = FitColors.cardInner,
      overlayScrim = FitColors.overlay,
      selectedSurface = FitColors.surfaceSelected,
      disabledSurface = FitColors.surfaceDisabled;

  const FitSemanticColors.light()
    : ai = FitLightColors.ai,
      running = FitLightColors.energy,
      steps = FitLightColors.ai,
      achievement = FitLightColors.warning,
      premium = FitLightColors.warning,
      energy = FitLightColors.energy,
      xp = FitLightColors.warning,
      chartProgress = FitLightColors.primary,
      chartInformation = FitLightColors.ai,
      chartEnergy = FitLightColors.energy,
      chartLimit = FitLightColors.error,
      surfaceSubtle = FitLightColors.backgroundSubtle,
      surfaceRaised = FitLightColors.surfaceRaised,
      card = FitLightColors.card,
      cardInner = FitLightColors.cardInner,
      overlayScrim = FitLightColors.overlay,
      selectedSurface = FitLightColors.primaryContainer,
      disabledSurface = FitLightColors.backgroundSubtle;

  final Color ai;
  final Color running;
  final Color steps;
  final Color achievement;
  final Color premium;
  final Color energy;
  final Color xp;
  final Color chartProgress;
  final Color chartInformation;
  final Color chartEnergy;
  final Color chartLimit;
  final Color surfaceSubtle;
  final Color surfaceRaised;
  final Color card;
  final Color cardInner;
  final Color overlayScrim;
  final Color selectedSurface;
  final Color disabledSurface;

  @override
  FitSemanticColors copyWith({
    Color? ai,
    Color? running,
    Color? steps,
    Color? achievement,
    Color? premium,
    Color? energy,
    Color? xp,
    Color? chartProgress,
    Color? chartInformation,
    Color? chartEnergy,
    Color? chartLimit,
    Color? surfaceSubtle,
    Color? surfaceRaised,
    Color? card,
    Color? cardInner,
    Color? overlayScrim,
    Color? selectedSurface,
    Color? disabledSurface,
  }) {
    return FitSemanticColors(
      ai: ai ?? this.ai,
      running: running ?? this.running,
      steps: steps ?? this.steps,
      achievement: achievement ?? this.achievement,
      premium: premium ?? this.premium,
      energy: energy ?? this.energy,
      xp: xp ?? this.xp,
      chartProgress: chartProgress ?? this.chartProgress,
      chartInformation: chartInformation ?? this.chartInformation,
      chartEnergy: chartEnergy ?? this.chartEnergy,
      chartLimit: chartLimit ?? this.chartLimit,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      card: card ?? this.card,
      cardInner: cardInner ?? this.cardInner,
      overlayScrim: overlayScrim ?? this.overlayScrim,
      selectedSurface: selectedSurface ?? this.selectedSurface,
      disabledSurface: disabledSurface ?? this.disabledSurface,
    );
  }

  @override
  FitSemanticColors lerp(covariant FitSemanticColors? other, double t) {
    if (other == null) return this;

    return FitSemanticColors(
      ai: Color.lerp(ai, other.ai, t)!,
      running: Color.lerp(running, other.running, t)!,
      steps: Color.lerp(steps, other.steps, t)!,
      achievement: Color.lerp(achievement, other.achievement, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
      energy: Color.lerp(energy, other.energy, t)!,
      xp: Color.lerp(xp, other.xp, t)!,
      chartProgress: Color.lerp(chartProgress, other.chartProgress, t)!,
      chartInformation: Color.lerp(
        chartInformation,
        other.chartInformation,
        t,
      )!,
      chartEnergy: Color.lerp(chartEnergy, other.chartEnergy, t)!,
      chartLimit: Color.lerp(chartLimit, other.chartLimit, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardInner: Color.lerp(cardInner, other.cardInner, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
      selectedSurface: Color.lerp(selectedSurface, other.selectedSurface, t)!,
      disabledSurface: Color.lerp(disabledSurface, other.disabledSurface, t)!,
    );
  }
}

/// Gradientes semânticos que não possuem representação no [ColorScheme].
@immutable
class FitThemeGradients extends ThemeExtension<FitThemeGradients> {
  const FitThemeGradients({
    required this.actionPrimary,
    required this.mediaScrim,
    required this.chartArea,
    required this.aiGlow,
    required this.premiumGlow,
    required this.surfaceDepth,
  });

  const FitThemeGradients.dark()
    : actionPrimary = FitGradients.actionPrimary,
      mediaScrim = FitGradients.mediaScrim,
      chartArea = FitGradients.chartArea,
      aiGlow = FitGradients.aiGlow,
      premiumGlow = FitGradients.premiumGlow,
      surfaceDepth = FitGradients.surfaceDepth;

  const FitThemeGradients.light()
    : actionPrimary = const LinearGradient(
        colors: [FitLightColors.primary, FitLightColors.primary],
      ),
      mediaScrim = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00000000), Color(0x99000000)],
      ),
      chartArea = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [FitLightColors.primaryContainer, Color(0x00DFF2A7)],
      ),
      aiGlow = const LinearGradient(
        colors: [FitLightColors.aiContainer, FitLightColors.aiContainer],
      ),
      premiumGlow = const LinearGradient(
        colors: [Color(0xFFFFE6AC), Color(0xFFFFE6AC)],
      ),
      surfaceDepth = const LinearGradient(
        colors: [FitLightColors.surfaceRaised, FitLightColors.surfaceRaised],
      );

  final Gradient actionPrimary;
  final Gradient mediaScrim;
  final Gradient chartArea;
  final Gradient aiGlow;
  final Gradient premiumGlow;
  final Gradient surfaceDepth;

  @override
  FitThemeGradients copyWith({
    Gradient? actionPrimary,
    Gradient? mediaScrim,
    Gradient? chartArea,
    Gradient? aiGlow,
    Gradient? premiumGlow,
    Gradient? surfaceDepth,
  }) {
    return FitThemeGradients(
      actionPrimary: actionPrimary ?? this.actionPrimary,
      mediaScrim: mediaScrim ?? this.mediaScrim,
      chartArea: chartArea ?? this.chartArea,
      aiGlow: aiGlow ?? this.aiGlow,
      premiumGlow: premiumGlow ?? this.premiumGlow,
      surfaceDepth: surfaceDepth ?? this.surfaceDepth,
    );
  }

  @override
  FitThemeGradients lerp(covariant FitThemeGradients? other, double t) {
    if (other == null) return this;

    return FitThemeGradients(
      actionPrimary: Gradient.lerp(actionPrimary, other.actionPrimary, t)!,
      mediaScrim: Gradient.lerp(mediaScrim, other.mediaScrim, t)!,
      chartArea: Gradient.lerp(chartArea, other.chartArea, t)!,
      aiGlow: Gradient.lerp(aiGlow, other.aiGlow, t)!,
      premiumGlow: Gradient.lerp(premiumGlow, other.premiumGlow, t)!,
      surfaceDepth: Gradient.lerp(surfaceDepth, other.surfaceDepth, t)!,
    );
  }
}

extension FitThemeDataExtensions on ThemeData {
  /// Retorna a extensão semântica com fallback seguro durante a migração.
  FitSemanticColors get fitSemanticColors =>
      extension<FitSemanticColors>() ??
      (brightness == Brightness.dark
          ? const FitSemanticColors.dark()
          : const FitSemanticColors.light());

  /// Retorna gradientes semânticos com fallback para o tema escuro atual.
  FitThemeGradients get fitGradients =>
      extension<FitThemeGradients>() ??
      (brightness == Brightness.dark
          ? const FitThemeGradients.dark()
          : const FitThemeGradients.light());
}
