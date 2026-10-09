import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/local_account_data_boundary.dart';
import '../../../core/config/dev_config.dart';
import '../../../models/historico_treino_model.dart';
import '../../../services/storage_service.dart';
import '../../plans/data/workout_history_repository.dart';
import '../../progression/data/progression_local_store.dart';
import '../../progression/domain/progression_models.dart';
import '../../workout_vertical_slice/data/workout_vertical_local_store.dart';

/// Read-only adapter from the existing Plans journal to Home's history view.
/// It never records XP, uploads data or creates another persisted history.
class HomeWorkoutHistoryReader {
  HomeWorkoutHistoryReader({
    LegacyWorkoutHistoryLoader? legacyLoader,
    ProgressionLocalStore? progressionStore,
  }) : _legacyLoader = legacyLoader ?? StorageService.carregarHistoricoTreinos,
       _progressionStore =
           progressionStore ?? SharedPreferencesProgressionStore();

  final LegacyWorkoutHistoryLoader _legacyLoader;
  final ProgressionLocalStore _progressionStore;

  Future<List<HistoricoTreinoModel>> load() async {
    final revision = AccountSessionLifecycle.revision.value;
    final owner =
        AccountSessionLifecycle.activeUserId ??
        (DevConfig.enabled && DevConfig.bypassLogin ? 'debug-gabriel' : null);
    final legacy = await _legacyLoader();
    if (AccountSessionLifecycle.revision.value != revision) return const [];
    if (owner == null) return legacy;

    final preferences = await SharedPreferences.getInstance();
    final history = await WorkoutHistoryRepository(
      localStore: SharedPreferencesWorkoutVerticalLocalStore(
        preferences,
        userScope: owner,
      ),
      legacyHistoryLoader: () async => legacy,
    ).load();
    final progression = await _progressionStore.load(owner);
    if (AccountSessionLifecycle.revision.value != revision) return const [];

    final xpBySession = <String, int>{};
    final eventKeys = <String>{};
    for (final event in progression?.events ?? const <XpEvent>[]) {
      if (event.userId == owner &&
          event.sourceType == XpSourceType.workout &&
          eventKeys.add(event.idempotencyKey)) {
        xpBySession.update(
          event.sourceId,
          (xp) => xp + event.amount,
          ifAbsent: () => event.amount,
        );
      }
    }
    return [
      for (final workout in history.workouts)
        if (workout.planId == 'legacy-history')
          legacy.firstWhere(
            (item) =>
                item.id.trim() == workout.id ||
                (item.id.trim().isEmpty &&
                    item.dataHora == workout.finishedAt &&
                    item.nomeTreino == workout.workoutName),
          )
        else
          HistoricoTreinoModel(
            id: workout.id,
            nomeTreino: workout.workoutName ?? workout.planName ?? 'Treino',
            dataHora: workout.finishedAt,
            tempoSegundos: workout.metrics.durationSeconds,
            tempoFormatado:
                '${(workout.metrics.durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(workout.metrics.durationSeconds % 60).toString().padLeft(2, '0')}',
            exerciciosTotais: workout.metrics.exerciseCount,
            exerciciosConcluidos: workout.metrics.exerciseCount,
            xpGanho: xpBySession[workout.id] ?? 0,
            caloriasEstimadas: workout.calories?.round() ?? 0,
            objetivo: '',
            nivel: '',
            seriesConcluidas: workout.metrics.setCount,
            volumeTotal: workout.metrics.totalVolume,
            recordesBatidos: history.summaries
                .firstWhere((item) => item.sessionId == workout.id)
                .personalRecordCount,
          ),
    ];
  }
}
