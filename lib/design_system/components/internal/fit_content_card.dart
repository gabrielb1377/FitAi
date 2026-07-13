import 'package:flutter/material.dart';

import '../../tokens/fit_spacing.dart';
import '../fit_card.dart';
import '../fit_progress.dart';

/// Composicao interna compartilhada pelos cards de dominio do Design System.
class FitContentCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> tags;
  final List<Widget> metadata;
  final double? progress;
  final String? progressLabel;
  final Widget? action;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const FitContentCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.tags = const [],
    this.metadata = const [],
    this.progress,
    this.progressLabel,
    this.action,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: onTap,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      semanticLabel: semanticLabel ?? title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: FitSpacing.s12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: FitSpacing.s4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: FitSpacing.s8),
                trailing!,
              ],
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s12),
            Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: tags,
            ),
          ],
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s12),
            Wrap(
              spacing: FitSpacing.s16,
              runSpacing: FitSpacing.s8,
              children: metadata,
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: FitSpacing.s16),
            FitProgress(value: progress!, label: progressLabel),
          ],
          if (action != null) ...[
            const SizedBox(height: FitSpacing.s16),
            action!,
          ],
        ],
      ),
    );
  }
}
