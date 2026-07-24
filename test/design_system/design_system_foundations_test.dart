import 'package:fitai/design_system/fit_design_system.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FitIA Design System 3.0 foundations', () {
    test('tema escuro e criado sem excecao', () {
      expect(FitTheme.dark, returnsNormally);
    });

    test('ColorScheme oficial possui brightness dark', () {
      final theme = FitTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, FitColors.background);
    });

    test('tokens cromaticos criticos nao sao transparentes', () {
      const criticalColors = <Color>[
        FitColors.background,
        FitColors.surface,
        FitColors.card,
        FitColors.textPrimary,
        FitColors.primary,
        FitColors.error,
      ];

      for (final color in criticalColors) {
        expect(color.a, greaterThan(0));
        expect(color, isNot(Colors.transparent));
      }
    });

    test('estilos tipograficos principais estao disponiveis', () {
      expect(FitTypography.display.fontSize, isNotNull);
      expect(FitTypography.heading.fontSize, isNotNull);
      expect(FitTypography.title.fontSize, isNotNull);
      expect(FitTypography.body.fontSize, isNotNull);
      expect(FitTypography.metric.fontFeatures, isNotEmpty);
      expect(FitNumberStyles.timer.fontFeatures, isNotEmpty);
      expect(FitNumberStyles.load.fontSize, isNotNull);
      expect(FitNumberStyles.progress.fontSize, isNotNull);
    });

    test('escala de espacamento e estritamente crescente', () {
      final scale = FitSpacing.orderedScale;

      for (var index = 1; index < scale.length; index++) {
        expect(scale[index], greaterThan(scale[index - 1]));
      }
    });

    test('raios nao possuem valores negativos', () {
      for (final radius in FitRadius.allValues) {
        expect(radius, greaterThanOrEqualTo(0));
      }
    });

    test('duracoes de motion, exceto instant, sao positivas', () {
      expect(FitDuration.instant, Duration.zero);
      for (final duration in FitDuration.positiveDurations) {
        expect(duration, greaterThan(Duration.zero));
      }
    });

    test('ThemeExtensions oficiais estao disponiveis', () {
      final theme = FitTheme.dark();
      final semanticColors = theme.extension<FitSemanticColors>();
      final gradients = theme.extension<FitThemeGradients>();

      expect(semanticColors, isNotNull);
      expect(semanticColors?.ai, FitColors.ai);
      expect(semanticColors?.premium, FitColors.premium);
      expect(gradients, isNotNull);
      expect(gradients?.actionPrimary, FitGradients.actionPrimary);
    });

    test('barrel exporta as APIs publicas fundamentais', () {
      expect(FitLayout.minimumTouchTarget, greaterThan(0));
      expect(FitStateTokens.success, FitColors.success);
      expect(FitElevation.dialog, FitShadows.high);
      expect(FitBreakpoints.ordered, isNotEmpty);
    });

    test('aliases legados apontam para tokens validos', () {
      expect(AppColors.primary, FitColors.primary);
      expect(AppColors.card, FitColors.card);
      expect(AppRadii.sm, FitRadius.input);
      expect(AppSpacing.xs, FitSpacing.legacyXs);
      expect(AppMotion.fast, const Duration(milliseconds: 160));
      expect(AppMotion.normal, const Duration(milliseconds: 240));
      expect(AppMotion.slow, const Duration(milliseconds: 320));
      expect(AppTheme.dark.colorScheme.primary, FitColors.primary);
    });

    test('ThemeData cobre controles globais essenciais', () {
      final theme = FitTheme.dark();

      expect(theme.cardTheme.color, FitColors.card);
      expect(theme.dividerTheme.color, FitColors.divider);
      expect(theme.progressIndicatorTheme.color, FitColors.primary);
      expect(theme.sliderTheme.activeTrackColor, FitColors.primary);
      expect(theme.inputDecorationTheme.fillColor, FitColors.surfaceRaised);
      expect(theme.dialogTheme.backgroundColor, FitColors.surfaceRaised);
      expect(theme.bottomSheetTheme.backgroundColor, FitColors.surfaceRaised);
    });
  });
}
