/// Base extensivel para atividades de movimento que nao pertencem a Planos.
///
/// Carga, series, repeticoes, volume e PRs de musculacao pertencem ao dominio
/// de Planos e nao devem ser adicionados a este contrato.
enum ActivityType { running, steps, walking, cycling }

enum ActivitySyncStatus { local, syncing, queued, synced, failed, conflict }

abstract interface class ActivityDetails {
  const ActivityDetails();
}

class ActivityRecord<T extends ActivityDetails> {
  const ActivityRecord({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.syncStatus,
    required this.details,
  });

  final String id;
  final ActivityType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final ActivitySyncStatus syncStatus;
  final T details;

  Duration get duration => endedAt.isBefore(startedAt)
      ? Duration.zero
      : endedAt.difference(startedAt);
}

class RunningActivityDetails implements ActivityDetails {
  const RunningActivityDetails({
    required this.distanceKm,
    this.paceMinutesPerKm,
    this.averageSpeedKmh,
    this.calories,
    this.steps,
    this.routePointCount,
  });

  final double distanceKm;
  final double? paceMinutesPerKm;
  final double? averageSpeedKmh;
  final double? calories;
  final int? steps;
  final int? routePointCount;
}

class StepsActivityDetails implements ActivityDetails {
  const StepsActivityDetails({
    required this.steps,
    this.goal = 0,
    this.source = 'local',
    this.estimatedDistanceMeters,
    this.estimatedCalories,
  });

  final int steps;
  final int goal;
  final String source;
  final double? estimatedDistanceMeters;
  final double? estimatedCalories;

  bool get goalReached => goal > 0 && steps >= goal;
}

/// Agregado generico para um dia de calendario, sem metricas de musculacao.
class ActivityCalendarDay {
  const ActivityCalendarDay({
    required this.date,
    required this.recordCount,
    required this.syncStatus,
  });

  final DateTime date;
  final int recordCount;
  final ActivitySyncStatus syncStatus;
}
