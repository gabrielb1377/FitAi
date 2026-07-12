import 'package:flutter/material.dart';
import '../../../design_system/fit_design_system.dart';
import '../../../models/treino_model.dart';
import '../../../services/running_session_service.dart';
import '../../../services/treino_do_dia_service.dart';
import 'home_entrance.dart';
import 'home_primary_loading.dart';

class HomePrimaryAction extends StatelessWidget {
  final TreinoDoDiaSelecao selection;
  final bool isLoading;
  final Future<void> Function(TreinoModel workout) onOpenWorkout;
  final Future<void> Function() onCreateWorkout;
  final Future<void> Function() onGenerateWithAi;
  const HomePrimaryAction({
    super.key,
    required this.selection,
    required this.isLoading,
    required this.onOpenWorkout,
    required this.onCreateWorkout,
    required this.onGenerateWithAi,
  });
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RunningSessionService.instance,
      builder: (context, _) => HomeEntrance(
        child: FitSection(
          title: 'Seu foco agora',
          child: _buildCard(context, RunningSessionService.instance),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, RunningSessionService running) {
    final workout = selection.treino;
    if (isLoading && workout == null) {
      return const HomePrimaryLoading();
    }
    if (workout == null) {
      return FitCard(
        variant: FitCardVariant.filled,
        elevation: 1,
        leading: const Icon(Icons.fitness_center_rounded),
        title: selection.titulo,
        subtitle: selection.descricao,
        child: Wrap(
          spacing: FitSpacing.s8,
          runSpacing: FitSpacing.s8,
          children: [
            FitButton(
              label: 'Criar treino',
              icon: Icons.add_rounded,
              onPressed: onCreateWorkout,
            ),
            FitButton(
              label: 'Gerar com IA',
              icon: Icons.auto_awesome_rounded,
              variant: FitButtonVariant.secondary,
              onPressed: onGenerateWithAi,
            ),
          ],
        ),
      );
    }

    final completed = selection.treinoConcluidoHoje;
    final isRestDay = selection.diaDeDescanso;
    final title = isRestDay
        ? 'Dia de recuperacao'
        : completed
        ? 'Treino concluido'
        : 'Treino de hoje';
    final buttonLabel = isRestDay
        ? 'Fazer treino leve'
        : completed
        ? 'Repetir treino'
        : 'Iniciar treino';
    return FitCard(
      variant: FitCardVariant.filled,
      elevation: 1,
      leading: const Icon(Icons.fitness_center_rounded),
      title: title,
      subtitle: running.hasActiveSession
          ? 'Corrida ativa tem prioridade agora.'
          : selection.descricao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (running.hasActiveSession) ...[
            FitStatusChip(label: 'Corrida ativa', tone: FitStatusTone.success),
            const SizedBox(height: FitSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: FitMetric(
                    label: 'Distancia',
                    value: '${running.distanceKm.toStringAsFixed(2)} km',
                    icon: Icons.directions_run_rounded,
                    color: context.colors.primary,
                  ),
                ),
                Expanded(
                  child: FitMetric(
                    label: 'Tempo',
                    value: _formatDuration(running.elapsedSeconds),
                    icon: Icons.timer_outlined,
                    color: context.colors.secondary,
                  ),
                ),
              ],
            ),
            const FitDivider(verticalSpacing: FitSpacing.s16),
          ],
          Text(workout.nome, style: context.textTheme.titleLarge),
          const SizedBox(height: FitSpacing.s8),
          Row(
            children: [
              Expanded(
                child: FitTagChip(
                  label: workout.objetivo,
                  icon: Icons.flag_outlined,
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              Expanded(
                child: FitMetric(
                  label: 'Duracao',
                  value: '${workout.tempoEstimado} min',
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          FitButton(
            label: buttonLabel,
            icon: completed ? Icons.replay_rounded : Icons.play_arrow_rounded,
            expand: true,
            onPressed: () => onOpenWorkout(workout),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
