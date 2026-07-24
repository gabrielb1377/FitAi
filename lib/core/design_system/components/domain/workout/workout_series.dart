import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../cards/cards.dart';
import '../../inputs/inputs.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Contador do número da série atual e do total previsto.
class FitSeriesCounter extends StatelessWidget {
  const FitSeriesCounter({
    super.key,
    required this.current,
    required this.total,
    this.label = 'Série',
  }) : assert(total > 0),
       assert(current >= 0);

  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FitDomainStatusBadge(
      label: '$label $current de $total',
      tone: FitDomainTone.primary,
      icon: FitIcons.repetitions,
    );
  }
}

/// Linha de série com carga, repetições e estado visual.
class FitSeriesRow extends StatelessWidget {
  const FitSeriesRow({
    super.key,
    required this.data,
    this.onTap,
    this.onToggleCompleted,
    this.enabled = true,
  });

  final FitSeriesDisplayData data;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleCompleted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final weightLabel = data.weight == null
        ? 'Carga não informada'
        : '${data.weight!.toStringAsFixed(data.weight! % 1 == 0 ? 0 : 1)} ${data.weightUnit}';
    return FitCard(
      selected: data.current,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      onTap: enabled ? onTap : null,
      semanticLabel:
          'Série ${data.index}, $weightLabel, ${data.repetitions} repetições',
      child: Row(
        children: [
          FitDomainStatusBadge(
            label: '${data.index}',
            tone: data.current ? FitDomainTone.primary : FitDomainTone.neutral,
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weightLabel, style: context.textTheme.titleMedium),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  '${data.repetitions} reps${data.restLabel == null ? '' : ' · ${data.restLabel}'}',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onToggleCompleted != null)
            Checkbox(
              value: data.completed,
              onChanged: enabled
                  ? (value) => onToggleCompleted!(value ?? false)
                  : null,
              semanticLabel: 'Marcar série ${data.index} como concluída',
            )
          else if (data.completed)
            Icon(FitIcons.success, color: context.colors.primary),
        ],
      ),
    );
  }
}

/// Seletor visual de repetições sem regra de progressão.
class FitRepsSelector extends StatelessWidget {
  const FitRepsSelector({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.enabled = true,
  }) : assert(min >= 0),
       assert(max >= min),
       assert(value >= min && value <= max);

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitStepper(
      label: 'Repetições',
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      onChanged: (next) => onChanged(next.round()),
      valueFormatter: (current) => current.round().toString(),
      enabled: enabled,
    );
  }
}

/// Seletor visual de carga com limites definidos pelo chamador.
class FitWeightSelector extends StatelessWidget {
  const FitWeightSelector({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.unit = 'kg',
    this.enabled = true,
  }) : assert(min >= 0),
       assert(max >= min),
       assert(step > 0),
       assert(value >= min && value <= max);

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String unit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FitStepper(
      label: 'Carga',
      value: value,
      min: min,
      max: max,
      step: step,
      onChanged: onChanged,
      valueFormatter: (current) =>
          '${current.toStringAsFixed(current % 1 == 0 ? 0 : 1)} $unit',
      enabled: enabled,
    );
  }
}
