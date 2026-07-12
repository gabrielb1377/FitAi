import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Metrica compacta para resumos horizontais sem criar um card por valor.
///
/// Exemplo: `FitMetric(label: 'Passos', value: '6.240', icon: Icons.directions_walk)`.
class FitMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color? color;
  final CrossAxisAlignment alignment;

  const FitMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value${detail == null ? '' : ', $detail'}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: FitSpacing.s8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: FitSpacing.s2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall,
          ),
          if (detail != null) ...[
            const SizedBox(height: FitSpacing.s2),
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
