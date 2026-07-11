import 'ready_plan_exercise_model.dart';

class ReadyPlanDayModel {
  final String id;
  final String name;
  final String title;
  final String weekday;
  final String muscleGroup;
  final int order;
  final List<ReadyPlanExerciseModel> exercises;

  const ReadyPlanDayModel({
    required this.id,
    required this.name,
    this.title = '',
    this.weekday = '',
    this.muscleGroup = '',
    this.order = 0,
    this.exercises = const [],
  });

  factory ReadyPlanDayModel.fromJson(Map<String, dynamic> json) {
    return ReadyPlanDayModel(
      id: _string(json['id']),
      name: _string(
        json['name'],
        fallback: _string(json['nome'], fallback: 'Dia'),
      ),
      title: _string(json['title'], fallback: _string(json['titulo'])),
      weekday: _string(json['weekday'], fallback: _string(json['diaSemana'])),
      muscleGroup: _string(
        json['muscleGroup'],
        fallback: _string(json['grupoMuscular']),
      ),
      order: _int(json['order'], fallback: _int(json['ordem'])),
      exercises: _maps(
        json['exercises'] ?? json['exercicios'],
      ).map(ReadyPlanExerciseModel.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'weekday': weekday,
    'muscleGroup': muscleGroup,
    'order': order,
    'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
  };

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
