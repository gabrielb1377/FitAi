class ReadyPlanExerciseModel {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final int order;
  final int sets;
  final String reps;
  final int restSeconds;
  final String rir;
  final String cadence;
  final String notes;
  final String category;
  final List<String> muscles;
  final List<String> equipment;

  const ReadyPlanExerciseModel({
    required this.id,
    this.exerciseId = '',
    required this.exerciseName,
    this.order = 0,
    this.sets = 0,
    this.reps = '',
    this.restSeconds = 0,
    this.rir = '',
    this.cadence = '',
    this.notes = '',
    this.category = '',
    this.muscles = const [],
    this.equipment = const [],
  });

  factory ReadyPlanExerciseModel.fromJson(Map<String, dynamic> json) {
    return ReadyPlanExerciseModel(
      id: _string(json['id']),
      exerciseId: _string(
        json['exerciseId'],
        fallback: _string(json['exercicioId']),
      ),
      exerciseName: _string(
        json['exerciseName'],
        fallback: _string(json['nome'], fallback: 'Exercício'),
      ),
      order: _int(json['order'], fallback: _int(json['ordem'])),
      sets: _int(json['sets'], fallback: _int(json['series'])),
      reps: _string(json['reps'], fallback: _string(json['repeticoes'])),
      restSeconds: _int(json['restSeconds'], fallback: _int(json['descanso'])),
      rir: _string(json['rir']),
      cadence: _string(json['cadence'], fallback: _string(json['cadencia'])),
      notes: _string(json['notes'], fallback: _string(json['observacoes'])),
      category: _string(json['category'], fallback: _string(json['categoria'])),
      muscles: _stringList(json['muscles'] ?? json['musculos']),
      equipment: _stringList(json['equipment'] ?? json['equipamentos']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'order': order,
    'sets': sets,
    'reps': reps,
    'restSeconds': restSeconds,
    'rir': rir,
    'cadence': cadence,
    'notes': notes,
    'category': category,
    'muscles': muscles,
    'equipment': equipment,
  };

  static String _string(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
