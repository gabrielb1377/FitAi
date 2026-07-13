import 'fit_shadows.dart';

/// Sombras discretas para dar profundidade sem pesar a interface.
abstract final class FitElevation {
  static const level0 = FitShadows.none;
  static const level1 = FitShadows.low;
  static const level2 = FitShadows.medium;
  static const level3 = FitShadows.high;
}
