import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final current = currentStep.clamp(0, 2);
    return Semantics(
      label: 'Etapa ${current + 1} de 3',
      value: '${current + 1}/3',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == current ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: index == current
                      ? FitColors.primary
                      : FitColors.textHint.withAlpha(100),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              if (index != 2) const SizedBox(width: FitSpacing.s8),
            ],
          ],
        ),
      ),
    );
  }
}
