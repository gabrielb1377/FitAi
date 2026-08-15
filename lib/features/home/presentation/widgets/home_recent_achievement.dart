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
    return FitActionRow(
      key: const ValueKey('home-recent-achievement'),
      icon: FitIcons.achievement,
      iconColor: context.fitColors.achievement,
      title: item?.nome ?? 'Suas conquistas',
      subtitle:
          item?.descricao ?? 'Continue ativo para desbloquear novos marcos.',
      onTap: onOpenAchievements,
    );
  }
}
