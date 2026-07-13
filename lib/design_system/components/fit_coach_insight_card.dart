import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';
import 'fit_badge.dart';
import 'fit_button.dart';
import 'fit_coach_card.dart';

/// Um insight explicavel do Coach, com no maximo uma acao contextual.
class FitCoachInsightCard extends StatelessWidget {
  final String title;
  final String insight;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isAiGenerated;

  const FitCoachInsightCard({
    super.key,
    required this.title,
    required this.insight,
    this.actionLabel,
    this.onAction,
    this.isAiGenerated = true,
  }) : assert((actionLabel == null) == (onAction == null));

  @override
  Widget build(BuildContext context) {
    return FitCoachCard(
      title: title,
      action: isAiGenerated ? const FitBadge.ai() : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onAction != null) ...[
            const SizedBox(height: FitSpacing.s12),
            FitButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: FitButtonVariant.ghost,
              size: FitButtonSize.compact,
            ),
          ],
        ],
      ),
    );
  }
}
