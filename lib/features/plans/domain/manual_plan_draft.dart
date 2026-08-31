import '../../../models/exercicio_model.dart';
import '../../../models/treino_model.dart';

/// Estado volátil do fluxo manual. Ele só se torna um [TreinoModel] depois de
/// passar pela validação e pelo editor oficial de metadados.
class ManualPlanDraft {
  ManualPlanDraft({
    required this.id,
    required this.goal,
    this.structure = 'Full Body',
    this.estimatedMinutes = 45,
    List<ManualPlanDraftDay>? days,
  }) : days = days ?? [ManualPlanDraftDay.initial()];

  final String id;
  String goal;
  String structure;
  int estimatedMinutes;
  final List<ManualPlanDraftDay> days;

  List<ExercicioModel> get exercises =>
      List.unmodifiable(days.expand((day) => day.exercises));

  int get exerciseCount => exercises.length;

  ManualPlanDraftDay addDay() {
    final day = ManualPlanDraftDay(
      id: 'draft-day-${days.length + 1}',
      title: 'Treino ${days.length + 1}',
    );
    days.add(day);
    return day;
  }

  bool removeDay(String dayId) {
    if (days.length <= 1) return false;
    final originalLength = days.length;
    days.removeWhere((day) => day.id == dayId);
    return days.length != originalLength;
  }

  ManualPlanDraftDay? dayById(String dayId) {
    for (final day in days) {
      if (day.id == dayId) return day;
    }
    return null;
  }

  ManualPlanDraftSelectionResult addExercise({
    required String dayId,
    required ExercicioModel exercise,
  }) {
    final day = dayById(dayId);
    if (day == null) return ManualPlanDraftSelectionResult.dayNotFound;
    if (exercise.id.trim().isEmpty) {
      return ManualPlanDraftSelectionResult.missingCatalogId;
    }
    if (days.any(
      (candidate) => candidate.exercises.any(
        (selected) => selected.id.trim() == exercise.id.trim(),
      ),
    )) {
      return ManualPlanDraftSelectionResult.duplicate;
    }

    day.exercises.add(
      exercise.copyWith(
        canonicalExerciseId: exercise.canonicalExerciseId.trim().isEmpty
            ? exercise.id.trim()
            : exercise.canonicalExerciseId.trim(),
        canonicalName: exercise.canonicalName.trim().isEmpty
            ? exercise.nome.trim()
            : exercise.canonicalName.trim(),
      ),
    );
    return ManualPlanDraftSelectionResult.added;
  }

  bool removeExercise({required String dayId, required String exerciseId}) {
    final day = dayById(dayId);
    if (day == null) return false;
    final originalLength = day.exercises.length;
    day.exercises.removeWhere((exercise) => exercise.id == exerciseId);
    return day.exercises.length != originalLength;
  }

  bool updatePrescription({
    required String dayId,
    required String exerciseId,
    required int sets,
    required String reps,
    required int restSeconds,
  }) {
    final day = dayById(dayId);
    if (day == null) return false;
    final index = day.exercises.indexWhere(
      (exercise) => exercise.id == exerciseId,
    );
    if (index < 0) return false;
    day.exercises[index] = day.exercises[index].copyWith(
      series: sets,
      repeticoes: reps.trim(),
      descansoSegundos: restSeconds,
    );
    return true;
  }

  String? validate() {
    if (days.isEmpty) return 'Adicione pelo menos um treino ao plano.';
    if (estimatedMinutes <= 0) {
      return 'Informe uma duração válida para o treino.';
    }

    for (final day in days) {
      if (day.title.trim().isEmpty) return 'Todo treino precisa de um nome.';
      if (day.exercises.isEmpty) {
        return 'Adicione pelo menos um exercício em ${day.title}.';
      }
      for (final exercise in day.exercises) {
        if (exercise.id.trim().isEmpty) {
          return 'Um exercício selecionado não possui ID do catálogo.';
        }
        if (exercise.series <= 0 ||
            exercise.repeticoes.trim().isEmpty ||
            exercise.descansoSegundos <= 0) {
          return 'Configure séries, repetições e descanso para ${exercise.nome}.';
        }
      }
    }
    return null;
  }

  TreinoModel toEditorPlan() => _buildPlan(name: '', level: '');

  TreinoModel toPlan({required String name, required String level}) {
    if (name.trim().isEmpty) throw StateError('Informe o nome do plano.');
    if (level.trim().isEmpty) throw StateError('Informe o nível do plano.');
    return _buildPlan(name: name, level: level);
  }

  TreinoModel _buildPlan({required String name, required String level}) {
    final validationError = validate();
    if (validationError != null) throw StateError(validationError);

    return TreinoModel(
      id: id,
      nome: name.trim(),
      descricao: '',
      objetivo: goal,
      nivel: level,
      divisao: structure,
      tempoEstimado: estimatedMinutes,
      diasPorSemana: days.length,
      planoDias: List.unmodifiable([
        for (var index = 0; index < days.length; index++)
          TreinoDiaModel(
            codigo: 'Dia ${index + 1}',
            nome: days[index].title.trim(),
            ordem: index + 1,
            exercicioIds: List.unmodifiable(
              days[index].exercises.map((exercise) => exercise.id),
            ),
          ),
      ]),
      criadoPorIA: false,
      exercicios: exercises,
      dataCriacao: DateTime.now().toIso8601String(),
      origem: 'manual',
    );
  }
}

class ManualPlanDraftDay {
  ManualPlanDraftDay({
    required this.id,
    required this.title,
    List<ExercicioModel>? exercises,
  }) : exercises = exercises ?? [];

  factory ManualPlanDraftDay.initial() =>
      ManualPlanDraftDay(id: 'draft-day-1', title: 'Treino 1');

  final String id;
  String title;
  final List<ExercicioModel> exercises;
}

enum ManualPlanDraftSelectionResult {
  added,
  duplicate,
  missingCatalogId,
  dayNotFound,
}
