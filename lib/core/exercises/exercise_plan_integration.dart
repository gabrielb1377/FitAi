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
    _requiredExerciseId(insertion.exercise.id);
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
    await _persistPlan(updated);
    return ExercisePlanInsertionResult(
      plan: updated,
      insertedExercise: configuredExercise,
      position: position,
    );
  }

  /// Replaces one future prescription while preserving the plan identity and
  /// its local-first persistence path. A plan created by R2.4 has one unique
  /// catalog ID per exercise, which keeps this command unambiguous.
  Future<TreinoModel> replaceInPlan({
    required TreinoModel plan,
    required String previousExerciseId,
    required ExercicioModel replacement,
  }) async {
    final previousId = _requiredExerciseId(previousExerciseId);
    final replacementId = _requiredExerciseId(replacement.id);
    if (previousId == replacementId) return plan;
    final index = plan.exercicios.indexWhere((item) => item.id == previousId);
    if (index < 0) throw StateError('Exercicio original nao existe no plano.');
    if (plan.exercicios.any((item) => item.id == replacementId)) {
      throw StateError('O exercicio substituto ja existe no plano.');
    }
    final exercises = List<ExercicioModel>.from(plan.exercicios)
      ..[index] = replacement;
    final updated = _withExercises(
      plan,
      exercises: exercises,
      days: _mapDayIds(
        plan,
        (ids) => [
          for (final id in ids)
            if (id == previousId) replacementId else id,
        ],
      ),
    );
    await _persistPlan(updated);
    return updated;
  }

  /// Removes only an exercise that has a valid remaining plan structure.
  /// Session sets are not owned by plan definitions and are never touched.
  Future<TreinoModel> removeFromPlan({
    required TreinoModel plan,
    required String exerciseId,
  }) async {
    final id = _requiredExerciseId(exerciseId);
    if (plan.exercicios.length <= 1) {
      throw StateError('O plano precisa manter pelo menos um exercicio.');
    }
    if (!plan.exercicios.any((item) => item.id == id)) {
      throw StateError('Exercicio nao existe no plano.');
    }
    for (final day in plan.planoDias) {
      if (day.exercicioIds.contains(id) && day.exercicioIds.length <= 1) {
        throw StateError('O treino precisa manter pelo menos um exercicio.');
      }
    }
    final updated = _withExercises(
      plan,
      exercises: plan.exercicios.where((item) => item.id != id).toList(),
      days: _mapDayIds(plan, (ids) => ids.where((item) => item != id).toList()),
    );
    await _persistPlan(updated);
    return updated;
  }

  /// Persists a deterministic order. Day projections follow the same order,
  /// so `TreinoModel.somenteDia` restores it after a restart.
  Future<TreinoModel> reorderPlanExercises({
    required TreinoModel plan,
    required List<String> orderedExerciseIds,
  }) async {
    final currentIds = plan.exercicios
        .map((exercise) => _requiredExerciseId(exercise.id))
        .toList(growable: false);
    final requested = orderedExerciseIds
        .map(_requiredExerciseId)
        .toList(growable: false);
    if (requested.length != currentIds.length ||
        requested.toSet().length != requested.length ||
        !requested.toSet().containsAll(currentIds)) {
      throw StateError('A nova ordem nao representa os exercicios do plano.');
    }
    if (_sameSequence(currentIds, requested)) return plan;
    final byId = {
      for (final exercise in plan.exercicios) exercise.id: exercise,
    };
    final updated = _withExercises(
      plan,
      exercises: [for (final id in requested) byId[id]!],
      days: _mapDayIds(plan, (ids) {
        final dayIds = ids.toSet();
        return [
          for (final id in requested)
            if (dayIds.contains(id)) id,
          for (final id in ids)
            if (!requested.contains(id)) id,
        ];
      }),
    );
    await _persistPlan(updated);
    return updated;
  }

  Future<void> _persistPlan(TreinoModel plan) async {
    final savePlan = this.savePlan;
    if (savePlan != null) {
      await savePlan(plan);
    } else {
      await _treinoService.adicionarTreinoComPersistencia(plan);
    }
  }

  TreinoModel _withExercises(
    TreinoModel plan, {
    required List<ExercicioModel> exercises,
    required List<TreinoDiaModel> days,
  }) => TreinoModel.fromJson({
    ...plan.toJson(),
    'exercicios': exercises.map((exercise) => exercise.toJson()).toList(),
    'planoDias': days.map((day) => day.toJson()).toList(),
  });

  List<TreinoDiaModel> _mapDayIds(
    TreinoModel plan,
    List<String> Function(List<String> ids) transform,
  ) => [
    for (final day in plan.planoDias)
      TreinoDiaModel(
        codigo: day.codigo,
        nome: day.nome,
        ordem: day.ordem,
        exercicioIds: transform(List<String>.from(day.exercicioIds)),
      ),
  ];

  String _requiredExerciseId(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('O exercicio precisa de um ID canonico.');
    }
    return normalized;
  }

  bool _sameSequence(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  String _identityFor(ExercicioModel exercise) =>
      ExerciseIdentity.buildExerciseKey(
        exerciseId: exercise.id,
        exerciseName: exercise.nome,
      );
}
