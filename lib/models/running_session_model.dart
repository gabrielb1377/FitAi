enum RunningSyncStatus { local, syncing, queued, synced }

extension RunningSyncStatusStorage on RunningSyncStatus {
  String get storageValue => name;

  static RunningSyncStatus fromStorage(Object? value) =>
      RunningSyncStatus.values.firstWhere(
        (status) => status.name == value?.toString().trim().toLowerCase(),
        orElse: () => RunningSyncStatus.local,
      );
}

class RunningRoutePointModel {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final String timestamp;

  const RunningRoutePointModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp,
    };
  }

  factory RunningRoutePointModel.fromJson(Map<String, dynamic> json) {
    return RunningRoutePointModel(
      latitude: _doubleFromJson(json['latitude']),
      longitude: _doubleFromJson(json['longitude']),
      accuracy: _doubleFromJson(json['accuracy']),
      altitude: _doubleFromJson(json['altitude']),
      speed: _doubleFromJson(json['speed']),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  static double _doubleFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}

class RunningSessionModel {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int elapsedSeconds;
  final double distanceKm;
  final double averageSpeed;
  final double currentSpeed;
  final double pace;
  final double calories;
  final int? steps;
  final List<RunningRoutePointModel> route;
  final bool paused;
  final bool finished;
  final DateTime lastUpdatedAt;

  const RunningSessionModel({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.averageSpeed,
    required this.currentSpeed,
    required this.pace,
    required this.calories,
    this.steps,
    required this.route,
    required this.paused,
    required this.finished,
    required this.lastUpdatedAt,
  });

  factory RunningSessionModel.start({
    required String id,
    required DateTime startTime,
  }) {
    return RunningSessionModel(
      id: id,
      startTime: startTime,
      elapsedSeconds: 0,
      distanceKm: 0,
      averageSpeed: 0,
      currentSpeed: 0,
      pace: 0,
      calories: 0,
      steps: null,
      route: const [],
      paused: false,
      finished: false,
      lastUpdatedAt: startTime,
    );
  }

  RunningSessionModel copyWith({
    DateTime? endTime,
    bool clearEndTime = false,
    int? elapsedSeconds,
    double? distanceKm,
    double? averageSpeed,
    double? currentSpeed,
    double? pace,
    double? calories,
    int? steps,
    List<RunningRoutePointModel>? route,
    bool? paused,
    bool? finished,
    DateTime? lastUpdatedAt,
  }) {
    return RunningSessionModel(
      id: id,
      startTime: startTime,
      endTime: clearEndTime ? null : endTime ?? this.endTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceKm: _nonNegative(distanceKm ?? this.distanceKm),
      averageSpeed: _nonNegative(averageSpeed ?? this.averageSpeed),
      currentSpeed: _nonNegative(currentSpeed ?? this.currentSpeed),
      pace: _nonNegative(pace ?? this.pace),
      calories: _nonNegative(calories ?? this.calories),
      steps: steps ?? this.steps,
      route: route ?? this.route,
      paused: paused ?? this.paused,
      finished: finished ?? this.finished,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'distanceKm': distanceKm,
      'averageSpeed': averageSpeed,
      'currentSpeed': currentSpeed,
      'pace': pace,
      'calories': calories,
      'steps': steps,
      'route': route.map((point) => point.toJson()).toList(),
      'paused': paused,
      'finished': finished,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory RunningSessionModel.fromJson(Map<String, dynamic> json) {
    final startTime =
        DateTime.tryParse(json['startTime']?.toString() ?? '') ??
        DateTime.now();
    final elapsedSeconds = _intFromJson(
      json['elapsedSeconds'] ?? json['segundos'] ?? json['durationSeconds'],
    );
    final distanceKm = _doubleFromJson(json['distanceKm'] ?? json['distancia']);
    final averageSpeed = _doubleFromJson(json['averageSpeed']);
    final pace = _doubleFromJson(json['pace']);
    final route = _routeFromJson(json['route']);

    return RunningSessionModel(
      id: json['id']?.toString() ?? _fallbackId(startTime),
      startTime: startTime,
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      elapsedSeconds: elapsedSeconds < 0 ? 0 : elapsedSeconds,
      distanceKm: _nonNegative(distanceKm),
      averageSpeed: averageSpeed > 0
          ? averageSpeed
          : _calculateAverageSpeed(distanceKm, elapsedSeconds),
      currentSpeed: _nonNegative(_doubleFromJson(json['currentSpeed'])),
      pace: pace > 0 ? pace : _calculatePace(distanceKm, elapsedSeconds),
      calories: _nonNegative(
        _doubleFromJson(json['calories'], fallback: distanceKm * 60),
      ),
      steps: _nullableIntFromJson(json['steps'] ?? json['passos']),
      route: route,
      paused: _boolFromJson(json['paused']),
      finished: _boolFromJson(json['finished']),
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static List<RunningRoutePointModel> _routeFromJson(dynamic value) {
    if (value is! List) return const [];

    return value.whereType<Map>().map((item) {
      return RunningRoutePointModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  static double _calculateAverageSpeed(double distanceKm, int seconds) {
    if (distanceKm <= 0 || seconds <= 0) return 0;

    return distanceKm / (seconds / 3600);
  }

  static double _calculatePace(double distanceKm, int seconds) {
    if (distanceKm <= 0 || seconds <= 0) return 0;

    return (seconds / 60) / distanceKm;
  }

  static String _fallbackId(DateTime startTime) {
    return 'run_${startTime.microsecondsSinceEpoch}';
  }

  static bool _boolFromJson(dynamic value) {
    if (value is bool) return value;

    return value?.toString().toLowerCase() == 'true';
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableIntFromJson(dynamic value) {
    if (value == null) return null;
    return _intFromJson(value);
  }

  static double _doubleFromJson(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }

  static double _nonNegative(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 0;

    return value;
  }
}
