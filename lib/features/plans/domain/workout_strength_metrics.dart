import '../../workout_vertical_slice/domain/workout_vertical_models.dart';

/// Regras compartilhadas para métricas derivadas da musculação.
abstract final class WorkoutStrengthMetrics {
  /// Volume mecânico registrado, em kg·repetições, para uma série válida.
  static double setVolume(double weight, int reps) {
    if (!weight.isFinite || weight < 0 || reps <= 0) return 0;
    return weight * reps;
  }

  /// Soma séries persistidas no journal; duplicação lógica é responsabilidade
  /// do repositório que projeta o snapshot.
  static double journalVolume(Iterable<WorkoutSetLocal> sets) =>
      sets.fold(0, (total, set) => total + setVolume(set.weight, set.reps));
}
