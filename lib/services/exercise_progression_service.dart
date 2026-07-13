import 'package:flutter/foundation.dart';

import '../core/exercises/exercise_identity.dart';
import '../models/exercicio_model.dart';
import '../models/exercise_history_model.dart';
import '../models/exercise_progression_model.dart';
import 'exercise_history_service.dart';
import 'storage_service.dart';

/// Motor offline-first e deterministico para a proxima execucao de um exercicio.
/// Ele somente recomenda; o plano salvo nunca e modificado automaticamente.
class ExerciseProgressionService {
  final ExerciseHistoryService _historyService;

  const ExerciseProgressionService({
    this._historyService = const ExerciseHistoryService(),
  });

  Future<ExerciseProgressionModel> generate({
    required ExercicioModel exercise,
    required ExerciseProgressionConfig config,
  }) async {
    final history = await _historyService.loadExerciseHistory(exercise);
    final progression = calculate(
      exercise: exercise,
      config: config,
      executions: history.executions,
    );
    _log(
      '${progression.exerciseKey}: ${progression.action.name} '
      '(${progression.basedOnSessions} sessoes).',
    );
    return progression;
  }

  ExerciseProgressionModel calculate({
    required ExercicioModel exercise,
    required ExerciseProgressionConfig config,
    required List<ExerciseExecution> executions,
  }) {
    final recent = executions
        .map(
          (execution) => ExerciseExecution(
            id: execution.id,
            exerciseId: execution.exerciseId,
            exerciseKey: execution.exerciseKey,
            exerciseName: execution.exerciseName,
            workoutId: execution.workoutId,
            workoutName: execution.workoutName,
            date: execution.date,
            sets: execution.sets.where((set) => set.concluida).toList(),
          ),
        )
        .where((execution) => execution.sets.isNotEmpty)
        .take(6)
        .toList(growable: false);
    final range = _normalizeRange(config.repRange, config.goal);
    final targetSets = config.sets.clamp(2, 4).toInt();
    final targetRest = config.restSeconds.clamp(30, 180).toInt();
    final exerciseKey = ExerciseIdentity.buildExerciseKey(
      exerciseId: exercise.id,
      exerciseName: exercise.nome,
    );
    final latest = recent.isEmpty ? null : recent.first;
    final currentWeight = latest?.bestSet?.peso ?? 0;
    final confidence = switch (recent.length) {
      >= 4 => ExerciseProgressionConfidence.high,
      >= 2 => ExerciseProgressionConfidence.medium,
      _ => ExerciseProgressionConfidence.low,
    };

    ExerciseProgressionModel build({
      required ExerciseProgressionAction action,
      required String reason,
      double? suggestedWeight,
      int? suggestedSets,
      String? suggestedRepRange,
      int? suggestedRestSeconds,
    }) {
      return ExerciseProgressionModel(
        exerciseId: exercise.id,
        exerciseKey: exerciseKey,
        exerciseName: exercise.nome,
        currentWeight: currentWeight,
        currentSets: targetSets,
        currentRepRange: range.text,
        currentRestSeconds: targetRest,
        suggestedWeight: suggestedWeight ?? currentWeight,
        suggestedSets: suggestedSets ?? targetSets,
        suggestedRepRange: suggestedRepRange ?? range.text,
        suggestedRestSeconds: suggestedRestSeconds ?? targetRest,
        action: action,
        reason: reason,
        confidence: confidence,
        basedOnSessions: recent.length,
        generatedAt: DateTime.now(),
      );
    }

    if (recent.isEmpty) {
      return build(
        action: ExerciseProgressionAction.insufficientData,
        reason: 'Registre de 3 a 6 sessoes para receber uma sugestao segura.',
      );
    }

    final latestBelowRange = _belowMinimum(latest!, range.min);
    final previousBelowRange =
        recent.length > 1 && _belowMinimum(recent[1], range.min);
    final lastThreeBelow =
        recent.take(3).length == 3 &&
        recent.take(3).where((item) => _belowMinimum(item, range.min)).length >=
            3;

    if (lastThreeBelow) {
      return build(
        action: ExerciseProgressionAction.deload,
        suggestedWeight: _roundWeight(currentWeight * .90),
        suggestedSets: (targetSets - 1).clamp(2, 4).toInt(),
        suggestedRestSeconds: _safeRest(
          exercise,
          targetRest,
          performanceLow: true,
        ),
        reason:
            'As tres ultimas sessoes ficaram abaixo da faixa alvo. Reduza o esforco e priorize tecnica.',
      );
    }

    if (latestBelowRange && previousBelowRange) {
      return build(
        action: ExerciseProgressionAction.reduceWeight,
        suggestedWeight: _roundWeight(currentWeight * .95),
        suggestedRestSeconds: _safeRest(
          exercise,
          targetRest,
          performanceLow: true,
        ),
        reason:
            'As duas ultimas sessoes ficaram abaixo da faixa alvo. Uma reducao leve pode recuperar consistencia.',
      );
    }

    final reachedTopTwice =
        recent.length >= 2 &&
        _reachedMaximum(latest, range.max) &&
        _reachedMaximum(recent[1], range.max) &&
        currentWeight > 0;
    if (reachedTopTwice) {
      final increment = _loadIncrement(exercise, currentWeight);
      return build(
        action: ExerciseProgressionAction.increaseWeight,
        suggestedWeight: _roundWeight(currentWeight + increment),
        suggestedRepRange: '${range.min}-${range.max - 1}',
        suggestedRestSeconds: _safeRest(exercise, targetRest),
        reason:
            'Voce atingiu o topo da faixa em duas sessoes. Aumente apenas a carga na proxima execucao.',
      );
    }

    if (_withinRange(latest, range)) {
      final nextMax = (latest.bestSet?.repeticoes ?? range.min) + 1;
      return build(
        action: ExerciseProgressionAction.increaseReps,
        suggestedRepRange:
            '${range.min}-${nextMax.clamp(range.min, range.max)}',
        reason:
            'A ultima execucao ficou consistente na faixa alvo. Busque uma repeticao a mais antes de subir a carga.',
      );
    }

    return build(
      action: ExerciseProgressionAction.maintain,
      reason:
          'Mantenha a configuracao atual e registre mais sessoes para uma recomendacao mais confiavel.',
    );
  }

  Future<void> accept(
    ExerciseProgressionModel progression, {
    bool forNextOccurrence = true,
  }) async {
    await StorageService.salvarDecisaoProgressaoExercicio({
      ...progression.toJson(),
      'scope': forNextOccurrence ? 'next_occurrence' : 'current_session',
      if (!forNextOccurrence) 'consumedAt': DateTime.now().toIso8601String(),
    });
    _log(
      '${progression.exerciseKey}: sugestao aceita para '
      '${forNextOccurrence ? 'a proxima ocorrencia' : 'a sessao atual'}.',
    );
  }

  Future<ExerciseProgressionModel?> loadAccepted(
    ExercicioModel exercise,
  ) async {
    final key = ExerciseIdentity.buildExerciseKey(
      exerciseId: exercise.id,
      exerciseName: exercise.nome,
    );
    final saved = await StorageService.carregarDecisaoProgressaoExercicio(key);
    if (saved == null || saved['scope']?.toString() != 'next_occurrence') {
      return null;
    }
    return ExerciseProgressionModel.fromJson(saved);
  }

  _RepRange _normalizeRange(String input, String goal) {
    final match = RegExp(r'(\d+)\s*[-–]\s*(\d+)').firstMatch(input);
    if (match != null) {
      final min = int.tryParse(match.group(1)!) ?? 6;
      final max = int.tryParse(match.group(2)!) ?? 12;
      if (min > 0 && max >= min) return _RepRange(min, max);
    }
    final normalizedGoal = goal.toLowerCase();
    if (normalizedGoal.contains('forca')) return const _RepRange(4, 6);
    if (normalizedGoal.contains('resist')) return const _RepRange(10, 15);
    return const _RepRange(6, 12);
  }

  bool _belowMinimum(ExerciseExecution execution, int minimum) {
    if (execution.sets.isEmpty) return true;
    final valid = execution.sets.where((set) => set.repeticoes > 0).toList();
    return valid.isEmpty ||
        valid.where((set) => set.repeticoes < minimum).length * 2 >=
            valid.length;
  }

  bool _reachedMaximum(ExerciseExecution execution, int maximum) =>
      execution.sets.isNotEmpty &&
      execution.sets.every((set) => set.repeticoes >= maximum);

  bool _withinRange(ExerciseExecution execution, _RepRange range) =>
      execution.sets.isNotEmpty &&
      execution.sets.every(
        (set) => set.repeticoes >= range.min && set.repeticoes <= range.max,
      );

  double _loadIncrement(ExercicioModel exercise, double currentWeight) {
    final equipment = exercise.equipamentos.join(' ').toLowerCase();
    final isMachine =
        equipment.contains('maquina') || equipment.contains('machine');
    final base = isMachine ? 5.0 : 2.0;
    return (currentWeight * .025).clamp(base, currentWeight * .10).toDouble();
  }

  double _roundWeight(double value) {
    if (value <= 0) return 0;
    return (value * 2).roundToDouble() / 2;
  }

  int _safeRest(
    ExercicioModel exercise,
    int configured, {
    bool performanceLow = false,
  }) {
    if (performanceLow) return configured.clamp(60, 180).toInt();
    final name = exercise.nome.toLowerCase();
    final compound = RegExp(
      r'supino|agach|remada|levantamento|barra',
    ).hasMatch(name);
    return (compound ? configured.clamp(90, 180) : configured.clamp(30, 120))
        .toInt();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ExerciseProgression] $message');
  }
}

class _RepRange {
  final int min;
  final int max;
  const _RepRange(this.min, this.max);
  String get text => '$min-$max';
}
