import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/treino_model.dart';
import '../../../services/ia_evolutiva_service.dart';
import '../../../services/treino_do_dia_service.dart';
import 'fitia_recomendacao_card.dart';
import 'missoes_hoje_card.dart';

/// Mantem acoes e informacoes secundarias acessiveis sem competir com o foco.
class HomeSecondaryContent extends StatelessWidget {
  final TreinoDoDiaSelecao selection;
  final IaEvolutivaRecomendacao? recommendation;
  final bool isLoading;
  final bool workoutCompletedToday;
  final int steps;
  final int workoutsThisWeek;
  final int weeklyXp;
  final Future<void> Function(TreinoModel workout) onOpenWorkout;
  final Future<void> Function() onCreateWorkout;
  final Future<void> Function() onGenerateWithAi;

  const HomeSecondaryContent({
    super.key,
    required this.selection,
    required this.recommendation,
    required this.isLoading,
    required this.workoutCompletedToday,
    required this.steps,
    required this.workoutsThisWeek,
    required this.weeklyXp,
    required this.onOpenWorkout,
    required this.onCreateWorkout,
    required this.onGenerateWithAi,
  });

  @override
  Widget build(BuildContext context) {
    final workout = selection.treino;
    final canStart = workout != null && !selection.diaDeDescanso;
    return FitSection(
      title: 'Mais para hoje',
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Acoes, recomendacoes e missoes'),
        childrenPadding: const EdgeInsets.only(top: FitSpacing.s12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: [
                if (canStart)
                  FitButton(
                    label: 'Iniciar agora',
                    size: FitButtonSize.compact,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => onOpenWorkout(workout),
                  ),
                FitButton(
                  label: 'Gerar IA',
                  size: FitButtonSize.compact,
                  icon: Icons.auto_awesome_rounded,
                  variant: FitButtonVariant.secondary,
                  onPressed: onGenerateWithAi,
                ),
                FitButton(
                  label: 'Novo plano',
                  size: FitButtonSize.compact,
                  icon: Icons.add_rounded,
                  variant: FitButtonVariant.ghost,
                  onPressed: onCreateWorkout,
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s20),
          FitiaRecomendacaoCard(
            selecao: selection,
            recomendacao: recommendation,
            carregandoTreinos: isLoading,
          ),
          const SizedBox(height: FitSpacing.s16),
          MissoesHojeCard(
            treinoConcluidoHoje: workoutCompletedToday,
            passos: steps,
            treinosSemana: workoutsThisWeek,
            xpSemana: weeklyXp,
          ),
        ],
      ),
    );
  }
}
