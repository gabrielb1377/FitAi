import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';
import 'fit_card.dart';
import 'fit_progress.dart';

/// Progresso contextual com valor principal e detalhe opcional.
class FitProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final IconData icon;
  final String? description;
  final Color? color;
  final Widget? action;
  final VoidCallback? onTap;

  const FitProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.icon,
    this.description,
    this.color,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return FitCard(
      title: title,
      subtitle: description,
      leading: Icon(icon, color: accent),
      trailing: action,
      onTap: onTap,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      semanticLabel: '$title: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: FitSpacing.s12),
          FitProgress(value: progress, color: accent),
        ],
      ),
    );
  }
}
