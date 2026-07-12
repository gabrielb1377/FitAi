import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

/// Dados de meta prontos para apresentacao, sem acessar servicos ou navegacao.
class HomeGoalData {
  final String title;
  final String detail;
  final String remainingLabel;
  final double progress;
  final IconData icon;
  final Color color;

  const HomeGoalData({
    required this.title,
    required this.detail,
    required this.remainingLabel,
    required this.progress,
    required this.icon,
    required this.color,
  });
}

/// Resume a meta principal e os indicadores de progresso essenciais.
class HomeGoalProgress extends StatelessWidget {
  final HomeGoalData goal;
  final int xp;
  final int xpForNextLevel;
  final int level;
  final int currentStreak;
  final int recordCount;
  final VoidCallback? onOpenGoals;

  const HomeGoalProgress({
    super.key,
    required this.goal,
    required this.xp,
    required this.xpForNextLevel,
    required this.level,
    required this.currentStreak,
    required this.recordCount,
    this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress.clamp(0.0, 1.0) * 100).round();
    return FitSection(
      title: 'Progresso e metas',
      action: onOpenGoals == null
          ? null
          : TextButton(onPressed: onOpenGoals, child: const Text('Ver metas')),
      child: FitCard(
        variant: FitCardVariant.outlined,
        leading: Icon(goal.icon, color: goal.color),
        title: goal.title,
        subtitle: goal.detail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FitProgress(
              value: goal.progress,
              color: goal.color,
              label: goal.remainingLabel,
              trailing: '$percent%',
            ),
            const SizedBox(height: FitSpacing.s20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 420 ? 2 : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * FitSpacing.s16) /
                    columns;
                return Wrap(
                  spacing: FitSpacing.s16,
                  runSpacing: FitSpacing.s16,
                  children: [
                    SizedBox(
                      width: width,
                      child: FitMetric(
                        label: 'Nivel',
                        value: '$level',
                        detail: '$xp/$xpForNextLevel XP',
                        icon: Icons.bolt_rounded,
                        color: context.colors.primary,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FitMetric(
                        label: 'Sequencia',
                        value: '$currentStreak dias',
                        icon: Icons.local_fire_department_rounded,
                        color: context.colors.tertiary,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FitMetric(
                        label: 'Recordes',
                        value: recordCount == 0 ? 'Sem PR' : '+$recordCount',
                        icon: Icons.emoji_events_rounded,
                        color: context.colors.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
