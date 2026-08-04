import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../progression/progression.dart';

/// Nivel, sequencias e marco mais recente do agregado local de progressao.
class ProfileProgressionSection extends StatelessWidget {
  const ProfileProgressionSection({
    super.key,
    required this.snapshot,
    required this.onViewHistory,
  });

  final ProgressionSnapshot snapshot;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final balance = snapshot.balance;
    final streaks = snapshot.streaks.take(3).toList();
    final milestone = snapshot.milestones.isEmpty
        ? null
        : snapshot.milestones.last;
    final useIconAction = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return FitSection(
      title: 'Evolucao',
      onViewAll: useIconAction ? null : onViewHistory,
      viewAllLabel: 'Historico',
      action: useIconAction
          ? FitIconButton(
              icon: FitIcons.history,
              tooltip: 'Abrir historico de XP',
              onPressed: onViewHistory,
            )
          : null,
      child: Column(
        children: [
          FitXPProgressCard(
            title: 'Nivel ${balance.currentLevel}',
            xpLabel: '${balance.totalXp} XP total',
            progress: balance.progress,
            nextLevelLabel: '${balance.remainingXp} XP para o proximo nivel',
          ),
          if (streaks.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s12),
            FitCard(
              semanticLabel: 'Sequencias atuais',
              child: Column(
                children: [
                  for (var index = 0; index < streaks.length; index++) ...[
                    FitHorizontalMetric(
                      label: _streakLabel(streaks[index].type),
                      value: '${streaks[index].currentDays} dias',
                      detail: 'Melhor: ${streaks[index].bestDays} dias',
                      icon: FitIcons.streak,
                    ),
                    if (index < streaks.length - 1)
                      const FitDivider(verticalSpacing: FitSpacing.s12),
                  ],
                ],
              ),
            ),
          ],
          if (milestone != null) ...[
            const SizedBox(height: FitSpacing.s12),
            FitInfoCard(
              title: 'Marco recente',
              description: milestone.title,
              icon: FitIcons.achievement,
            ),
          ],
        ],
      ),
    );
  }

  String _streakLabel(StreakType type) => switch (type) {
    StreakType.activeDays => 'Dias ativos',
    StreakType.workouts => 'Treinos',
    StreakType.stepsGoals => 'Metas de passos',
    StreakType.runs => 'Corridas',
  };
}
