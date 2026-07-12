import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/historico_treino_model.dart';
import '../../../services/treino_do_dia_service.dart';
import 'home_goal_progress.dart';

/// Deriva dados visuais de meta sem acessar armazenamento ou alterar estado.
abstract final class HomeGoalResolver {
  static HistoricoTreinoModel? lastRecord(List<HistoricoTreinoModel> history) {
    final records = history.where((item) => item.recordesBatidos > 0).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return records.isEmpty ? null : records.first;
  }

  static HomeGoalData nextGoal({
    required TreinoDoDiaSelecao selection,
    required int steps,
    required int weeklyXp,
  }) {
    if (selection.treino == null) {
      return const HomeGoalData(
        title: 'Criar plano',
        detail: 'Monte sua primeira ficha',
        remainingLabel: 'Plano pendente',
        progress: 0,
        icon: Icons.add_task_rounded,
        color: FitColors.primary,
      );
    }
    if (!selection.treinoConcluidoHoje && !selection.diaDeDescanso) {
      return const HomeGoalData(
        title: 'Treino do dia',
        detail: 'Concluir 1 sessao hoje',
        remainingLabel: '1 treino restante',
        progress: 0.35,
        icon: Icons.play_circle_fill_rounded,
        color: FitColors.primary,
      );
    }
    if (steps < 8000) {
      return HomeGoalData(
        title: '8.000 passos',
        detail: '$steps/8000 hoje',
        remainingLabel: '${8000 - steps} passos restantes',
        progress: steps / 8000,
        icon: Icons.directions_walk_rounded,
        color: FitColors.info,
      );
    }
    if (weeklyXp < 200) {
      return HomeGoalData(
        title: '200 XP semana',
        detail: '$weeklyXp/200 XP',
        remainingLabel: '${200 - weeklyXp} XP restantes',
        progress: weeklyXp / 200,
        icon: Icons.bolt_rounded,
        color: FitColors.warning,
      );
    }
    return const HomeGoalData(
      title: 'Recuperar bem',
      detail: 'Sono, mobilidade e constancia',
      remainingLabel: 'Meta de hoje concluida',
      progress: 1,
      icon: Icons.self_improvement_rounded,
      color: FitColors.primaryLight,
    );
  }
}
