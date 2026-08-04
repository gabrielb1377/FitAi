import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../progression/progression.dart';

/// Mostra o catalogo real e local de conquistas; nada e desbloqueado pela UI.
class ProfileAchievementsSection extends StatelessWidget {
  const ProfileAchievementsSection({
    super.key,
    required this.snapshot,
    required this.onViewAll,
  });

  final ProgressionSnapshot snapshot;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final singleColumn = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final definitions = ProgressionRules.achievements.take(4).toList();
    final unlocked = snapshot.achievements
        .where((item) => item.isUnlocked)
        .length;
    return FitSection(
      title: 'Conquistas',
      onViewAll: onViewAll,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (singleColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked de ${ProgressionRules.achievements.length} desbloqueadas',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: FitSpacing.s12),
                for (final definition in definitions) ...[
                  _AchievementListItem(
                    data: _displayData(definition),
                    onTap: onViewAll,
                  ),
                  const SizedBox(height: FitSpacing.s8),
                ],
              ],
            );
          }
          const columns = 2;
          final width =
              (constraints.maxWidth - FitSpacing.s12 * (columns - 1)) / columns;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$unlocked de ${ProgressionRules.achievements.length} desbloqueadas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: FitSpacing.s12),
              Wrap(
                spacing: FitSpacing.s12,
                runSpacing: FitSpacing.s12,
                children: [
                  for (final definition in definitions)
                    SizedBox(
                      width: width,
                      child: FitAchievementCard(
                        data: _displayData(definition),
                        onTap: onViewAll,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  FitAchievementDisplayData _displayData(AchievementDefinition definition) {
    UserAchievement? achievement;
    for (final item in snapshot.achievements) {
      if (item.achievementId == definition.id) {
        achievement = item;
        break;
      }
    }
    return FitAchievementDisplayData(
      title: definition.name,
      description: definition.description,
      icon: _iconFor(definition.iconKey),
      progress: achievement?.progressValue ?? 0,
      unlocked: achievement?.isUnlocked ?? false,
    );
  }

  IconData _iconFor(String key) => switch (key) {
    'workout' => FitIcons.workout,
    'running' => FitIcons.running,
    'steps' => FitIcons.steps,
    'streak' => FitIcons.streak,
    'library' => FitIcons.library,
    _ => FitIcons.achievement,
  };
}

class _AchievementListItem extends StatelessWidget {
  const _AchievementListItem({required this.data, required this.onTap});

  final FitAchievementDisplayData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: onTap,
      variant: FitCardVariant.clickable,
      semanticLabel: '${data.title}: ${data.description}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(width: FitSpacing.s12),
              Expanded(
                child: Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s8),
          FitAchievementBadge(unlocked: data.unlocked),
          const SizedBox(height: FitSpacing.s8),
          Text(data.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FitSpacing.s8),
          FitProgress(value: data.progress ?? 0, animate: true),
        ],
      ),
    );
  }
}
