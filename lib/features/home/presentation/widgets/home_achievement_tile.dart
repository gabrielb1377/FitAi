import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/achievement_model.dart';

class HomeAchievementTile extends StatelessWidget {
  const HomeAchievementTile({super.key, required this.achievement});

  final AchievementModel achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.desbloqueada;
    final accent = unlocked ? FitColors.achievement : FitColors.textHint;
    return Semantics(
      label:
          '${achievement.nome}. ${unlocked ? 'Desbloqueada' : 'Bloqueada'}. ${achievement.descricao}',
      child: Container(
        padding: const EdgeInsets.all(FitSpacing.s16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: FitRadius.largeBorder,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withAlpha(24),
                borderRadius: FitRadius.mediumBorder,
              ),
              child: Icon(
                unlocked
                    ? Icons.emoji_events_rounded
                    : Icons.lock_outline_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.nome,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: unlocked ? null : FitColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    achievement.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: FitSpacing.s8),
            FitBadge(
              label: unlocked ? 'Concluida' : 'Bloqueada',
              tone: unlocked ? FitBadgeTone.warning : FitBadgeTone.neutral,
            ),
          ],
        ),
      ),
    );
  }
}
