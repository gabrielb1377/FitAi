import 'package:flutter/material.dart';

/// Sombras discretas para dar profundidade sem pesar a interface.
abstract final class FitElevation {
  static const level0 = <BoxShadow>[];
  static const level1 = <BoxShadow>[
    BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const level2 = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 5)),
  ];
  static const level3 = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
