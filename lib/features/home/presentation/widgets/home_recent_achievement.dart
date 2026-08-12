import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/achievement_model.dart';

/// Destaque discreto que preserva o acesso a conquistas fora do HTML canônico.
class HomeRecentAchievement extends StatelessWidget {
  const HomeRecentAchievement({
    super.key,
    required this.achievement,
    required this.onOpenAchievements,
  });

  final AchievementModel? achievement;
  final VoidCallback onOpenAchievements;

  @override
  Widget build(BuildContext context) {
    final item = achievement;
    return FitCard(
      key: const ValueKey('home-recent-achievement'),
      onTap: onOpenAchievements,
      variant: FitCardVariant.clickable,
      padding: const EdgeInsets.all(FitSpacing.s16),
      semanticLabel: item == null
          ? 'Abrir conquistas'
          : 'Conquista recente: ${item.nome}',
      child: Row(
        children: [
          Container(
            width: FitLayout.avatarSmall,
            height: FitLayout.avatarSmall,
            decoration: const BoxDecoration(
              color: FitColors.achievementContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FitIcons.achievement,
              color: FitColors.achievement,
              size: FitLayout.iconSizeCompact,
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item?.nome ?? 'Suas conquistas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  item?.descricao ??
                      'Continue ativo para desbloquear novos marcos.',
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
            color: FitColors.textTertiary,
            size: FitLayout.iconSizeCompact,
          ),
        ],
      ),
    );
  }
}
