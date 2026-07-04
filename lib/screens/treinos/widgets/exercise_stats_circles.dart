import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ExerciseStatsCircles extends StatelessWidget {
  final String repetitions;
  final String rest;
  final String series;
  final bool restHighlighted;

  const ExerciseStatsCircles({
    super.key,
    required this.repetitions,
    required this.rest,
    required this.series,
    this.restHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CircleMetric(
            label: 'Repeticoes necessarias',
            value: repetitions,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CircleMetric(
            label: 'Repouso',
            value: rest,
            highlighted: restHighlighted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CircleMetric(label: 'Series feitas', value: series),
        ),
      ],
    );
  }
}

class _CircleMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _CircleMetric({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 104,
          height: 104,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted
                ? AppColors.primary.withAlpha(28)
                : AppColors.surface,
            border: Border.all(
              color: highlighted
                  ? AppColors.primary
                  : Colors.white.withAlpha(14),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(34),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
