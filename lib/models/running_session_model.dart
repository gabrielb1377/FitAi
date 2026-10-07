enum RunningSyncStatus { local, syncing, queued, synced, conflict }

/// Proveniência obrigatória para uma métrica calórica de corrida.
///
/// Distância e duração não permitem inferir gasto energético com precisão. Um
/// valor sem fonte explícita é tratado como indisponível pela apresentação.
enum RunningCaloriesSource { device, health, manual, seed }

extension RunningCaloriesSourceStorage on RunningCaloriesSource {
  String get storageValue => name;

  static RunningCaloriesSource? fromStorage(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final source in RunningCaloriesSource.values) {
      if (source.storageValue == normalized) return source;
    }
    return null;
  }
}

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

  /// Progress accepted by the running core, never recomputed from coordinates.
  final double? cumulativeDistanceKm;
  final int? activeElapsedSeconds;
  final bool? startsSegment;

  const RunningRoutePointModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.timestamp,
    this.cumulativeDistanceKm,
    this.activeElapsedSeconds,
    this.startsSegment,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp,
      if (cumulativeDistanceKm != null)
        'cumulativeDistanceKm': cumulativeDistanceKm,
      if (activeElapsedSeconds != null)
        'activeElapsedSeconds': activeElapsedSeconds,
      if (startsSegment != null) 'startsSegment': startsSegment,
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
      cumulativeDistanceKm: json['cumulativeDistanceKm'] is num
          ? (json['cumulativeDistanceKm'] as num).toDouble()
          : null,
      activeElapsedSeconds: json['activeElapsedSeconds'] is int
          ? json['activeElapsedSeconds'] as int
          : null,
      startsSegment: json['startsSegment'] is bool
          ? json['startsSegment'] as bool
          : null,
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
  final double? calories;
  final RunningCaloriesSource? caloriesSource;
  final int? steps;
  final List<RunningRoutePointModel> route;
  final bool paused;
  final DateTime? pausedAt;
  final int accumulatedPausedSeconds;
  final bool finalizing;
  final bool finished;
  final DateTime lastUpdatedAt;

  bool get hasReliableCalories => calories != null && caloriesSource != null;

  const RunningSessionModel({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.averageSpeed,
    required this.currentSpeed,
    required this.pace,
    this.calories,
    this.caloriesSource,
    this.steps,
    required this.route,
    required this.paused,
    this.pausedAt,
    this.accumulatedPausedSeconds = 0,
    this.finalizing = false,
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
      calories: null,
      steps: null,
      route: const [],
      paused: false,
      pausedAt: null,
      accumulatedPausedSeconds: 0,
      finalizing: false,
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
    RunningCaloriesSource? caloriesSource,
    bool clearCalories = false,
    bool clearCaloriesSource = false,
    int? steps,
    List<RunningRoutePointModel>? route,
    bool? paused,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    int? accumulatedPausedSeconds,
    bool? finalizing,
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
      calories: clearCalories
          ? null
          : _nullableNonNegative(calories ?? this.calories),
      caloriesSource: clearCaloriesSource
          ? null
          : caloriesSource ?? this.caloriesSource,
      steps: steps ?? this.steps,
      route: route ?? this.route,
      paused: paused ?? this.paused,
      pausedAt: clearPausedAt ? null : pausedAt ?? this.pausedAt,
      accumulatedPausedSeconds: _nonNegativeInt(
        accumulatedPausedSeconds ?? this.accumulatedPausedSeconds,
      ),
      finalizing: finalizing ?? this.finalizing,
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
      'calories': hasReliableCalories ? calories : null,
      'caloriesSource': caloriesSource?.storageValue,
      'steps': steps,
      'route': route.map((point) => point.toJson()).toList(),
      'paused': paused,
      'pausedAt': pausedAt?.toIso8601String(),
      'accumulatedPausedSeconds': accumulatedPausedSeconds,
      'finalizing': finalizing,
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
      calories: _nullableNonNegative(json['calories']),
      caloriesSource: RunningCaloriesSourceStorage.fromStorage(
        json['caloriesSource'],
      ),
      steps: _nullableIntFromJson(json['steps'] ?? json['passos']),
      route: route,
      paused: _boolFromJson(json['paused']),
      pausedAt:
          DateTime.tryParse(json['pausedAt']?.toString() ?? '') ??
          (_boolFromJson(json['paused'])
              ? DateTime.tryParse(json['lastUpdatedAt']?.toString() ?? '')
              : null),
      accumulatedPausedSeconds: _nonNegativeInt(
        _intFromJson(json['accumulatedPausedSeconds']),
      ),
      finalizing: _boolFromJson(json['finalizing']),
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

  static double? _nullableNonNegative(dynamic value) {
    if (value is! num) return null;
    final parsed = value.toDouble();
    return parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  static int _nonNegativeInt(int value) => value < 0 ? 0 : value;
}
