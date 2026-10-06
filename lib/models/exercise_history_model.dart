import 'historico_serie_treino_model.dart';
import '../features/plans/domain/workout_strength_metrics.dart';

class ExerciseExecution {
  final String id;
  final String exerciseId;
  final String exerciseKey;
  final String exerciseName;
  final String workoutId;
  final String workoutName;
  final DateTime date;
  final List<HistoricoSerieTreinoModel> sets;

  const ExerciseExecution({
    required this.id,
    required this.exerciseId,
    required this.exerciseKey,
    required this.exerciseName,
    required this.workoutId,
    required this.workoutName,
    required this.date,
    required this.sets,
  });

  double get volume => sets.fold(
    0,
    (total, set) =>
        total + WorkoutStrengthMetrics.setVolume(set.peso, set.repeticoes),
  );

  HistoricoSerieTreinoModel? get bestSet {
    if (sets.isEmpty) return null;
    final ordered = [...sets]
      ..sort((a, b) {
        final weight = b.peso.compareTo(a.peso);
        if (weight != 0) return weight;
        final reps = b.repeticoes.compareTo(a.repeticoes);
        if (reps != 0) return reps;
        return b.volume.compareTo(a.volume);
      });
    return ordered.first;
  }

  double get estimatedOneRepMax {
    return sets.fold<double>(0, (best, set) {
      if (set.peso <= 0 ||
          !set.peso.isFinite ||
          set.repeticoes < 1 ||
          set.repeticoes > 10) {
        return best;
      }
      final estimate = set.peso * (1 + set.repeticoes / 30);
      return estimate > best ? estimate : best;
    });
  }
}

class ExerciseHistoryStats {
  final int totalSessions;
  final ExerciseExecution? latestExecution;
  final HistoricoSerieTreinoModel? bestLoadSet;
  final ExerciseExecution? highestVolumeExecution;
  final double estimatedOneRepMax;

  const ExerciseHistoryStats({
    required this.totalSessions,
    required this.latestExecution,
    required this.bestLoadSet,
    required this.highestVolumeExecution,
    required this.estimatedOneRepMax,
  });
}

class ExerciseHistorySnapshot {
  final List<ExerciseExecution> executions;
  final ExerciseHistoryStats stats;

  const ExerciseHistorySnapshot({
    required this.executions,
    required this.stats,
  });

  const ExerciseHistorySnapshot.empty()
    : executions = const [],
      stats = const ExerciseHistoryStats(
        totalSessions: 0,
        latestExecution: null,
        bestLoadSet: null,
        highestVolumeExecution: null,
        estimatedOneRepMax: 0,
      );
}
