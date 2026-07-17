import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_meta_model.dart';

class HomeGoalTile extends StatelessWidget {
  const HomeGoalTile({super.key, required this.goal});

  final FitaiMetaModel goal;

  @override
  Widget build(BuildContext context) {
    return FitProgressCard(
      title: goal.titulo,
      value: _valueLabel(),
      progress: goal.progresso,
      icon: _icon,
      description: goal.tempoRestante.isEmpty
          ? goal.statusLabel
          : '${goal.statusLabel} - ${goal.tempoRestante}',
      color: _color,
      action: FitBadge(
        label: goal.statusLabel,
        tone: goal.status == FitaiMetaStatus.concluida
            ? FitBadgeTone.success
            : FitBadgeTone.neutral,
      ),
    );
  }

  String _valueLabel() {
    final unit = goal.unidade.trim();
    return '${_format(goal.valorAtual)} / ${_format(goal.valorObjetivo)}${unit.isEmpty ? '' : ' $unit'}';
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');

  IconData get _icon => switch (goal.categoria) {
    FitaiMetaCategoria.treinos => Icons.fitness_center_rounded,
    FitaiMetaCategoria.corridas => Icons.directions_run_rounded,
    FitaiMetaCategoria.passos => Icons.directions_walk_rounded,
    FitaiMetaCategoria.forca => Icons.monitor_weight_outlined,
    FitaiMetaCategoria.corpo => Icons.accessibility_new_rounded,
  };

  Color get _color => switch (goal.categoria) {
    FitaiMetaCategoria.corridas => FitColors.running,
    FitaiMetaCategoria.passos => FitColors.steps,
    _ => FitColors.primary,
  };
}
