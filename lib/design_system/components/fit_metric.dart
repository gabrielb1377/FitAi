import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Metrica compacta para resumos horizontais sem criar um card por valor.
class FitMetric extends StatelessWidget {
  const FitMetric({
    super.key,
    required this.label,
    this.value,
    required this.icon,
    this.detail,
    this.unit,
    this.trend,
    this.color,
    this.alignment = CrossAxisAlignment.start,
    this.isLoading = false,
    this.unavailable = false,
  }) : assert(!isLoading || !unavailable);

  final String label;
  final String? value;
  final String? detail;
  final String? unit;
  final String? trend;
  final IconData icon;
  final Color? color;
  final CrossAxisAlignment alignment;
  final bool isLoading;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    final textTheme = Theme.of(context).textTheme;
    final visibleValue = unavailable ? '--' : value ?? '--';
    return Semantics(
      label: '$label: $visibleValue${detail == null ? '' : ', $detail'}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: FitSpacing.s8),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              '$visibleValue${unit == null ? '' : ' $unit'}',
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
          if (trend != null) ...[
            const SizedBox(height: FitSpacing.s2),
            Text(
              trend!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(color: accent),
            ),
          ],
        ],
      ),
    );
  }
}

/// Linha responsiva de metricas. Em espaco reduzido, os itens quebram sem
/// exigir largura fixa ou um card por valor.
class FitMetricRow extends StatelessWidget {
  const FitMetricRow({
    super.key,
    required this.children,
    this.spacing = FitSpacing.s16,
    this.runSpacing = FitSpacing.s12,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: spacing, runSpacing: runSpacing, children: children);
  }
}
