import 'package:flutter/widgets.dart';

/// Raios de borda padronizados para superficies e controles.
abstract final class FitRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 24;
  static const double pill = 999;

  static const smallBorder = BorderRadius.all(Radius.circular(small));
  static const mediumBorder = BorderRadius.all(Radius.circular(medium));
  static const largeBorder = BorderRadius.all(Radius.circular(large));
  static const xLargeBorder = BorderRadius.all(Radius.circular(xLarge));
  static const pillBorder = BorderRadius.all(Radius.circular(pill));
}
