import 'package:flutter/material.dart';

/// Sombras discretas preservadas como candidatos provisórios no DS3.
///
/// Em superfícies escuras elas sempre trabalham com diferença tonal e borda;
/// nunca são a única indicação de elevação.
abstract final class FitShadows {
  static const none = <BoxShadow>[];
  static const low = <BoxShadow>[
    BoxShadow(color: Color(0x24000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const medium = <BoxShadow>[
    BoxShadow(color: Color(0x30000000), blurRadius: 14, offset: Offset(0, 5)),
  ];
  static const high = <BoxShadow>[
    BoxShadow(color: Color(0x38000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const card = low;
  static const raisedCard = medium;
  static const floating = medium;
  static const overlay = high;
}
