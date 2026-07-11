import '../models/exercicio_model.dart';
import '../models/ready_plan_model.dart';
import '../models/treino_model.dart';

class ReadyPlanMapper {
  ReadyPlanMapper._();

  static TreinoModel toTreino(
    ReadyPlanModel plan, {
    required String workoutId,
    required String source,
  }) {
    final exercises = <ExercicioModel>[];
    final days = <TreinoDiaModel>[];

    for (var dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      final ids = <String>[];

      for (
        var exerciseIndex = 0;
        exerciseIndex < day.exercises.length;
        exerciseIndex++
      ) {
        final readyExercise = day.exercises[exerciseIndex];
        final exerciseId = '${workoutId}_${day.id}_${readyExercise.id}';
        ids.add(exerciseId);

        exercises.add(
          ExercicioModel(
            id: exerciseId,
            nome: readyExercise.exerciseName,
            categoria: readyExercise.category.isEmpty
                ? day.muscleGroup
                : readyExercise.category,
            descricao: _description(readyExercise),
            comoExecutar:
                'Execute com controle, postura segura e amplitude confortável.',
            cuidados: 'Reduza a intensidade em caso de dor ou desconforto.',
            musculos: readyExercise.muscles.isEmpty
                ? _groups(day.muscleGroup)
                : readyExercise.muscles,
            equipamentos: readyExercise.equipment.isEmpty
                ? plan.equipment
                : readyExercise.equipment,
            locais: plan.location.isEmpty ? const [] : [plan.location],
            dificuldade: plan.level,
            objetivo: plan.goal,
            imagem: '',
            gifPath: '',
            video: '',
            tags: [
              plan.category,
              plan.goal,
              'source:$source',
              'series:${readyExercise.sets}',
              'repeticoes:${readyExercise.reps}',
              'descanso:${readyExercise.restSeconds}',
              if (readyExercise.rir.isNotEmpty) 'rir:${readyExercise.rir}',
              if (readyExercise.cadence.isNotEmpty)
                'cadencia:${readyExercise.cadence}',
            ].where((tag) => tag.trim().isNotEmpty).toList(),
            caloriasHora: 0,
            series: readyExercise.sets,
            repeticoes: readyExercise.reps,
            descansoSegundos: readyExercise.restSeconds,
            rir: readyExercise.rir,
            cadencia: readyExercise.cadence,
            observacoesTreino: readyExercise.notes,
          ),
        );
      }

      days.add(
        TreinoDiaModel(
          codigo: day.name.isEmpty ? 'Dia ${dayIndex + 1}' : day.name,
          nome: day.title.isEmpty ? day.muscleGroup : day.title,
          ordem: day.order > 0 ? day.order : dayIndex + 1,
          exercicioIds: ids,
        ),
      );
    }

    return TreinoModel(
      id: workoutId,
      nome: plan.name,
      descricao: plan.description,
      objetivo: plan.goal,
      nivel: plan.level,
      divisao: plan.split,
      tempoEstimado: plan.estimatedMinutes,
      diasPorSemana: plan.daysPerWeek,
      local: plan.location,
      equipamentos: plan.equipment,
      gruposPrioritarios: plan.tags,
      observacoes: 'Plano pronto adicionado pela Biblioteca FitIA.',
      planoDias: days,
      criadoPorIA: false,
      exercicios: exercises,
      dataCriacao: DateTime.now().toIso8601String(),
      origem: source,
      readyPlanId: plan.id,
    );
  }

  static String _description(dynamic exercise) {
    final details = <String>[
      if (exercise.sets > 0) 'Séries: ${exercise.sets}',
      if (exercise.reps.isNotEmpty) 'Repetições: ${exercise.reps}',
      if (exercise.restSeconds > 0) 'Descanso: ${exercise.restSeconds}s',
      if (exercise.rir.isNotEmpty) 'RIR: ${exercise.rir}',
      if (exercise.cadence.isNotEmpty) 'Cadência: ${exercise.cadence}',
      if (exercise.notes.isNotEmpty) exercise.notes,
    ];
    return details.join(' | ');
  }

  static List<String> _groups(String value) {
    return value
        .split(RegExp(r'\+|/|,'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
