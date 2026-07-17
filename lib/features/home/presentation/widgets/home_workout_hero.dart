import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../services/treino_do_dia_service.dart';

class HomeWorkoutHero extends StatelessWidget {
  const HomeWorkoutHero({
    super.key,
    required this.selection,
    required this.runningActive,
    required this.runningDistance,
    required this.runningSeconds,
    required this.onOpenWorkout,
    required this.onCreatePlan,
    required this.onOpenRunning,
  });

  final TreinoDoDiaSelecao selection;
  final bool runningActive;
  final double runningDistance;
  final int runningSeconds;
  final VoidCallback onOpenWorkout;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenRunning;

  @override
  Widget build(BuildContext context) {
    if (runningActive) {
      return FitWorkoutHero(
        eyebrow: 'Agora',
        title: 'Corrida em andamento',
        subtitle: 'Sua sessao continua ativa.',
        badge: const FitBadge.success(label: 'Ativa'),
        metrics: [
          FitStatChip(
            label: 'km',
            value: runningDistance.toStringAsFixed(2),
            icon: Icons.route_rounded,
          ),
          FitStatChip(
            label: 'tempo',
            value: _formatDuration(runningSeconds),
            icon: Icons.timer_outlined,
          ),
        ],
        action: FitButton(
          label: 'Continuar corrida',
          expand: true,
          icon: Icons.directions_run_rounded,
          onPressed: onOpenRunning,
        ),
        onTap: onOpenRunning,
      );
    }

    final workout = selection.treino;
    if (workout == null) {
      return FitWorkoutHero(
        eyebrow: 'Proximo passo',
        title: 'Crie seu primeiro plano',
        subtitle: 'Escolha um plano para organizar seus proximos treinos.',
        action: FitButton(
          label: 'Criar plano',
          expand: true,
          icon: Icons.add_rounded,
          onPressed: onCreatePlan,
        ),
      );
    }

    final completed = selection.treinoConcluidoHoje;
    final group = workout.grupoDia.trim().isNotEmpty
        ? workout.grupoDia.trim()
        : workout.objetivo.trim();
    return FitWorkoutHero(
      eyebrow: selection.diaDeDescanso ? 'Recuperacao' : 'Treino de hoje',
      title: workout.nome,
      subtitle: group.isEmpty ? null : group,
      badge: completed ? const FitBadge.success() : null,
      metrics: [
        FitStatChip(
          label: 'min',
          value: '${workout.tempoEstimado}',
          icon: Icons.schedule_rounded,
        ),
        if (workout.divisao.trim().isNotEmpty)
          FitStatChip(
            label: 'divisao',
            value: workout.divisao,
            icon: Icons.view_week_outlined,
          ),
      ],
      progress: completed ? 1 : null,
      progressLabel: completed ? 'Concluido hoje' : null,
      action: FitButton(
        label: completed
            ? 'Ver treino'
            : selection.diaDeDescanso
            ? 'Abrir treino leve'
            : 'Iniciar treino',
        expand: true,
        icon: completed ? Icons.check_rounded : Icons.play_arrow_rounded,
        onPressed: onOpenWorkout,
      ),
      onTap: onOpenWorkout,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
}
