import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/components/fit_icon_button.dart';
import '../../../../design_system/tokens/fit_icons.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Controle numérico compacto com limites definidos pelo chamador.
class FitStepper extends StatelessWidget {
  const FitStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.valueFormatter,
    this.enabled = true,
    this.decreaseTooltip = 'Diminuir',
    this.increaseTooltip = 'Aumentar',
  }) : assert(max >= min),
       assert(step > 0),
       assert(value >= min && value <= max);

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String Function(double value)? valueFormatter;
  final bool enabled;
  final String decreaseTooltip;
  final String increaseTooltip;

  @override
  Widget build(BuildContext context) {
    final canDecrease = enabled && value > min;
    final canIncrease = enabled && value < max;
    final formattedValue = valueFormatter?.call(value) ?? value.toString();
    return Semantics(
      label: label,
      value: formattedValue,
      enabled: enabled,
      child: Container(
        padding: const EdgeInsets.all(FitSpacing.s8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: FitRadius.mediumBorder,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            FitIconButton(
              icon: FitIcons.remove,
              tooltip: decreaseTooltip,
              size: FitButtonSize.small,
              enabled: canDecrease,
              onPressed: canDecrease
                  ? () => onChanged((value - step).clamp(min, max))
                  : null,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedValue,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: FitSpacing.s2),
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            FitIconButton(
              icon: FitIcons.add,
              tooltip: increaseTooltip,
              size: FitButtonSize.small,
              enabled: canIncrease,
              onPressed: canIncrease
                  ? () => onChanged((value + step).clamp(min, max))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
