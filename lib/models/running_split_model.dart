import 'dart:math' as math;

import 'running_session_model.dart';

/// Parcial derivada localmente de uma rota GPS. Nao depende de mapa nem rede.
class RunningSplitModel {
  const RunningSplitModel({
    required this.kilometer,
    required this.elapsedSeconds,
  });

  final int kilometer;
  final int elapsedSeconds;

  double get paceMinutesPerKm => elapsedSeconds / 60;

  static List<RunningSplitModel> fromRoute(List<RunningRoutePointModel> route) {
    if (route.length < 2) return const [];

    final points = [...route]
      ..sort((a, b) => _timestamp(a).compareTo(_timestamp(b)));
    final splits = <RunningSplitModel>[];
    var accumulatedMeters = 0.0;
    var accumulatedSeconds = 0.0;
    var kilometer = 1;

    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      var remainingMeters = _metersBetween(previous, current);
      var remainingSeconds = _timestamp(
        current,
      ).difference(_timestamp(previous)).inSeconds.clamp(0, 3600).toDouble();

      while (remainingMeters > 0) {
        final metersToSplit = 1000 - accumulatedMeters;
        if (remainingMeters < metersToSplit) {
          accumulatedMeters += remainingMeters;
          accumulatedSeconds += remainingSeconds;
          break;
        }

        final ratio = metersToSplit / remainingMeters;
        accumulatedSeconds += remainingSeconds * ratio;
        splits.add(
          RunningSplitModel(
            kilometer: kilometer++,
            elapsedSeconds: accumulatedSeconds.round(),
          ),
        );
        remainingMeters -= metersToSplit;
        remainingSeconds -= remainingSeconds * ratio;
        accumulatedMeters = 0;
        accumulatedSeconds = 0;
      }
    }
    return splits;
  }

  static DateTime _timestamp(RunningRoutePointModel point) =>
      DateTime.tryParse(point.timestamp) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  static double _metersBetween(
    RunningRoutePointModel first,
    RunningRoutePointModel second,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(second.latitude - first.latitude);
    final longitudeDelta = _radians(second.longitude - first.longitude);
    final firstLatitude = _radians(first.latitude);
    final secondLatitude = _radians(second.latitude);
    final value =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(firstLatitude) *
            math.cos(secondLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(value), math.sqrt(1 - value));
  }

  static double _radians(double value) => value * math.pi / 180;
}
