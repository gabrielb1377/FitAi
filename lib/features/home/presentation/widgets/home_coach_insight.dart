import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/coach_insight_model.dart';

/// Atalho compacto para o Coach, conforme o bloco de IA do prototipo Home.
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
    return FitCard(
      key: const ValueKey('home-coach-card'),
      onTap: onOpenCoach,
      variant: FitCardVariant.clickable,
      color: FitColors.aiContainer,
      borderColor: FitColors.borderSubtle,
      padding: const EdgeInsets.all(FitSpacing.s16),
      semanticLabel: insight == null
          ? 'Abrir Coach FitIA. Ainda sem insights.'
          : 'Abrir Coach FitIA. ${insight.titulo}. ${insight.descricao}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CoachIcon(),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight?.titulo ?? 'Ainda sem insights',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: FitColors.ai,
                  ),
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  insight?.descricao ??
                      'Registre atividades para receber orientacoes.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: FitColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          const Icon(
            FitIcons.forward,
            color: FitColors.textTertiary,
            size: FitLayout.iconSizeCompact,
          ),
        ],
      ),
    );
  }
}

class _CoachIcon extends StatelessWidget {
  const _CoachIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FitLayout.domainThumbnailSmall,
      height: FitLayout.domainThumbnailSmall,
      decoration: const BoxDecoration(
        color: FitColors.ai,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        FitIcons.coach,
        color: FitColors.onInfo,
        size: FitLayout.iconSizeCompact,
      ),
    );
  }
}
