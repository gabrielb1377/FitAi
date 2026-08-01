import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../services/treino_service.dart';
import 'exercise_identity.dart';

/// A local command to insert a canonical exercise into an existing plan.
class ExercisePlanInsertion {
  const ExercisePlanInsertion({
    required this.plan,
    required this.exercise,
    this.dayIndex,
    this.position,
    required this.sets,
    required this.repetitions,
    required this.restSeconds,
  });

  final TreinoModel plan;
  final ExercicioModel exercise;
  final int? dayIndex;
  final int? position;
  final int sets;
  final String repetitions;
  final int restSeconds;
}

class ExercisePlanInsertionResult {
  const ExercisePlanInsertionResult({
    required this.plan,
    required this.insertedExercise,
    required this.position,
  });

  final TreinoModel plan;
  final ExercicioModel insertedExercise;
  final int position;
}

/// Persists a plan change through the current [TreinoService] only.
///
/// It intentionally does not call the backend. [TreinoService] retains its
/// existing local-first persistence and optional synchronization behavior.
class ExercisePlanIntegration {
  ExercisePlanIntegration({
    TreinoService? treinoService,
    this.loadPlans,
    this.savePlan,
  }) : _treinoService = treinoService ?? TreinoService.instance;

  final TreinoService _treinoService;
  final Future<List<TreinoModel>> Function()? loadPlans;
  final Future<void> Function(TreinoModel plan)? savePlan;

  Future<List<TreinoModel>> availablePlans() async {
    final loadPlans = this.loadPlans;
    if (loadPlans != null) return loadPlans();
    await _treinoService.initialize();
    return _treinoService.treinos
        .where((plan) => plan.isPlanoPrincipal)
        .toList(growable: false);
  }

  Future<ExercisePlanInsertionResult> addToPlan(
    ExercisePlanInsertion insertion,
  ) async {
    final plan = insertion.plan;
    final configuredExercise = insertion.exercise.copyWith(
      series: insertion.sets.clamp(1, 99),
      repeticoes: insertion.repetitions.trim().isEmpty
          ? insertion.exercise.repeticoes
          : insertion.repetitions.trim(),
      descansoSegundos: insertion.restSeconds.clamp(0, 3600),
    );
    final exercises = List<ExercicioModel>.from(plan.exercicios);
    final identity = _identityFor(configuredExercise);
    if (exercises.any((item) => _identityFor(item) == identity)) {
      throw StateError('Este exercicio ja esta no plano selecionado.');
    }
    final position = (insertion.position ?? exercises.length).clamp(
      0,
      exercises.length,
    );
    exercises.insert(position, configuredExercise);

    final days = List<TreinoDiaModel>.from(plan.planoDias);
    final dayIndex = insertion.dayIndex;
    if (dayIndex != null && dayIndex >= 0 && dayIndex < days.length) {
      final day = days[dayIndex];
      final ids = List<String>.from(day.exercicioIds);
      final dayPosition = position.clamp(0, ids.length);
      ids.insert(dayPosition, configuredExercise.id);
      days[dayIndex] = TreinoDiaModel(
        codigo: day.codigo,
        nome: day.nome,
        ordem: day.ordem,
        exercicioIds: ids,
      );
    }

    final updated = TreinoModel(
      id: plan.id,
      nome: plan.nome,
      descricao: plan.descricao,
      objetivo: plan.objetivo,
      nivel: plan.nivel,
      divisao: plan.divisao,
      tempoEstimado: plan.tempoEstimado,
      diasPorSemana: plan.diasPorSemana,
      local: plan.local,
      equipamentos: plan.equipamentos,
      gruposPrioritarios: plan.gruposPrioritarios,
      lesoesRestricoes: plan.lesoesRestricoes,
      exerciciosFavoritos: plan.exerciciosFavoritos,
      exerciciosEvitados: plan.exerciciosEvitados,
      observacoes: plan.observacoes,
      diaPlano: plan.diaPlano,
      grupoDia: plan.grupoDia,
      ordemDia: plan.ordemDia,
      planoDias: days,
      criadoPorIA: plan.criadoPorIA,
      exercicios: exercises,
      dataCriacao: plan.dataCriacao,
      origem: plan.origem,
      readyPlanId: plan.readyPlanId,
    );
    final savePlan = this.savePlan;
    if (savePlan != null) {
      await savePlan(updated);
    } else {
      await _treinoService.adicionarTreinoComPersistencia(updated);
    }
    return ExercisePlanInsertionResult(
      plan: updated,
      insertedExercise: configuredExercise,
      position: position,
    );
  }

  String _identityFor(ExercicioModel exercise) =>
      ExerciseIdentity.buildExerciseKey(
        exerciseId: exercise.id,
        exerciseName: exercise.nome,
      );
}
