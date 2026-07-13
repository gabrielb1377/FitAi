enum ExerciseProgressionAction {
  increaseWeight,
  increaseReps,
  maintain,
  reduceWeight,
  deload,
  insufficientData,
}

enum ExerciseProgressionConfidence { low, medium, high }

class ExerciseProgressionConfig {
  final int sets;
  final String repRange;
  final int restSeconds;
  final String goal;
  final String level;

  const ExerciseProgressionConfig({
    required this.sets,
    required this.repRange,
    required this.restSeconds,
    required this.goal,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
    'sets': sets,
    'repRange': repRange,
    'restSeconds': restSeconds,
    'goal': goal,
    'level': level,
  };

  factory ExerciseProgressionConfig.fromJson(Map<String, dynamic> json) {
    return ExerciseProgressionConfig(
      sets: _int(json['sets'], fallback: 3),
      repRange: json['repRange']?.toString() ?? '6-12',
      restSeconds: _int(json['restSeconds'], fallback: 60),
      goal: json['goal']?.toString() ?? 'hipertrofia',
      level: json['level']?.toString() ?? 'intermediario',
    );
  }
}

class ExerciseProgressionModel {
  final String exerciseId;
  final String exerciseKey;
  final String exerciseName;
  final double currentWeight;
  final int currentSets;
  final String currentRepRange;
  final int currentRestSeconds;
  final double suggestedWeight;
  final int suggestedSets;
  final String suggestedRepRange;
  final int suggestedRestSeconds;
  final ExerciseProgressionAction action;
  final String reason;
  final ExerciseProgressionConfidence confidence;
  final int basedOnSessions;
  final DateTime generatedAt;

  const ExerciseProgressionModel({
    required this.exerciseId,
    required this.exerciseKey,
    required this.exerciseName,
    required this.currentWeight,
    required this.currentSets,
    required this.currentRepRange,
    required this.currentRestSeconds,
    required this.suggestedWeight,
    required this.suggestedSets,
    required this.suggestedRepRange,
    required this.suggestedRestSeconds,
    required this.action,
    required this.reason,
    required this.confidence,
    required this.basedOnSessions,
    required this.generatedAt,
  });

  bool get isActionable =>
      action == ExerciseProgressionAction.increaseWeight ||
      action == ExerciseProgressionAction.increaseReps ||
      action == ExerciseProgressionAction.reduceWeight ||
      action == ExerciseProgressionAction.deload;

  String get actionLabel => switch (action) {
    ExerciseProgressionAction.increaseWeight => 'Aumentar carga',
    ExerciseProgressionAction.increaseReps => 'Aumentar repeticoes',
    ExerciseProgressionAction.maintain => 'Manter configuracao',
    ExerciseProgressionAction.reduceWeight => 'Reduzir carga',
    ExerciseProgressionAction.deload => 'Deload sugerido',
    ExerciseProgressionAction.insufficientData => 'Dados insuficientes',
  };

  String get actionCode => switch (action) {
    ExerciseProgressionAction.increaseWeight => 'increase_weight',
    ExerciseProgressionAction.increaseReps => 'increase_reps',
    ExerciseProgressionAction.maintain => 'maintain',
    ExerciseProgressionAction.reduceWeight => 'reduce_weight',
    ExerciseProgressionAction.deload => 'deload',
    ExerciseProgressionAction.insufficientData => 'insufficient_data',
  };

  String get confidenceLabel => switch (confidence) {
    ExerciseProgressionConfidence.high => 'Alta confianca',
    ExerciseProgressionConfidence.medium => 'Confianca moderada',
    ExerciseProgressionConfidence.low => 'Baixa confianca',
  };

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseKey': exerciseKey,
    'exerciseName': exerciseName,
    'currentWeight': currentWeight,
    'currentSets': currentSets,
    'currentRepRange': currentRepRange,
    'currentRestSeconds': currentRestSeconds,
    'suggestedWeight': suggestedWeight,
    'suggestedSets': suggestedSets,
    'suggestedRepRange': suggestedRepRange,
    'suggestedRestSeconds': suggestedRestSeconds,
    'action': actionCode,
    'reason': reason,
    'confidence': confidence.name,
    'basedOnSessions': basedOnSessions,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory ExerciseProgressionModel.fromJson(Map<String, dynamic> json) {
    return ExerciseProgressionModel(
      exerciseId: json['exerciseId']?.toString() ?? '',
      exerciseKey: json['exerciseKey']?.toString() ?? '',
      exerciseName: json['exerciseName']?.toString() ?? 'Exercicio',
      currentWeight: _double(json['currentWeight']),
      currentSets: _int(json['currentSets'], fallback: 3),
      currentRepRange: json['currentRepRange']?.toString() ?? '6-12',
      currentRestSeconds: _int(json['currentRestSeconds'], fallback: 60),
      suggestedWeight: _double(json['suggestedWeight']),
      suggestedSets: _int(json['suggestedSets'], fallback: 3),
      suggestedRepRange: json['suggestedRepRange']?.toString() ?? '6-12',
      suggestedRestSeconds: _int(json['suggestedRestSeconds'], fallback: 60),
      action: _actionFromJson(json['action']?.toString()),
      reason: json['reason']?.toString() ?? '',
      confidence: ExerciseProgressionConfidence.values.firstWhere(
        (value) => value.name == json['confidence']?.toString(),
        orElse: () => ExerciseProgressionConfidence.low,
      ),
      basedOnSessions: _int(json['basedOnSessions']),
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

ExerciseProgressionAction _actionFromJson(String? value) => switch (value) {
  'increase_weight' ||
  'increaseWeight' => ExerciseProgressionAction.increaseWeight,
  'increase_reps' || 'increaseReps' => ExerciseProgressionAction.increaseReps,
  'reduce_weight' || 'reduceWeight' => ExerciseProgressionAction.reduceWeight,
  'deload' => ExerciseProgressionAction.deload,
  'insufficient_data' ||
  'insufficientData' => ExerciseProgressionAction.insufficientData,
  _ => ExerciseProgressionAction.maintain,
};

int _int(dynamic value, {int fallback = 0}) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}
