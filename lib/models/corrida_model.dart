import 'running_session_model.dart';

class CorridaModel {
  final String id;
  final String userId;
  final double distancia;
  final int segundos;
  final String data;
  final String startTime;
  final String? endTime;
  final double averageSpeed;
  final double currentSpeed;
  final double pace;
  final double? calories;
  final RunningCaloriesSource? caloriesSource;
  final int? steps;
  final RunningSyncStatus syncStatus;
  final List<RunningRoutePointModel> route;
  final bool paused;
  final bool finished;
  final int version;
  final String remoteRevision;
  final String updatedAt;
  final String? deletedAt;

  CorridaModel({
    String? id,
    this.userId = 'local',
    required this.distancia,
    required this.segundos,
    required this.data,
    String? startTime,
    this.endTime,
    double? averageSpeed,
    this.currentSpeed = 0,
    double? pace,
    this.calories,
    this.caloriesSource,
    this.steps,
    this.syncStatus = RunningSyncStatus.local,
    this.route = const [],
    this.paused = false,
    this.finished = true,
    this.version = 1,
    this.remoteRevision = '0',
    String? updatedAt,
    this.deletedAt,
  }) : id = id ?? _buildId(startTime ?? data),
       startTime = startTime ?? data,
       updatedAt = updatedAt ?? endTime ?? data,
       averageSpeed =
           averageSpeed ?? _calculateAverageSpeed(distancia, segundos),
       pace = pace ?? _calculatePace(distancia, segundos);

  bool get hasReliableCalories => calories != null && caloriesSource != null;
  bool get isDeleted => deletedAt != null;
  String get mutationId => 'run:$id:v$version';

  factory CorridaModel.fromSession(
    RunningSessionModel session, {
    String userId = 'local',
  }) {
    final endTime = session.endTime ?? DateTime.now();

    return CorridaModel(
      id: session.id,
      userId: userId,
      distancia: session.distanceKm,
      segundos: session.elapsedSeconds,
      data: endTime.toIso8601String(),
      startTime: session.startTime.toIso8601String(),
      endTime: endTime.toIso8601String(),
      averageSpeed: session.averageSpeed,
      currentSpeed: session.currentSpeed,
      pace: session.pace,
      calories: session.calories,
      caloriesSource: session.caloriesSource,
      steps: session.steps,
      syncStatus: RunningSyncStatus.local,
      route: session.route,
      paused: session.paused,
      finished: true,
      updatedAt: endTime.toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'distancia': distancia,
      'segundos': segundos,
      'data': data,
      'startTime': startTime,
      'endTime': endTime,
      'elapsedSeconds': segundos,
      'distanceKm': distancia,
      'averageSpeed': averageSpeed,
      'velocidadeMedia': averageSpeed,
      'currentSpeed': currentSpeed,
      'pace': pace,
      'calories': hasReliableCalories ? calories : null,
      'caloriesSource': caloriesSource?.storageValue,
      'steps': steps,
      'passos': steps,
      'syncStatus': syncStatus.storageValue,
      'route': route.map((point) => point.toJson()).toList(),
      'paused': paused,
      'finished': finished,
      'version': version,
      'remoteRevision': remoteRevision,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  factory CorridaModel.fromJson(Map<String, dynamic> json) {
    final distancia = _doubleFromJson(json['distancia'] ?? json['distanceKm']);
    final segundos = _intFromJson(
      json['segundos'] ?? json['elapsedSeconds'] ?? json['durationSeconds'],
    );

    return CorridaModel(
      id: json['id']?.toString(),
      userId: json['userId']?.toString().trim().isNotEmpty == true
          ? json['userId'].toString().trim()
          : 'local',
      distancia: distancia,
      segundos: segundos,
      data:
          json['data']?.toString() ??
          json['endTime']?.toString() ??
          json['performedAt']?.toString() ??
          '',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      averageSpeed: _doubleFromJson(
        json['averageSpeed'] ?? json['velocidadeMedia'],
        fallback: _calculateAverageSpeed(distancia, segundos),
      ),
      currentSpeed: _doubleFromJson(json['currentSpeed']),
      pace: _doubleFromJson(
        json['pace'],
        fallback: _calculatePace(distancia, segundos),
      ),
      calories: _nullableDouble(json['calories']),
      caloriesSource: RunningCaloriesSourceStorage.fromStorage(
        json['caloriesSource'],
      ),
      steps: _nullableIntFromJson(json['steps'] ?? json['passos']),
      syncStatus: RunningSyncStatusStorage.fromStorage(json['syncStatus']),
      route: _routeFromJson(json['route']),
      paused: _boolFromJson(json['paused']),
      finished: json.containsKey('finished')
          ? _boolFromJson(json['finished'])
          : true,
      version: _intFromJson(json['version']).clamp(1, 1 << 30).toInt(),
      remoteRevision: json['remoteRevision']?.toString() ?? '0',
      updatedAt:
          json['updatedAt']?.toString() ??
          json['endTime']?.toString() ??
          json['data']?.toString(),
      deletedAt: json['deletedAt']?.toString(),
    );
  }

  static List<RunningRoutePointModel> _routeFromJson(dynamic value) {
    if (value is! List) return const [];

    return value.whereType<Map>().map((item) {
      return RunningRoutePointModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  static String _buildId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'run_${DateTime.now().microsecondsSinceEpoch}';
    }

    return 'run_${normalized.hashCode.abs()}';
  }

  static double _calculateAverageSpeed(double distanceKm, int seconds) {
    if (distanceKm <= 0 || seconds <= 0) return 0;

    return distanceKm / (seconds / 3600);
  }

  static double _calculatePace(double distanceKm, int seconds) {
    if (distanceKm <= 0 || seconds <= 0) return 0;

    return (seconds / 60) / distanceKm;
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

  CorridaModel copyWith({
    String? userId,
    String? endTime,
    double? averageSpeed,
    double? currentSpeed,
    double? pace,
    double? calories,
    RunningCaloriesSource? caloriesSource,
    bool clearCalories = false,
    bool clearCaloriesSource = false,
    int? steps,
    List<RunningRoutePointModel>? route,
    RunningSyncStatus? syncStatus,
    int? version,
    String? remoteRevision,
    String? updatedAt,
    String? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return CorridaModel(
      id: id,
      userId: userId ?? this.userId,
      distancia: distancia,
      segundos: segundos,
      data: data,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      pace: pace ?? this.pace,
      calories: clearCalories ? null : calories ?? this.calories,
      caloriesSource: clearCaloriesSource
          ? null
          : caloriesSource ?? this.caloriesSource,
      steps: steps ?? this.steps,
      route: route ?? this.route,
      paused: paused,
      finished: finished,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  static double _doubleFromJson(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }

  static double? _nullableDouble(dynamic value) {
    if (value is! num) return null;
    final parsed = value.toDouble();
    return parsed.isFinite && parsed >= 0 ? parsed : null;
  }
}
