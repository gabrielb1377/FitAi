import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/dev_config.dart';
import '../core/exercises/exercise_identity.dart';
import '../features/auth/data/auth_service.dart';
import '../features/plans/data/workout_history_repository.dart';
import '../features/plans/domain/workout_history_models.dart';
import '../features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import '../models/exercicio_model.dart';
import '../models/exercise_history_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/progresso_exercicio_model.dart';
import 'storage_service.dart';

typedef ExercisePlanHistoryLoader =
    Future<PlanWorkoutHistorySnapshot> Function();

/// Leitura e consolidacao offline-first do historico por exercicio.
class ExerciseHistoryService {
  const ExerciseHistoryService({this.historyLoader});

  final ExercisePlanHistoryLoader? historyLoader;

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
    final canonical = await _loadCanonicalExerciseSeries(exercise);
    if (canonical.isNotEmpty) {
      _log('Historico canonico encontrado para ${exercise.id}.');
      return deduplicateHistory(canonical);
    }

    await StorageService.migrateExerciseHistorySchema();
    final saved = await StorageService.carregarHistoricoSeriesTreino();
    final matched = _matchingLegacySeries(saved, exercise);

    if (matched.isNotEmpty) {
      _log('Historico legado compativel encontrado para ${exercise.id}.');
      return deduplicateHistory(matched);
    }

    final legacyProgress = exercise.canonicalExerciseId.trim().isEmpty
        ? await StorageService.carregarProgressos()
        : const <ProgressoExercicioModel>[];
    final legacy = legacyProgress
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
    // Escrita reservada para a superficie tecnica legada. A jornada oficial
    // persiste sets no journal antes de atualizar a interface.
    await StorageService.salvarHistoricoSerieTreino(series);
    _log('Execucao salva para ${series.exerciseKey}.');
  }

  Future<List<HistoricoSerieTreinoModel>> _loadCanonicalExerciseSeries(
    ExercicioModel exercise,
  ) async {
    final history = await (historyLoader ?? _loadLocalPlanHistory)();
    final canonicalId = ExerciseIdentity.canonicalIdFor(exercise);
    final requiresCanonicalMatch = exercise.canonicalExerciseId
        .trim()
        .isNotEmpty;
    final hasCanonicalIdentity = history.workouts.any(
      (workout) => workout.exercises.any(
        (executed) => executed.exerciseId == canonicalId,
      ),
    );
    final series = <HistoricoSerieTreinoModel>[];
    for (final workout in history.workouts) {
      for (final executed in workout.exercises) {
        final exactCanonicalMatch = executed.exerciseId == canonicalId;
        if (requiresCanonicalMatch || hasCanonicalIdentity
            ? !exactCanonicalMatch
            : !ExerciseIdentity.matchesExercise(
                storedExerciseId: executed.exerciseId,
                storedExerciseKey: ExerciseIdentity.buildExerciseKey(
                  exerciseId: executed.exerciseId,
                  exerciseName: executed.name,
                ),
                storedExerciseName: executed.name,
                exercise: exercise,
              )) {
          continue;
        }
        for (final set in executed.sets) {
          series.add(
            HistoricoSerieTreinoModel(
              id: set.id,
              treinoId: workout.workoutId,
              sessaoTreinoId: workout.id,
              nomeTreino: workout.workoutName ?? workout.planName ?? 'Treino',
              exercicioId: executed.exerciseId,
              exerciseKey: ExerciseIdentity.buildExerciseKey(
                exerciseId: executed.exerciseId,
                exerciseName: executed.name,
              ),
              nomeExercicio: executed.name,
              serieNumero: set.index + 1,
              peso: set.weight,
              repeticoes: set.repetitions,
              descansoSegundos: set.restSeconds ?? 0,
              comentario: set.notes ?? '',
              dataHora: set.completedAt,
            ),
          );
        }
      }
    }
    return series;
  }

  Future<PlanWorkoutHistorySnapshot> _loadLocalPlanHistory() async {
    final session = await AuthService().restoreSession();
    final userId =
        session?.userId ??
        (DevConfig.enabled && DevConfig.bypassLogin ? 'debug-gabriel' : null);
    if (userId == null || userId.trim().isEmpty) {
      return const PlanWorkoutHistorySnapshot.empty();
    }
    final preferences = await SharedPreferences.getInstance();
    return WorkoutHistoryRepository(
      localStore: SharedPreferencesWorkoutVerticalLocalStore(
        preferences,
        userScope: userId,
      ),
      legacyHistoryLoader: StorageService.carregarHistoricoTreinos,
      legacyExerciseHistoryLoader: StorageService.carregarHistoricoSeriesTreino,
    ).load();
  }

  List<HistoricoSerieTreinoModel> _matchingLegacySeries(
    List<HistoricoSerieTreinoModel> saved,
    ExercicioModel exercise,
  ) => saved
      .where((entry) {
        if (exercise.canonicalExerciseId.trim().isNotEmpty) {
          return entry.exercicioId.trim() ==
              exercise.canonicalExerciseId.trim();
        }
        return ExerciseIdentity.matchesExercise(
          storedExerciseId: entry.exercicioId,
          storedExerciseKey: entry.exerciseKey,
          storedExerciseName: entry.nomeExercicio,
          exercise: exercise,
        );
      })
      .toList(growable: false);

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
