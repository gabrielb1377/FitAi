import 'package:flutter/widgets.dart';

/// Escala de espaçamento reutilizável do FitIA.
///
/// Os valores vêm do Design System anterior e são provisórios no DS3 até a
/// medição das foundations de Spacing e Grid.
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

  static const minimum = s2;
  static const extraSmall = s4;
  static const small = s8;
  static const medium = s16;
  static const large = s24;
  static const extraLarge = s32;
  static const huge = s48;

  static const screenMargin = s16;
  static const sectionGap = s24;
  static const cardPadding = s16;
  static const listGap = s12;
  static const controlGap = s12;
  static const compactGap = s8;

  /// Valores legados preservados para `AppSpacing` durante a migração.
  static const legacyXs = 6.0;
  static const legacySm = 10.0;
  static const legacyMd = 14.0;
  static const legacyLg = 20.0;
  static const legacyXl = 28.0;
  static const legacyXxl = 36.0;

  static const orderedScale = <double>[
    s2,
    s4,
    s8,
    s12,
    s16,
    s20,
    s24,
    s32,
    s40,
    s48,
    s64,
  ];

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
  double get screenMargin => FitSpacing.screenMargin;
  double get sectionGap => FitSpacing.sectionGap;
  double get cardPadding => FitSpacing.cardPadding;
  double get listGap => FitSpacing.listGap;

  EdgeInsets all(double value) => EdgeInsets.all(value);
  EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}
