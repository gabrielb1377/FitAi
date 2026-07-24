import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/coach_insight_model.dart';

class HomeCoachInsight extends StatelessWidget {
  const HomeCoachInsight({
    super.key,
    required this.insights,
    required this.onOpenCoach,
  });

  final List<CoachInsightModel> insights;
  final VoidCallback onOpenCoach;

  @override
  Widget build(BuildContext context) {
    final insight = insights.isEmpty ? null : insights.first;
    return FitSection(
      title: 'Coach FitIA',
      child: FitCard(
        onTap: onOpenCoach,
        variant: FitCardVariant.clickable,
        padding: const EdgeInsets.all(FitSpacing.s12),
        semanticLabel: 'Abrir Coach FitIA',
        child: Row(
          children: [
            Container(
              width: FitLayout.avatarMedium,
              height: FitLayout.avatarMedium,
              decoration: const BoxDecoration(
                color: FitColors.aiContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                FitIcons.coach,
                color: FitColors.ai,
                size: FitLayout.iconSizeMedium,
              ),
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight?.titulo ?? 'Ainda sem insights',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: FitSpacing.s2),
                  Text(
                    insight?.descricao ??
                        'Registre atividades para receber orientações.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: FitSpacing.s8),
            const Icon(
              FitIcons.forward,
              color: FitColors.textSecondary,
              size: FitLayout.iconSizeCompact,
            ),
          ],
        ),
      ),
    );
  }
}
