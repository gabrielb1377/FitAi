class DailyStepsModel {
  final String date;
  final int steps;
  final int goal;
  final String source;
  final DateTime? syncedAt;
  final DateTime updatedAt;

  const DailyStepsModel({
    required this.date,
    required this.steps,
    required this.goal,
    required this.source,
    required this.updatedAt,
    this.syncedAt,
  });

  static const String sourceHealthConnect = 'health_connect';
  static const String sourceLocal = 'local';
  static const String sourceManual = 'manual';

  bool get goalCompleted => steps >= goal;

  int get remainingSteps => (goal - steps).clamp(0, goal);

  double get progress => goal <= 0 ? 0 : (steps / goal).clamp(0.0, 1.0);

  double get estimatedDistanceKm => steps * 0.000762;

  double get estimatedCalories => steps * 0.04;

  int get estimatedActiveMinutes => (steps / 100).round();

  DailyStepsModel copyWith({
    String? date,
    int? steps,
    int? goal,
    String? source,
    DateTime? syncedAt,
    bool clearSyncedAt = false,
    DateTime? updatedAt,
  }) {
    return DailyStepsModel(
      date: date ?? this.date,
      steps: _nonNegative(steps ?? this.steps),
      goal: _nonNegative(goal ?? this.goal),
      source: source ?? this.source,
      syncedAt: clearSyncedAt ? null : syncedAt ?? this.syncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'steps': steps,
      'goal': goal,
      'source': source,
      'syncedAt': syncedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyStepsModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return DailyStepsModel(
      date: json['date']?.toString() ?? json['data']?.toString() ?? '',
      steps: _intFromJson(json['steps'] ?? json['passos']),
      goal: _intFromJson(
        json['goal'] ?? json['meta'] ?? json['metaDiaria'],
        fallback: 10000,
      ),
      source:
          json['source']?.toString() ??
          json['origem']?.toString() ??
          DailyStepsModel.sourceLocal,
      syncedAt: DateTime.tryParse(json['syncedAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  static int _intFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) return _nonNegative(value);
    if (value is num) return _nonNegative(value.round());

    return _nonNegative(int.tryParse(value?.toString() ?? '') ?? fallback);
  }

  static int _nonNegative(int value) {
    return value < 0 ? 0 : value;
  }
}
