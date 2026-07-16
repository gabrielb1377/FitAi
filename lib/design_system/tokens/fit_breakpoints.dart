/// Breakpoints mobile-first usados para adaptar componentes, nao para criar
/// uma experiencia desktop paralela nesta fase.
abstract final class FitBreakpoints {
  static const double smallMobile = 359;
  static const double mobile = 360;
  static const double tablet = 600;
  static const double largeTablet = 840;

  static bool isSmallMobile(double width) => width <= smallMobile;
  static bool isTablet(double width) => width >= tablet;
  static bool isLargeTablet(double width) => width >= largeTablet;
}
