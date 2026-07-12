import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Divisor FitIA com espaco vertical consistente e personalizacao pontual.
class FitDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double thickness;
  final double verticalSpacing;
  final Color? color;

  const FitDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 1,
    this.verticalSpacing = FitSpacing.s16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalSpacing),
      child: Divider(
        indent: indent,
        endIndent: endIndent,
        thickness: thickness,
        height: thickness,
        color: color ?? Theme.of(context).dividerColor,
      ),
    );
  }
}
