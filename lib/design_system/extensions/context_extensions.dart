import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Atalhos de leitura para tokens dependentes do contexto atual.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  FitSpacingValues get spacing => FitSpacing.values;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
}
