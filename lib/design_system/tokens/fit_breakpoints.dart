/// Breakpoints mobile-first provisórios herdados da arquitetura atual.
///
/// O DS3 confirma a estratégia responsiva, mas ainda precisa medir os valores.
abstract final class FitBreakpoints {
  static const double smallMobile = 359;
  static const double mobile = 360;
  static const double tablet = 600;
  static const double largeTablet = 840;

  static const ordered = <double>[mobile, tablet, largeTablet];

  static bool isSmallMobile(double width) => width <= smallMobile;
  static bool isTablet(double width) => width >= tablet;
  static bool isLargeTablet(double width) => width >= largeTablet;
}
