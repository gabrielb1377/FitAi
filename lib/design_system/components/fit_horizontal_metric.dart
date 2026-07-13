import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Metrica horizontal sem card para linhas de resumo densas.
class FitHorizontalMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final Color? color;

  const FitHorizontalMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    return Semantics(
      label: '$label: $value${detail == null ? '' : ', $detail'}',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              borderRadius: FitRadius.mediumBorder,
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (detail != null)
                  Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
