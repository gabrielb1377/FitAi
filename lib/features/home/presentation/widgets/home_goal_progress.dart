import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';

class HomeGoalProgress extends StatelessWidget {
  const HomeGoalProgress({
    super.key,
    required this.goal,
    required this.onOpenGoals,
  });

  final FitaiMetaModel? goal;
  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    final current = goal;
    return FitSection(
      title: 'Meta principal',
      onViewAll: onOpenGoals,
      child: current == null
          ? FitEmptyState(
              icon: Icons.flag_outlined,
              title: 'Nenhuma meta disponivel',
              description:
                  'Abra Metas para acompanhar seus proximos objetivos.',
              actionLabel: 'Ver metas',
              onAction: onOpenGoals,
            )
          : FitProgressCard(
              title: current.titulo,
              value: _valueLabel(current),
              progress: current.progresso,
              icon: _iconFor(current.categoria),
              description: current.tempoRestante.isEmpty
                  ? current.statusLabel
                  : current.tempoRestante,
              color: _colorFor(current.categoria),
              onTap: onOpenGoals,
            ),
    );
  }

  String _valueLabel(FitaiMetaModel goal) {
    final current = _format(goal.valorAtual);
    final target = _format(goal.valorObjetivo);
    final unit = goal.unidade.trim();
    return '$current / $target${unit.isEmpty ? '' : ' $unit'}';
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  IconData _iconFor(FitaiMetaCategoria category) => switch (category) {
    FitaiMetaCategoria.treinos => Icons.fitness_center_rounded,
    FitaiMetaCategoria.corridas => Icons.directions_run_rounded,
    FitaiMetaCategoria.passos => Icons.directions_walk_rounded,
    FitaiMetaCategoria.forca => Icons.monitor_weight_outlined,
    FitaiMetaCategoria.corpo => Icons.accessibility_new_rounded,
  };

  Color _colorFor(FitaiMetaCategoria category) => switch (category) {
    FitaiMetaCategoria.corridas => FitColors.running,
    FitaiMetaCategoria.passos => FitColors.steps,
    _ => FitColors.primary,
  };
}
