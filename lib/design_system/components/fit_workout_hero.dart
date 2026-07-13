import 'package:flutter/material.dart';

import '../tokens/fit_icons.dart';
import '../tokens/fit_spacing.dart';
import 'fit_hero_card.dart';
import 'fit_progress.dart';

/// Resumo dominante do treino atual ou da proxima sessao.
class FitWorkoutHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget> metrics;
  final double? progress;
  final String? progressLabel;
  final Widget? badge;
  final Widget? action;
  final VoidCallback? onTap;

  const FitWorkoutHero({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.metrics = const [],
    this.progress,
    this.progressLabel,
    this.badge,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FitHeroCard(
      title: title,
      subtitle: subtitle,
      eyebrow: eyebrow,
      icon: FitIcons.workout,
      badge: badge,
      action: action,
      onTap: onTap,
      child: metrics.isEmpty && progress == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metrics.isNotEmpty)
                  Wrap(
                    spacing: FitSpacing.s16,
                    runSpacing: FitSpacing.s8,
                    children: metrics,
                  ),
                if (progress != null) ...[
                  if (metrics.isNotEmpty)
                    const SizedBox(height: FitSpacing.s16),
                  FitProgress(value: progress!, label: progressLabel),
                ],
              ],
            ),
    );
  }
}
