/// Origem declarada para o agregado diário de passos.
///
/// A origem é preservada para que a interface não apresente uma leitura seed,
/// manual ou legada como se tivesse vindo de um sensor.
enum DailyStepsSource { local, manual, seed, device, healthConnect }

extension DailyStepsSourceStorage on DailyStepsSource {
  String get storageValue => switch (this) {
    DailyStepsSource.local => 'local',
    DailyStepsSource.manual => 'manual',
    DailyStepsSource.seed => 'seed',
    DailyStepsSource.device => 'device',
    DailyStepsSource.healthConnect => 'health_connect',
  };

  String get label => switch (this) {
    DailyStepsSource.local => 'Dados locais',
    DailyStepsSource.manual => 'Registro manual',
    DailyStepsSource.seed => 'Dados de demonstração',
    DailyStepsSource.device => 'Dispositivo',
    DailyStepsSource.healthConnect => 'Health Connect',
  };

  static DailyStepsSource fromStorage(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'manual' => DailyStepsSource.manual,
      'seed' => DailyStepsSource.seed,
      'device' => DailyStepsSource.device,
      'health_connect' ||
      'healthconnect' ||
      'health' => DailyStepsSource.healthConnect,
      _ => DailyStepsSource.local,
    };
  }
}

/// Estado local da tentativa de sincronização de um registro diário.
enum DailyStepsSyncStatus { local, pending, syncing, synced, conflict, failed }

extension DailyStepsSyncStatusStorage on DailyStepsSyncStatus {
  String get storageValue => name;

  static DailyStepsSyncStatus fromStorage(Object? value) {
    return DailyStepsSyncStatus.values.firstWhere(
      (status) => status.storageValue == value?.toString().trim(),
      orElse: () => DailyStepsSyncStatus.local,
    );
  }
}

/// Registro canônico de passos para um único usuário em um único dia local.
///
/// Distância e calorias são opcionais. O modelo não calcula estimativas a
/// partir dos passos porque isso exigiria parâmetros que o FitIA ainda não
/// possui com confiança (por exemplo, passada, peso e fonte do dispositivo).
class DailyStepsModel {
  DailyStepsModel({
    required String date,
    required int steps,
    required int goal,
    required this.source,
    required this.recordedAt,
    required this.updatedAt,
    this.id,
    String userId = defaultUserId,
    this.estimatedDistanceMeters,
    this.estimatedCalories,
    this.syncedAt,
    this.syncStatus = DailyStepsSyncStatus.local,
    this.version = 1,
  }) : date = normalizeDateKey(date, fallback: recordedAt),
       userId = userId.trim().isEmpty ? defaultUserId : userId.trim(),
       steps = steps < 0 ? 0 : steps,
       goal = goal < 0 ? 0 : goal,
       assert(estimatedDistanceMeters == null || estimatedDistanceMeters >= 0),
       assert(estimatedCalories == null || estimatedCalories >= 0),
       assert(version >= 1);

  static const String defaultUserId = 'local';
  static const String sourceHealthConnect = 'health_connect';
  static const String sourceLocal = 'local';
  static const String sourceManual = 'manual';
  static const String sourceSeed = 'seed';
  static const String sourceDevice = 'device';

  /// Identificador estável; se ausente em dados legados, [naturalId] é usado.
  final String? id;
  final String userId;
  final String date;
  final int steps;
  final int goal;
  final String source;
  final double? estimatedDistanceMeters;
  final double? estimatedCalories;
  final DateTime recordedAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DailyStepsSyncStatus syncStatus;
  final int version;

  String get recordId => id?.trim().isNotEmpty == true
      ? id!.trim()
      : naturalId(userId: userId, date: date);

  DailyStepsSource get sourceKind =>
      DailyStepsSourceStorage.fromStorage(source);

  String get sourceLabel => sourceKind.label;

  bool get hasEstimatedDistance => estimatedDistanceMeters != null;

  bool get hasEstimatedCalories => estimatedCalories != null;

  bool get goalCompleted => goal > 0 && steps >= goal;

  int get remainingSteps =>
      goal <= 0 ? 0 : (goal - steps).clamp(0, goal).toInt();

  double get progress =>
      goal <= 0 ? 0 : (steps / goal).clamp(0.0, 1.0).toDouble();

  DailyStepsModel copyWith({
    String? id,
    String? userId,
    String? date,
    int? steps,
    int? goal,
    String? source,
    double? estimatedDistanceMeters,
    bool clearEstimatedDistance = false,
    double? estimatedCalories,
    bool clearEstimatedCalories = false,
    DateTime? recordedAt,
    DateTime? syncedAt,
    bool clearSyncedAt = false,
    DateTime? updatedAt,
    DailyStepsSyncStatus? syncStatus,
    int? version,
  }) {
    return DailyStepsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
      source: source ?? this.source,
      estimatedDistanceMeters: clearEstimatedDistance
          ? null
          : estimatedDistanceMeters ?? this.estimatedDistanceMeters,
      estimatedCalories: clearEstimatedCalories
          ? null
          : estimatedCalories ?? this.estimatedCalories,
      recordedAt: recordedAt ?? this.recordedAt,
      syncedAt: clearSyncedAt ? null : syncedAt ?? this.syncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': recordId,
      'userId': userId,
      'date': normalizeDateKey(date, fallback: recordedAt),
      'steps': steps,
      'goal': goal,
      'source': sourceKind.storageValue,
      'estimatedDistanceMeters': estimatedDistanceMeters,
      'estimatedCalories': estimatedCalories,
      'recordedAt': recordedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'syncStatus': syncStatus.storageValue,
      'version': version,
    };
  }

  factory DailyStepsModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final recordedAt =
        DateTime.tryParse(json['recordedAt']?.toString() ?? '') ?? now;
    final updatedAt =
        DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? recordedAt;
    final userId = _nonBlank(json['userId']) ?? defaultUserId;
    final date = normalizeDateKey(
      json['date']?.toString() ?? json['data']?.toString() ?? '',
      fallback: recordedAt,
    );
    final syncedAt = DateTime.tryParse(json['syncedAt']?.toString() ?? '');

    return DailyStepsModel(
      id: _nonBlank(json['id']) ?? naturalId(userId: userId, date: date),
      userId: userId,
      date: date,
      steps: _intFromJson(json['steps'] ?? json['passos']),
      goal: _intFromJson(
        json['goal'] ?? json['meta'] ?? json['metaDiaria'],
        fallback: 10000,
      ),
      source: DailyStepsSourceStorage.fromStorage(
        json['source'] ?? json['origem'],
      ).storageValue,
      estimatedDistanceMeters: _nonNegativeDouble(
        json['estimatedDistanceMeters'],
      ),
      estimatedCalories: _nonNegativeDouble(json['estimatedCalories']),
      recordedAt: recordedAt,
      updatedAt: updatedAt,
      syncedAt: syncedAt,
      syncStatus: json.containsKey('syncStatus')
          ? DailyStepsSyncStatusStorage.fromStorage(json['syncStatus'])
          : syncedAt == null
          ? DailyStepsSyncStatus.local
          : DailyStepsSyncStatus.synced,
      version: _intFromJson(
        json['version'],
        fallback: 1,
      ).clamp(1, 1 << 30).toInt(),
    );
  }

  static String naturalId({required String userId, required String date}) {
    return 'steps:${userId.trim().isEmpty ? defaultUserId : userId.trim()}:${normalizeDateKey(date)}';
  }

  static String normalizeDateKey(String value, {DateTime? fallback}) {
    final parsed = DateTime.tryParse(value)?.toLocal() ?? fallback?.toLocal();
    if (parsed == null) return value.trim();
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  static int _intFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) return value.round() < 0 ? 0 : value.round();
    return (int.tryParse(value?.toString() ?? '') ?? fallback)
        .clamp(0, 1 << 30)
        .toInt();
  }

  static double? _nonNegativeDouble(dynamic value) {
    if (value is! num) return null;
    final parsed = value.toDouble();
    return parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  static String? _nonBlank(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
