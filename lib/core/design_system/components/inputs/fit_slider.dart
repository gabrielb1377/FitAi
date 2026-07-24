import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_spacing.dart';

/// Slider controlado com label, valor formatado e sem regra de domínio.
class FitSlider extends StatelessWidget {
  const FitSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueFormatter,
    this.enabled = true,
    this.semanticLabel,
  }) : assert(max > min),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String Function(double value)? valueFormatter;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final formattedValue = valueFormatter?.call(value) ?? value.toString();
    return Semantics(
      slider: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      value: formattedValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: FitSpacing.s8),
              Text(
                formattedValue,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: formattedValue,
            semanticFormatterCallback: (_) => formattedValue,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
