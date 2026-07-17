import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/achievement_model.dart';

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
    if (item == null) return const SizedBox.shrink();
    return FitSection(
      title: 'Conquista recente',
      onViewAll: onOpenAchievements,
      child: FitActionTile(
        title: item.nome,
        description: item.descricao,
        icon: Icons.emoji_events_rounded,
        color: FitColors.achievement,
        onTap: onOpenAchievements,
        trailing: const FitBadge(
          label: 'Conquista',
          tone: FitBadgeTone.warning,
          icon: Icons.bolt_rounded,
        ),
      ),
    );
  }
}
