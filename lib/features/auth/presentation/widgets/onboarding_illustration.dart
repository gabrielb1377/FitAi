import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Placeholder visual local para o onboarding, substituivel pelos assets
/// aprovados sem alterar a estrutura das telas.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withAlpha(16),
              border: Border.all(color: _accent.withAlpha(80)),
            ),
          ),
          Icon(_icon, color: _accent, size: 116),
          if (step == 0) ...[
            _MetricPill(label: 'Forca', value: '+28%', top: 44, left: 10),
            _MetricPill(
              label: 'Resistencia',
              value: '+35%',
              bottom: 28,
              left: 4,
            ),
            _MetricPill(
              label: 'Performance',
              value: '+42%',
              bottom: 46,
              right: 4,
            ),
          ] else if (step == 1) ...[
            _MetricPill(label: 'Passos', value: '8.432', top: 38, right: 8),
            _MetricPill(label: 'Corrida', value: '5,2 km', bottom: 36, left: 4),
          ] else ...[
            _CoachBubble(bottom: 22),
          ],
        ],
      ),
    );
  }

  IconData get _icon => switch (step) {
    0 => Icons.fitness_center_rounded,
    1 => Icons.insights_rounded,
    _ => Icons.smart_toy_rounded,
  };

  Color get _accent => step == 2 ? FitColors.ai : FitColors.primary;
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final String label;
  final String value;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s12,
          vertical: FitSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: FitColors.surface,
          borderRadius: FitRadius.mediumBorder,
          border: Border.all(color: FitColors.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: FitColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({this.bottom});

  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: FitSpacing.s12,
      right: FitSpacing.s12,
      child: Container(
        padding: const EdgeInsets.all(FitSpacing.s12),
        decoration: BoxDecoration(
          color: FitColors.surface,
          borderRadius: FitRadius.mediumBorder,
          border: Border.all(color: FitColors.ai.withAlpha(110)),
        ),
        child: Text(
          'Oi, eu sou a FitIA! Vou ajudar voce a evoluir.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
