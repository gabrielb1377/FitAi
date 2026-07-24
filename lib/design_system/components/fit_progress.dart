import 'package:flutter/material.dart';

import '../tokens/fit_duration.dart';
import '../tokens/fit_layout.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Barra de progresso rotulada para metas e avancos percentuais.
class FitProgress extends StatelessWidget {
  const FitProgress({
    super.key,
    required this.value,
    this.label,
    this.trailing,
    this.color,
    this.height = FitLayout.progressCompactThickness,
    this.animate = false,
  });

  final double value;
  final String? label;
  final String? trailing;
  final Color? color;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0).toDouble();
    final colors = Theme.of(context).colorScheme;
    Widget progress(double progressValue) => LinearProgressIndicator(
      value: progressValue,
      minHeight: height,
      backgroundColor: colors.surfaceContainerHighest,
      color: color ?? colors.primary,
    );
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
                  Flexible(
                    child: Text(
                      trailing!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          if (label != null || trailing != null)
            const SizedBox(height: FitSpacing.s8),
          ClipRRect(
            borderRadius: FitRadius.pillBorder,
            child: animate
                ? TweenAnimationBuilder<double>(
                    tween: Tween(end: normalized),
                    duration: FitDuration.normal,
                    curve: FitDuration.curve,
                    builder: (context, animatedValue, _) =>
                        progress(animatedValue),
                  )
                : progress(normalized),
          ),
        ],
      ),
    );
  }
}

/// Nome explicito para a barra linear oficial.
class FitProgressBar extends FitProgress {
  const FitProgressBar({
    super.key,
    required super.value,
    super.label,
    super.trailing,
    super.color,
    super.height,
    super.animate,
  });
}

class FitCircularProgress extends StatelessWidget {
  const FitCircularProgress({
    super.key,
    this.value,
    this.label,
    this.showPercentage = false,
    this.color,
    this.size = FitLayout.progressRingSize,
    this.strokeWidth = FitLayout.progressRingStroke,
  });

  final double? value;
  final String? label;
  final bool showPercentage;
  final Color? color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.clamp(0.0, 1.0).toDouble();
    final displayLabel =
        label ??
        (showPercentage && normalized != null
            ? '${(normalized * 100).round()}%'
            : null);
    return Semantics(
      label:
          '${label ?? 'Progresso circular'}${normalized == null ? ', carregando' : ': ${(normalized * 100).round()}%'}',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: normalized,
                strokeWidth: strokeWidth,
                color: color ?? Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            if (displayLabel != null)
              Padding(
                padding: const EdgeInsets.all(FitSpacing.s4),
                child: Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FitStepProgress extends StatelessWidget {
  const FitStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.label,
    this.color,
  }) : assert(totalSteps > 0);

  final int currentStep;
  final int totalSteps;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final normalized = (currentStep / totalSteps).clamp(0.0, 1.0).toDouble();
    return FitProgress(
      value: normalized,
      color: color,
      label: label,
      trailing: '$currentStep/$totalSteps',
      animate: true,
    );
  }
}

class FitGoalProgress extends FitProgress {
  const FitGoalProgress({
    super.key,
    required super.value,
    required String title,
    String? percentage,
    super.color,
    super.animate,
  }) : super(label: title, trailing: percentage);
}
