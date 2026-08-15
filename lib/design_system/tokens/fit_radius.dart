import 'package:flutter/widgets.dart';

/// Raios padronizados para superfícies e controles.
///
/// A escala existente foi preservada como valor provisório no DS3. Os aliases
/// semânticos evitam que componentes escolham raios apenas pela aparência.
abstract final class FitRadius {
  static const double small = 4;
  static const double medium = 8;
  static const double large = 8;
  static const double highlighted = 12;
  static const double xLarge = 12;
  static const double bottomSheet = 16;
  static const double pill = 999;
  static const double circular = pill;

  static const controlSmall = small;
  static const input = medium;
  static const card = large;
  static const cardHighlighted = highlighted;
  static const dialog = xLarge;

  static const smallBorder = BorderRadius.all(Radius.circular(small));
  static const mediumBorder = BorderRadius.all(Radius.circular(medium));
  static const largeBorder = BorderRadius.all(Radius.circular(large));
  static const highlightedBorder = BorderRadius.all(
    Radius.circular(highlighted),
  );
  static const xLargeBorder = BorderRadius.all(Radius.circular(xLarge));
  static const bottomSheetBorder = BorderRadius.vertical(
    top: Radius.circular(bottomSheet),
  );
  static const pillBorder = BorderRadius.all(Radius.circular(pill));

  static const allValues = <double>[
    small,
    medium,
    large,
    highlighted,
    xLarge,
    bottomSheet,
    pill,
  ];
}
