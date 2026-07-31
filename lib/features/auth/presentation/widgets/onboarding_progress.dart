import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  }) : assert(totalSteps > 0);

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final current = currentStep.clamp(0, totalSteps - 1);
    return Semantics(
      label: 'Etapa ${current + 1} de $totalSteps',
      value: '${current + 1}/$totalSteps',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < totalSteps; index++) ...[
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
              if (index != totalSteps - 1) const SizedBox(width: FitSpacing.s8),
            ],
          ],
        ),
      ),
    );
  }
}
