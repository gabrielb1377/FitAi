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
    return FitCard(
      variant: FitCardVariant.clickable,
      elevation: 1,
      title: title,
      subtitle: subtitle,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent.withAlpha(26),
          borderRadius: FitRadius.mediumBorder,
        ),
        child: Icon(icon, color: accent),
      ),
      trailing: const Icon(Icons.arrow_forward_rounded),
      onTap: onOpen,
      semanticLabel: actionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Value(label: primaryLabel, value: primaryValue),
              ),
              const SizedBox(width: FitSpacing.s16),
              Expanded(
                child: _Value(label: secondaryLabel, value: secondaryValue),
              ),
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
          const SizedBox(height: FitSpacing.s20),
          FitButton(
            label: actionLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: onOpen,
            variant: FitButtonVariant.outlined,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final String label;
  final String value;

  const _Value({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: FitSpacing.s4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
