import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Barra de progresso rotulada para metas e avancos percentuais.
///
/// Exemplo: `FitProgress(value: 0.6, label: 'Meta semanal', trailing: '60%')`.
class FitProgress extends StatelessWidget {
  final double value;
  final String? label;
  final String? trailing;
  final Color? color;
  final double height;

  const FitProgress({
    super.key,
    required this.value,
    this.label,
    this.trailing,
    this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0).toDouble();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '${label ?? 'Progresso'}: ${(normalized * 100).round()}%',
      value: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || trailing != null)
            Row(
              children: [
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          if (label != null || trailing != null)
            const SizedBox(height: FitSpacing.s8),
          ClipRRect(
            borderRadius: FitRadius.pillBorder,
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: height,
              backgroundColor: colors.surfaceContainerHighest,
              color: color ?? colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
