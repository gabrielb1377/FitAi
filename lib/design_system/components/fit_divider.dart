import 'package:flutter/material.dart';

/// Divisor discreto com espacamento e recuos configuraveis.
class FitDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;
  final double? height;

  const FitDivider({super.key, this.indent, this.endIndent, this.height});

  @override
  Widget build(BuildContext context) {
    return Divider(indent: indent, endIndent: endIndent, height: height);
  }
}
