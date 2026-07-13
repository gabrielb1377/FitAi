import 'package:flutter/material.dart';

/// Sombras oficiais, discretas e adequadas para superficies escuras.
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
}
