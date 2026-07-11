import 'package:flutter/widgets.dart';

/// Escala de espacamento consistente para novos componentes FitIA.
abstract final class FitSpacing {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;

  static const values = FitSpacingValues();
}

/// Versao de leitura da escala para uso por `BuildContext`.
class FitSpacingValues {
  const FitSpacingValues();

  double get s2 => FitSpacing.s2;
  double get s4 => FitSpacing.s4;
  double get s8 => FitSpacing.s8;
  double get s12 => FitSpacing.s12;
  double get s16 => FitSpacing.s16;
  double get s20 => FitSpacing.s20;
  double get s24 => FitSpacing.s24;
  double get s32 => FitSpacing.s32;
  double get s40 => FitSpacing.s40;
  double get s48 => FitSpacing.s48;
  double get s64 => FitSpacing.s64;

  EdgeInsets all(double value) => EdgeInsets.all(value);
  EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}
