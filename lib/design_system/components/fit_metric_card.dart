import 'package:flutter/material.dart';

import 'fit_card.dart';
import 'fit_metric.dart';

/// Metrica com superficie propria para grids em que o card e necessario.
/// Para resumos sem moldura, prefira `FitMetric` ou `FitHorizontalMetric`.
class FitMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final Color? color;
  final VoidCallback? onTap;

  const FitMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: onTap,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      semanticLabel: '$label: $value',
      child: FitMetric(
        label: label,
        value: value,
        icon: icon,
        detail: detail,
        color: color,
      ),
    );
  }
}
