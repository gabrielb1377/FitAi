import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../domain/profile_models.dart';

/// Resumo de atividade derivado das fontes canônicas ja lidas pelo Perfil.
class ProfileSummarySection extends StatelessWidget {
  const ProfileSummarySection({super.key, required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final lastActivity = _lastActivity(stats);
    final hasDailyGoal =
        stats.latestSteps != null && (stats.dailyStepsGoal ?? 0) > 0;
    final progress = hasDailyGoal
        ? (stats.latestSteps! / stats.dailyStepsGoal!).clamp(0.0, 1.0)
        : 0.0;
    return FitSection(
      title: 'Resumo',
      child: FitCard(
        child: Column(
          children: [
            FitHorizontalMetric(
              label: 'Ultima atividade',
              value: lastActivity.label,
              detail: lastActivity.detail,
              icon: lastActivity.icon,
              unavailable: lastActivity.unavailable,
            ),
            const FitDivider(verticalSpacing: FitSpacing.s12),
            FitHorizontalMetric(
              label: 'Ultima corrida',
              value: stats.lastRunDistanceKm == null
                  ? '--'
                  : '${stats.lastRunDistanceKm!.toStringAsFixed(1)} km',
              detail: _dateLabel(stats.lastRunAt),
              icon: FitIcons.running,
              unavailable: stats.lastRunDistanceKm == null,
            ),
            const FitDivider(verticalSpacing: FitSpacing.s12),
            const FitHorizontalMetric(
              label: 'Plano atual',
              value: '--',
              detail: 'Indisponivel',
              icon: FitIcons.plans,
              unavailable: true,
            ),
            const FitDivider(verticalSpacing: FitSpacing.s12),
            FitHorizontalMetric(
              label: 'Meta diaria',
              value: hasDailyGoal ? '${stats.latestSteps}' : '--',
              detail: hasDailyGoal
                  ? '${stats.dailyStepsGoal} passos'
                  : 'Sem meta local',
              icon: FitIcons.steps,
              unavailable: !hasDailyGoal,
            ),
            if (hasDailyGoal) ...[
              const SizedBox(height: FitSpacing.s12),
              FitProgress(
                value: progress,
                label: 'Passos de hoje',
                trailing: '${(progress * 100).round()}%',
                animate: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ProfileActivity _lastActivity(UserStats stats) {
    final candidates = <_ProfileActivity>[
      if (stats.lastWorkoutAt != null)
        _ProfileActivity(
          date: stats.lastWorkoutAt!,
          label: stats.lastWorkoutName ?? 'Treino concluido',
          detail: _dateLabel(stats.lastWorkoutAt),
          icon: FitIcons.workout,
        ),
      if (stats.lastRunAt != null)
        _ProfileActivity(
          date: stats.lastRunAt!,
          label: 'Corrida concluida',
          detail: _dateLabel(stats.lastRunAt),
          icon: FitIcons.running,
        ),
      if (stats.lastStepsAt != null && (stats.latestSteps ?? 0) > 0)
        _ProfileActivity(
          date: stats.lastStepsAt!,
          label: '${stats.latestSteps} passos',
          detail: _dateLabel(stats.lastStepsAt),
          icon: FitIcons.steps,
        ),
    ];
    if (candidates.isEmpty) {
      return const _ProfileActivity(
        label: '--',
        detail: 'Nenhuma atividade local',
        icon: FitIcons.history,
        unavailable: true,
      );
    }
    candidates.sort((first, second) => second.date!.compareTo(first.date!));
    return candidates.first;
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Indisponivel';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _ProfileActivity {
  const _ProfileActivity({
    this.date,
    required this.label,
    required this.detail,
    required this.icon,
    this.unavailable = false,
  });

  final DateTime? date;
  final String label;
  final String detail;
  final IconData icon;
  final bool unavailable;
}
