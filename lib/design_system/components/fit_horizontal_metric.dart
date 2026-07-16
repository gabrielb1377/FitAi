import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Metrica horizontal sem card para linhas de resumo densas.
class FitHorizontalMetric extends StatelessWidget {
  const FitHorizontalMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.unit,
    this.trend,
    this.color,
    this.isLoading = false,
    this.unavailable = false,
  }) : assert(!isLoading || !unavailable);

  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final String? unit;
  final String? trend;
  final Color? color;
  final bool isLoading;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    return Semantics(
      label:
          '$label: ${unavailable ? 'Indisponivel' : value}${detail == null ? '' : ', $detail'}',
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
                if (trend != null)
                  Text(
                    trend!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: accent),
                  ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Flexible(
              child: Text(
                unavailable ? '--' : '$value${unit == null ? '' : ' $unit'}',
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
