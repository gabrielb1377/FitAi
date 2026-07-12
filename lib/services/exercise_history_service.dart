import 'package:flutter/foundation.dart';

import '../core/exercises/exercise_identity.dart';
import '../models/exercicio_model.dart';
import '../models/exercise_history_model.dart';
import '../models/historico_serie_treino_model.dart';
import 'storage_service.dart';

/// Leitura e consolidacao offline-first do historico por exercicio.
class ExerciseHistoryService {
  const ExerciseHistoryService();

  Future<ExerciseHistorySnapshot> loadExerciseHistory(
    ExercicioModel exercise,
  ) async {
    final series = await loadExerciseSeries(exercise);
    final executions = _groupExecutions(series);
    return ExerciseHistorySnapshot(
      executions: executions,
      stats: _stats(executions),
    );
  }

  Future<List<HistoricoSerieTreinoModel>> loadExerciseSeries(
    ExercicioModel exercise,
  ) async {
    await StorageService.migrateExerciseHistorySchema();
    final saved = await StorageService.carregarHistoricoSeriesTreino();
    final matched = saved
        .where(
          (entry) => ExerciseIdentity.matchesExercise(
            storedExerciseId: entry.exercicioId,
            storedExerciseKey: entry.exerciseKey,
            storedExerciseName: entry.nomeExercicio,
            exercise: exercise,
          ),
        )
        .toList();

    if (matched.isNotEmpty) {
      _log('Historico encontrado por id/chave para ${exercise.id}.');
      return deduplicateHistory(matched);
    }

    final legacy = (await StorageService.carregarProgressos())
        .where(
          (entry) =>
              ExerciseIdentity.normalizeName(entry.nomeExercicio) ==
              ExerciseIdentity.normalizeName(exercise.nome),
        )
        .toList();
    final legacySeries = legacy
        .map(
          (entry) => HistoricoSerieTreinoModel(
            id: 'legacy_${entry.id}',
            treinoId: '',
            sessaoTreinoId: 'legacy_${entry.id}',
            nomeTreino: entry.observacao.trim().isEmpty
                ? 'Treino anterior'
                : entry.observacao,
            exercicioId: '',
            exerciseKey: ExerciseIdentity.buildExerciseKey(
              exerciseName: entry.nomeExercicio,
            ),
            nomeExercicio: entry.nomeExercicio,
            serieNumero: entry.series <= 0 ? 1 : entry.series,
            peso: entry.peso,
            repeticoes: entry.repeticoes,
            descansoSegundos: entry.tempoDescanso ?? 0,
            comentario: entry.observacao,
            dataHora: entry.data,
          ),
        )
        .toList();

    if (legacySeries.isNotEmpty) {
      _log('Fallback legado por nome para ${exercise.nome}.');
    } else {
      _log(
        'Historico vazio para ${ExerciseIdentity.normalizeName(exercise.nome)}.',
      );
    }
    return legacySeries;
  }

  List<HistoricoSerieTreinoModel> deduplicateHistory(
    List<HistoricoSerieTreinoModel> history,
  ) {
    final seen = <String>{};
    final unique = <HistoricoSerieTreinoModel>[];
    for (final entry in history) {
      final key = entry.deduplicationKey;
      if (seen.add(key)) {
        unique.add(entry);
      } else {
        _log('Duplicacao evitada para ${entry.exerciseKey}.');
      }
    }
    unique.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return unique;
  }

  Future<void> saveExerciseExecution(HistoricoSerieTreinoModel series) async {
    await StorageService.salvarHistoricoSerieTreino(series);
    _log('Execucao salva para ${series.exerciseKey}.');
  }

  List<ExerciseExecution> _groupExecutions(
    List<HistoricoSerieTreinoModel> series,
  ) {
    final groups = <String, List<HistoricoSerieTreinoModel>>{};
    for (final entry in series) {
      final session = entry.sessaoTreinoId.trim().isNotEmpty
          ? entry.sessaoTreinoId.trim()
          : '${entry.treinoId}|${entry.dataHora.year}-${entry.dataHora.month}-${entry.dataHora.day}-${entry.dataHora.hour}-${entry.dataHora.minute}';
      groups.putIfAbsent(session, () => []).add(entry);
    }

    final executions = groups.entries.map((group) {
      final sets = [...group.value]
        ..sort((a, b) => a.serieNumero.compareTo(b.serieNumero));
      final latest = sets
          .map((set) => set.dataHora)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final first = sets.first;
      return ExerciseExecution(
        id: group.key,
        exerciseId: first.exercicioId,
        exerciseKey: first.exerciseKey,
        exerciseName: first.nomeExercicio,
        workoutId: first.treinoId,
        workoutName: first.nomeTreino,
        date: latest,
        sets: sets,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return executions;
  }

  ExerciseHistoryStats _stats(List<ExerciseExecution> executions) {
    final sets = executions.expand((execution) => execution.sets).toList();
    HistoricoSerieTreinoModel? bestLoad;
    for (final set in sets) {
      if (bestLoad == null ||
          set.peso > bestLoad.peso ||
          (set.peso == bestLoad.peso && set.repeticoes > bestLoad.repeticoes)) {
        bestLoad = set;
      }
    }

    ExerciseExecution? highestVolume;
    for (final execution in executions) {
      if (highestVolume == null || execution.volume > highestVolume.volume) {
        highestVolume = execution;
      }
    }

    final oneRepMax = executions.fold<double>(
      0,
      (current, execution) => execution.estimatedOneRepMax > current
          ? execution.estimatedOneRepMax
          : current,
    );
    return ExerciseHistoryStats(
      totalSessions: executions.length,
      latestExecution: executions.isEmpty ? null : executions.first,
      bestLoadSet: bestLoad,
      highestVolumeExecution: highestVolume,
      estimatedOneRepMax: oneRepMax,
    );
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ExerciseHistory] $message');
  }
}
