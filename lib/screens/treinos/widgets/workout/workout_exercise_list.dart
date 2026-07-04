import 'package:flutter/material.dart';

import '../../../../models/exercicio_model.dart';
import 'exercise_comment_box.dart';
import 'exercise_gif_card.dart';
import 'exercise_history_card.dart';
import 'exercise_inputs_row.dart';
import 'exercise_stats_circles.dart';
import 'exercise_summary.dart';
import 'rest_timer_card.dart';
import 'workout_secondary_action.dart';

class WorkoutExerciseList extends StatelessWidget {
  final ExercicioModel exercicio;
  final int concluidas;
  final int seriesPorExercicio;
  final int descansoPadrao;
  final int descansoRestante;
  final bool emDescanso;
  final TextEditingController pesoController;
  final TextEditingController repeticoesController;
  final TextEditingController comentarioController;
  final bool comentarioAberto;
  final List<WorkoutHistoryEntry> historico;
  final VoidCallback onAddReps;
  final ValueChanged<String> onInputChanged;
  final VoidCallback onToggleComment;
  final ValueChanged<String> onCommentChanged;
  final VoidCallback onSkipRest;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String Function(TextEditingController controller) texto;

  const WorkoutExerciseList({
    super.key,
    required this.exercicio,
    required this.concluidas,
    required this.seriesPorExercicio,
    required this.descansoPadrao,
    required this.descansoRestante,
    required this.emDescanso,
    required this.pesoController,
    required this.repeticoesController,
    required this.comentarioController,
    required this.comentarioAberto,
    required this.historico,
    required this.onAddReps,
    required this.onInputChanged,
    required this.onToggleComment,
    required this.onCommentChanged,
    required this.onSkipRest,
    required this.onPrevious,
    required this.onNext,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      children: [
        ExerciseGifCard(exercicio: exercicio),
        const SizedBox(height: 18),
        ExerciseSummary(nome: exercicio.nome, categoria: exercicio.categoria),
        const SizedBox(height: 18),
        ExerciseStatsCircles(
          reps: texto(repeticoesController),
          rest: emDescanso ? '${descansoRestante}s' : '${descansoPadrao}s',
          series: '$concluidas/$seriesPorExercicio',
        ),
        if (emDescanso) ...[
          const SizedBox(height: 18),
          RestTimerCard(
            seconds: descansoRestante,
            totalSeconds: descansoPadrao,
            onSkip: onSkipRest,
          ),
        ],
        const SizedBox(height: 18),
        ExerciseInputsRow(
          pesoController: pesoController,
          repeticoesController: repeticoesController,
          onAddReps: onAddReps,
          onChanged: onInputChanged,
        ),
        const SizedBox(height: 12),
        ExerciseCommentBox(
          controller: comentarioController,
          isOpen: comentarioAberto,
          onToggle: onToggleComment,
          onChanged: onCommentChanged,
        ),
        const SizedBox(height: 18),
        ExerciseHistoryCard(entries: historico),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: WorkoutSecondaryAction(
                label: 'Anterior',
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WorkoutSecondaryAction(
                label: 'PrÃ³ximo',
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
