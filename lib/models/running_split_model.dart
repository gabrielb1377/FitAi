import 'corrida_model.dart';
import 'running_session_model.dart';

/// Kilometer splits projected from accepted distance and active time.
class RunningSplitModel {
  const RunningSplitModel({
    required this.kilometer,
    required this.elapsedSeconds,
    this.distanceKm = 1,
    this.isPartial = false,
  });

  final int kilometer;
  final int elapsedSeconds;
  final double distanceKm;
  final bool isPartial;

  double get paceMinutesPerKm =>
      distanceKm > 0 ? elapsedSeconds / 60 / distanceKm : 0;

  /// Legacy points lack pause/accepted-distance metadata: fail closed.
  static List<RunningSplitModel> fromRoute(List<RunningRoutePointModel> route) {
    if (route.isEmpty) return const [];
    return _derive(
      route,
      route.last.cumulativeDistanceKm,
      route.last.activeElapsedSeconds,
    );
  }

  static List<RunningSplitModel> fromRun(CorridaModel run) {
    if (!run.finished || run.isDeleted) return const [];
    return _derive(run.route, run.distancia, run.segundos);
  }

  static List<RunningSplitModel> _derive(
    List<RunningRoutePointModel> route,
    double? finalDistance,
    int? finalSeconds,
  ) {
    if (route.length < 2 ||
        finalDistance == null ||
        !finalDistance.isFinite ||
        finalDistance <= 0 ||
        finalSeconds == null ||
        finalSeconds <= 0) {
      return const [];
    }
    var previousDistance = 0.0;
    var previousSeconds = 0;
    DateTime? previousTimestamp;
    for (final point in route) {
      final distance = point.cumulativeDistanceKm;
      final seconds = point.activeElapsedSeconds;
      final timestamp = DateTime.tryParse(point.timestamp);
      if (distance == null ||
          !distance.isFinite ||
          distance < previousDistance ||
          distance > finalDistance + 1e-9 ||
          seconds == null ||
          seconds < previousSeconds ||
          seconds > finalSeconds ||
          timestamp == null ||
          (previousTimestamp != null &&
              !timestamp.isAfter(previousTimestamp)) ||
          (distance - previousDistance >
              (seconds - previousSeconds + 1) / 100) ||
          (point.startsSegment == true && distance != previousDistance)) {
        return const [];
      }
      previousDistance = distance;
      previousSeconds = seconds;
      previousTimestamp = timestamp;
    }
    // No missing distance may be extrapolated before/after tracking.
    if (route.first.cumulativeDistanceKm != 0 ||
        (previousDistance - finalDistance).abs() > 1e-9) {
      return const [];
    }

    final result = <RunningSplitModel>[];
    var boundary = 1;
    var lastBoundarySeconds = 0;
    previousDistance = 0;
    previousSeconds = 0;
    for (final point in route) {
      final distance = point.cumulativeDistanceKm!;
      final seconds = point.activeElapsedSeconds!;
      while (distance + 1e-9 >= boundary && distance > previousDistance) {
        final ratio =
            ((boundary - previousDistance) / (distance - previousDistance))
                .clamp(0.0, 1.0);
        final crossing = (previousSeconds + (seconds - previousSeconds) * ratio)
            .round();
        result.add(
          RunningSplitModel(
            kilometer: boundary++,
            elapsedSeconds: crossing - lastBoundarySeconds,
          ),
        );
        lastBoundarySeconds = crossing;
      }
      previousDistance = distance;
      previousSeconds = seconds;
    }
    final remainder = finalDistance - (boundary - 1);
    if (remainder > 1e-9) {
      result.add(
        RunningSplitModel(
          kilometer: boundary,
          elapsedSeconds: finalSeconds - lastBoundarySeconds,
          distanceKm: remainder,
          isPartial: true,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}
