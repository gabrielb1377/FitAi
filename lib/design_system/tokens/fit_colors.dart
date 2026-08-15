import 'package:flutter/material.dart';

/// Paleta primitiva do FitIA Design System Next.
///
/// Consumidores devem usar [FitColors]. A paleta permanece privada para evitar
/// que nomes físicos virem contrato de componente.
abstract final class _FitPalette {
  static const neutral1000 = Color(0xFF090B08);
  static const neutral950 = Color(0xFF0C0F0B);
  static const neutral900 = Color(0xFF11140F);
  static const neutral850 = Color(0xFF161A13);
  static const neutral800 = Color(0xFF1A1F17);
  static const neutral700 = Color(0xFF22291E);
  static const neutral600 = Color(0xFF30382B);
  static const neutral500 = Color(0xFF465140);
  static const neutral300 = Color(0xFF7F8979);
  static const neutral200 = Color(0xFFB7BFAF);
  static const neutral0 = Color(0xFFF5F7EE);

  // Lima eletrica e a assinatura esportiva. Azul fica reservado para IA.
  static const primaryDeep = Color(0xFF8EAD2B);
  static const primaryDefault = Color(0xFFC9F548);
  static const primaryBright = Color(0xFFE0FF7A);
  static const aiDefault = Color(0xFF63AFFF);
  static const infoDefault = Color(0xFF68B8E8);
  static const energyDefault = Color(0xFFFF9640);
  static const warningDefault = Color(0xFFF5C04A);
  static const errorDefault = Color(0xFFFF6161);
  static const xpDefault = Color(0xFFFFB44A);
}

/// Tokens semânticos oficiais do FitIA Design System Next.
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

  static const overlay = Color(0xB3000000);
  static const primaryContainer = Color(0x26C9F548);
  static const aiContainer = Color(0x2463AFFF);
  static const achievementContainer = Color(0x24FFB44A);

  static const onInfo = background;
  static const onAchievement = background;
  static const onError = background;

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

/// Paleta clara desenhada separadamente, sem inverter o tema escuro.
///
/// Componentes novos devem preferir `Theme.of(context).colorScheme` para
/// responder corretamente a ambos os modos.
abstract final class FitLightColors {
  static const background = Color(0xFFF3F5EE);
  static const backgroundSubtle = Color(0xFFEDF0E7);
  static const surface = Color(0xFFFAFCF6);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const card = Color(0xFFF7F9F3);
  static const cardInner = Color(0xFFE8ECE2);
  static const borderSubtle = Color(0xFFDCE2D5);
  static const borderStrong = Color(0xFFBCC6B4);
  static const textPrimary = Color(0xFF151912);
  static const textSecondary = Color(0xFF4E5849);
  static const textTertiary = Color(0xFF6D7867);
  static const textDisabled = Color(0xFF929A8D);
  static const primary = Color(0xFF537200);
  static const primaryContainer = Color(0xFFDFF2A7);
  static const ai = Color(0xFF176DB8);
  static const aiContainer = Color(0xFFDCEEFF);
  static const energy = Color(0xFFB84D00);
  static const warning = Color(0xFF8A6200);
  static const error = Color(0xFFB3261E);
  static const overlay = Color(0x66000000);

  static const colorScheme = ColorScheme.light(
    primary: primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: primaryContainer,
    onPrimaryContainer: Color(0xFF1C2A00),
    secondary: ai,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: aiContainer,
    onSecondaryContainer: Color(0xFF082E4E),
    tertiary: energy,
    onTertiary: Color(0xFFFFFFFF),
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: cardInner,
    outline: borderStrong,
    outlineVariant: borderSubtle,
    error: error,
    onError: Color(0xFFFFFFFF),
  );
}
