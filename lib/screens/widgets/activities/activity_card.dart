import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;
  final double? progress;
  final String actionLabel;
  final VoidCallback onOpen;

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.actionLabel,
    required this.onOpen,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return FitEditorialHero(
      eyebrow: 'Atividade',
      title: title,
      subtitle: subtitle,
      trailing: Icon(icon, color: accent),
      accentColor: accent,
      onTap: onOpen,
      semanticLabel: actionLabel,
      action: FitSecondaryButton(
        label: actionLabel,
        trailingIcon: Icons.arrow_forward_rounded,
        onPressed: onOpen,
        fullWidth: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FitMetricRail(
            items: [
              FitMetricRailItem(label: primaryLabel, value: primaryValue),
              FitMetricRailItem(label: secondaryLabel, value: secondaryValue),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: FitSpacing.s16),
            FitProgress(
              value: progress!,
              label: 'Meta diaria',
              trailing: '${(progress! * 100).round()}%',
            ),
          ],
        ],
      ),
    );
  }
}
