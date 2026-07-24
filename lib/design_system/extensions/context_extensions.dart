import 'package:flutter/material.dart';

import '../theme/fit_theme_extensions.dart';
import '../tokens/fit_breakpoints.dart';
import '../tokens/fit_spacing.dart';

/// Atalhos de leitura para tokens dependentes do contexto atual.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  FitSemanticColors get fitColors => theme.fitSemanticColors;
  FitThemeGradients get fitGradients => theme.fitGradients;
  FitSpacingValues get spacing => FitSpacing.values;
  TextTheme get textTheme => theme.textTheme;
  TextTheme get fitText => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  bool get isSmallMobile => FitBreakpoints.isSmallMobile(screenWidth);
  bool get isTablet => FitBreakpoints.isTablet(screenWidth);
  bool get isLargeTablet => FitBreakpoints.isLargeTablet(screenWidth);
}
