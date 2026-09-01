import 'package:flutter/material.dart';

import '../../../models/exercicio_model.dart';
import '../../../widgets/exercicio_gif_viewer.dart';
import 'exercise_comment_field.dart';
import 'exercise_gif_card.dart';
import 'exercise_history.dart';
import 'exercise_info_card.dart';
import 'exercise_inputs.dart';
import 'exercise_stats_circles.dart';
import 'workout_progress_bar.dart';

class WorkoutCurrentExercise extends StatelessWidget {
  final ExercicioModel exercicio;
  final String restText;
  final String seriesText;
  final bool restHighlighted;
  final TextEditingController pesoController;
  final TextEditingController repeticoesController;
  final TextEditingController comentarioController;
  final ValueChanged<String> onRepeticoesChanged;
  final VoidCallback onIncrementRepeticoes;
  final bool commentOpen;
  final VoidCallback onToggleComment;
  final List<ExerciseHistoryEntry> historyEntries;
  final double progress;

  const WorkoutCurrentExercise({
    super.key,
    required this.exercicio,
    required this.restText,
    required this.seriesText,
    required this.restHighlighted,
    required this.pesoController,
    required this.repeticoesController,
    required this.comentarioController,
    required this.onRepeticoesChanged,
    required this.onIncrementRepeticoes,
    required this.commentOpen,
    required this.onToggleComment,
    required this.historyEntries,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final canonicalExerciseId = exercicio.canonicalExerciseId.trim().isNotEmpty
        ? exercicio.canonicalExerciseId
        : exercicio.id;
    final repetitionsText = repeticoesController.text.trim().isEmpty
        ? '0'
        : repeticoesController.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        children: [
          ExerciseGifCard(
            canonicalExerciseId: canonicalExerciseId,
            title: exercicio.nome,
            onTap: () => mostrarGifExercicioTelaCheia(
              context,
              canonicalExerciseId: canonicalExerciseId,
              titulo: exercicio.nome,
              subtitulo: exercicio.categoria,
            ),
          ),
          const SizedBox(height: 22),
          ExerciseInfoCard(
            name: exercicio.nome,
            recommendation: _recommendation(),
          ),
          const SizedBox(height: 20),
          ExerciseStatsCircles(
            repetitions: repetitionsText,
            rest: restText,
            series: seriesText,
            restHighlighted: restHighlighted,
          ),
          const SizedBox(height: 22),
          ExerciseInputs(
            pesoController: pesoController,
            repeticoesController: repeticoesController,
            onRepeticoesChanged: onRepeticoesChanged,
            onIncrementRepeticoes: onIncrementRepeticoes,
          ),
          const SizedBox(height: 10),
          ExerciseCommentField(
            isOpen: commentOpen,
            controller: comentarioController,
            onToggle: onToggleComment,
          ),
          const SizedBox(height: 18),
          ExerciseHistory(entries: historyEntries),
          const SizedBox(height: 18),
          WorkoutProgressBar(progress: progress),
        ],
      ),
    );
  }

  String _recommendation() {
    final peso = pesoController.text.trim();
    final reps = repeticoesController.text.trim().isEmpty
        ? '8-12'
        : repeticoesController.text.trim();
    final carga = peso.isEmpty || peso == '0'
        ? 'uma carga confortavel'
        : '$peso kg';
    return 'Peso recomendado: $carga. Busque $reps repeticoes com controle e foco em ${_mainMuscle().toLowerCase()}.';
  }

  String _mainMuscle() {
    if (exercicio.musculos.isNotEmpty) return exercicio.musculos.first;
    return exercicio.categoria;
  }
}
