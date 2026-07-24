import 'package:flutter/material.dart';

/// Paleta primitiva medida na Official UI.
///
/// Consumidores devem usar [FitColors]. A paleta permanece privada para evitar
/// que nomes físicos virem contrato de componente.
abstract final class _FitPalette {
  static const neutral1000 = Color(0xFF00060C);
  static const neutral950 = Color(0xFF010910);
  static const neutral900 = Color(0xFF080E13);
  static const neutral850 = Color(0xFF091015);
  static const neutral800 = Color(0xFF0A1218);
  static const neutral700 = Color(0xFF10161B);
  static const neutral600 = Color(0xFF1C2028);
  static const neutral500 = Color(0xFF25272C);
  static const neutral300 = Color(0xFF7D7E7F);
  static const neutral200 = Color(0xFFA3A4A5);
  static const neutral0 = Color(0xFFFFFFFF);

  // Valores cromáticos DS3 provisórios, mantidos centralizados até validação.
  static const primaryDeep = Color(0xFF5E8701);
  static const primaryDefault = Color(0xFF70A527);
  static const primaryBright = Color(0xFF7BAF01);
  static const aiDefault = Color(0xFF44B89C);
  static const infoDefault = Color(0xFF2F9ADB);
  static const energyDefault = Color(0xFFED9606);
  static const warningDefault = Color(0xFFF7B703);
  static const errorDefault = Color(0xFFC32722);
  static const xpDefault = Color(0xFF7049D3);
}

/// Tokens semânticos oficiais do FitIA Design System 3.0.
///
/// Neutros são confirmados pela documentação DS3. Valores cromáticos continuam
/// provisórios e podem mudar sem alterar os nomes semânticos desta API.
abstract final class FitColors {
  static const background = _FitPalette.neutral1000;
  static const backgroundSubtle = _FitPalette.neutral950;
  static const surface = _FitPalette.neutral900;
  static const surfaceRaised = _FitPalette.neutral850;
  static const card = _FitPalette.neutral800;
  static const cardInner = _FitPalette.neutral700;
  static const borderSubtle = _FitPalette.neutral600;
  static const borderStrong = _FitPalette.neutral500;

  static const textPrimary = _FitPalette.neutral0;
  static const textSecondary = _FitPalette.neutral200;
  static const textTertiary = _FitPalette.neutral300;
  static const textDisabled = _FitPalette.neutral300;

  /// Ação principal, seleção, progresso e sucesso.
  static const primary = _FitPalette.primaryDefault;
  static const primaryMuted = _FitPalette.primaryDeep;
  static const primaryEmphasis = _FitPalette.primaryBright;
  static const onPrimary = background;

  /// Papéis cromáticos de domínio. Não existe um `accent` global no DS3.
  static const ai = _FitPalette.aiDefault;
  static const info = _FitPalette.infoDefault;
  static const energy = _FitPalette.energyDefault;
  static const warning = _FitPalette.warningDefault;
  static const error = _FitPalette.errorDefault;
  static const xp = _FitPalette.xpDefault;
  static const success = primary;
  static const premium = warning;
  static const achievement = warning;
  static const running = energy;
  static const steps = info;

  /// Tokens de estado provisórios sustentados pelos papéis existentes.
  static const surfaceSelected = cardInner;
  static const primaryPressed = primaryMuted;
  static const focus = primaryEmphasis;
  static const surfaceDisabled = surfaceRaised;

  /// Alpha de overlays e containers permanece provisório no DS3.
  static const overlay = Color(0x99000000);
  static const primaryContainer = Color(0x2470A527);
  static const aiContainer = Color(0x2444B89C);
  static const achievementContainer = Color(0x24F7B703);

  static const onInfo = background;
  static const onAchievement = background;
  static const onError = textPrimary;

  // Aliases de compatibilidade para consumidores existentes.
  static const primaryDark = primaryMuted;
  static const primaryLight = primaryEmphasis;
  static const surfaceSubtle = backgroundSubtle;
  static const surfaceVariant = card;
  static const surfaceElevated = surfaceRaised;
  static const outline = borderStrong;
  static const outlineSoft = borderSubtle;
  static const border = borderStrong;
  static const divider = borderSubtle;
  static const textHint = textTertiary;
  static const danger = error;

  static const colorScheme = ColorScheme.dark(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: primary,
    secondary: ai,
    onSecondary: onInfo,
    secondaryContainer: aiContainer,
    onSecondaryContainer: ai,
    tertiary: energy,
    onTertiary: onAchievement,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: cardInner,
    outline: outline,
    outlineVariant: outlineSoft,
    error: error,
    onError: onError,
  );
}
