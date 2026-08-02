import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/daily_steps_model.dart';

/// Resumo diário honesto: métricas estimadas só aparecem quando a fonte as
/// forneceu e nunca são deduzidas a partir da quantidade de passos.
class StepsDailyOverview extends StatelessWidget {
  const StepsDailyOverview({
    super.key,
    required this.record,
    required this.goal,
    required this.status,
    required this.onEditGoal,
  });

  final DailyStepsModel? record;
  final int goal;
  final String status;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final current = record;
    if (current == null) {
      return FitCard(
        title: 'Passos de hoje',
        subtitle: 'A fonte de passos ainda não enviou um resumo para hoje.',
        leading: const Icon(Icons.directions_walk_rounded),
        footer: Align(
          alignment: Alignment.centerRight,
          child: FitButton(
            label: 'Definir meta',
            variant: FitButtonVariant.ghost,
            onPressed: onEditGoal,
          ),
        ),
        child: Text(status, style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final percentage = (current.progress * 100).round();
    return Semantics(
      label:
          'Passos de hoje: ${current.steps} de ${current.goal}. Progresso de $percentage%. ${current.sourceLabel}.',
      child: FitCard(
        title: 'Passos de hoje',
        subtitle: current.sourceLabel,
        leading: const Icon(Icons.directions_walk_rounded),
        trailing: FitBadge(
          label: _syncLabel(current.syncStatus),
          tone: _syncTone(current.syncStatus),
        ),
        footer: Align(
          alignment: Alignment.centerRight,
          child: FitButton(
            label: 'Editar meta',
            variant: FitButtonVariant.ghost,
            icon: Icons.edit_outlined,
            onPressed: onEditGoal,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${current.steps}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: FitSpacing.s4),
            Text(
              'de ${current.goal} passos na meta diária',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: FitSpacing.s20),
            FitProgress(
              value: current.progress,
              label: 'Progresso diário',
              trailing: '$percentage%',
            ),
            if (current.hasEstimatedDistance ||
                current.hasEstimatedCalories) ...[
              const SizedBox(height: FitSpacing.s16),
              Wrap(
                spacing: FitSpacing.s12,
                runSpacing: FitSpacing.s8,
                children: [
                  if (current.estimatedDistanceMeters != null)
                    _EstimateLabel(
                      icon: Icons.route_outlined,
                      label:
                          'Distância estimada ${(current.estimatedDistanceMeters! / 1000).toStringAsFixed(1)} km',
                    ),
                  if (current.estimatedCalories != null)
                    _EstimateLabel(
                      icon: Icons.local_fire_department_outlined,
                      label:
                          'Calorias estimadas ${current.estimatedCalories!.toStringAsFixed(0)} kcal',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateLabel extends StatelessWidget {
  const _EstimateLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: FitLayout.iconSizeSmall),
          const SizedBox(width: FitSpacing.s4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

String _syncLabel(DailyStepsSyncStatus status) {
  return switch (status) {
    DailyStepsSyncStatus.local => 'Local',
    DailyStepsSyncStatus.pending => 'Pendente',
    DailyStepsSyncStatus.syncing => 'Sincronizando',
    DailyStepsSyncStatus.synced => 'Sincronizado',
    DailyStepsSyncStatus.conflict => 'Conflito',
    DailyStepsSyncStatus.failed => 'Erro local',
  };
}

FitBadgeTone _syncTone(DailyStepsSyncStatus status) {
  return switch (status) {
    DailyStepsSyncStatus.synced => FitBadgeTone.success,
    DailyStepsSyncStatus.pending ||
    DailyStepsSyncStatus.syncing => FitBadgeTone.info,
    DailyStepsSyncStatus.conflict ||
    DailyStepsSyncStatus.failed => FitBadgeTone.danger,
    DailyStepsSyncStatus.local => FitBadgeTone.neutral,
  };
}
