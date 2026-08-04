import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../progression/progression.dart';
import '../../domain/profile_models.dart';

/// Objetivos e medidas que existem no snapshot local de Perfil.
class ProfileGoalsSection extends StatelessWidget {
  const ProfileGoalsSection({
    super.key,
    required this.snapshot,
    required this.onConfigure,
  });

  final ProfileSnapshot snapshot;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final useIconAction = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final profile = snapshot.profile;
    final goals = snapshot.progression.activeGoals.take(3).toList();
    final hasContent =
        profile.weightKg != null ||
        profile.heightCm != null ||
        goals.isNotEmpty;
    return FitSection(
      title: 'Objetivos',
      onViewAll: useIconAction ? null : onConfigure,
      viewAllLabel: 'Configurar',
      action: useIconAction
          ? FitIconButton(
              icon: FitIcons.edit,
              tooltip: 'Configurar objetivos',
              onPressed: onConfigure,
            )
          : null,
      child: FitCard(
        child: hasContent
            ? Column(
                children: [
                  FitHorizontalMetric(
                    label: 'Peso',
                    value: _weightLabel(profile.weightKg),
                    icon: FitIcons.weight,
                    unavailable: profile.weightKg == null,
                  ),
                  const FitDivider(verticalSpacing: FitSpacing.s12),
                  FitHorizontalMetric(
                    label: 'Altura',
                    value: _heightLabel(profile.heightCm),
                    icon: FitIcons.muscles,
                    unavailable: profile.heightCm == null,
                  ),
                  for (final goal in goals) ...[
                    const FitDivider(verticalSpacing: FitSpacing.s12),
                    FitHorizontalMetric(
                      label: _goalLabel(goal.type),
                      value: '${goal.currentValue}/${goal.target}',
                      detail: _periodLabel(goal.period),
                      icon: FitIcons.goal,
                    ),
                    const SizedBox(height: FitSpacing.s8),
                    FitProgress(
                      value: goal.progress,
                      label: _goalStatusLabel(goal.status),
                      trailing: '${(goal.progress * 100).round()}%',
                      animate: true,
                    ),
                  ],
                ],
              )
            : FitEmptyState(
                icon: FitIcons.goal,
                title: 'Objetivos ainda nao definidos',
                description:
                    'Adicione suas medidas e um objetivo para acompanhar sua evolucao.',
                actionLabel: 'Configurar perfil',
                onAction: onConfigure,
              ),
      ),
    );
  }

  String _weightLabel(double? value) => value == null
      ? '--'
      : '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} kg';

  String _heightLabel(double? value) => value == null
      ? '--'
      : '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} cm';

  String _goalLabel(GoalType type) => switch (type) {
    GoalType.weeklyWorkouts => 'Treinos na semana',
    GoalType.weeklyRuns => 'Corridas na semana',
    GoalType.weeklyDistance => 'Distancia na semana',
    GoalType.dailySteps => 'Passos de hoje',
    GoalType.weeklyActiveDays => 'Dias ativos na semana',
    GoalType.monthlyFrequency => 'Atividades no mes',
  };

  String _periodLabel(GoalPeriod period) => switch (period) {
    GoalPeriod.daily => 'Periodo diario',
    GoalPeriod.weekly => 'Periodo semanal',
    GoalPeriod.monthly => 'Periodo mensal',
  };

  String _goalStatusLabel(GoalStatus status) => switch (status) {
    GoalStatus.active => 'Em andamento',
    GoalStatus.completed => 'Concluida',
    GoalStatus.expired => 'Encerrada',
  };
}
