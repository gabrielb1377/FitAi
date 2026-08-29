import '../core/exercises/exercise_catalog_binding.dart';
import '../data/exercicios/exercicios.dart';
import '../models/exercicio_model.dart';
import '../models/ready_plan_model.dart';
import '../models/treino_model.dart';

class ReadyPlanBindingException implements Exception {
  const ReadyPlanBindingException(this.message);

  final String message;

  @override
  String toString() => 'ReadyPlanBindingException: $message';
}

class ReadyPlanMapper {
  ReadyPlanMapper._();

  static TreinoModel toTreino(
    ReadyPlanModel plan, {
    required String workoutId,
    required String source,
    ExerciseCatalogBinder? catalogBinder,
  }) {
    final binder = catalogBinder ?? ExerciseCatalogBinder(bancoExercicios);
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
        final binding = binder.bindTemplate(
          templateItemId: readyExercise.id,
          remoteExerciseId: readyExercise.exerciseId,
          canonicalExerciseId: readyExercise.canonicalExerciseId,
          exerciseName: readyExercise.exerciseName,
        );
        if (!binding.isResolved || binding.entry == null) {
          throw ReadyPlanBindingException(
            'O exercício "${readyExercise.exerciseName}" ainda não possui um '
            'vínculo seguro com a Biblioteca FitIA.',
          );
        }

        // This is a stable plan occurrence, not an exercise catalog identity.
        final itemId = '${workoutId}_${day.id}_${readyExercise.id}';
        ids.add(itemId);
        exercises.add(
          binding.entry!.exercise.copyWith(
            id: itemId,
            canonicalExerciseId: binding.canonicalExerciseId,
            canonicalName: binding.canonicalName,
            templateItemId: binding.templateItemId,
            remoteExerciseId: binding.remoteExerciseId,
            series: readyExercise.sets,
            repeticoes: readyExercise.reps,
            descansoSegundos: readyExercise.restSeconds,
            rir: readyExercise.rir,
            cadencia: readyExercise.cadence,
            observacoesTreino: _description(readyExercise),
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
}
