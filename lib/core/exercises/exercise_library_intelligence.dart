import '../../models/exercicio_model.dart';
import 'exercise_identity.dart';

/// An event that contributes to the personal exercise ranking.
enum ExerciseUsageEvent {
  viewed(1),
  addedToPlan(4),
  addedToWorkout(5),
  replacedInWorkout(4),
  startedInWorkout(6);

  const ExerciseUsageEvent(this.weight);

  final int weight;
}

/// A human-readable contribution used by deterministic recommendations.
class ExerciseRecommendationReason {
  const ExerciseRecommendationReason({
    required this.code,
    required this.label,
    required this.description,
    required this.scoreContribution,
  });

  final String code;
  final String label;
  final String description;
  final int scoreContribution;
}

/// One related exercise ranked from local catalog metadata only.
class ExerciseRecommendation {
  const ExerciseRecommendation({
    required this.exercise,
    required this.score,
    required this.reasons,
  });

  final ExercicioModel exercise;
  final int score;
  final List<ExerciseRecommendationReason> reasons;
}

/// The user-facing category for a possible exercise replacement.
enum ExerciseSubstitutionKind {
  equivalent,
  sameMuscle,
  sameMovement,
  sameEquipment,
  noEquipment,
  easier,
  harder,
}

class ExerciseSubstitution {
  const ExerciseSubstitution({
    required this.exercise,
    required this.kind,
    required this.recommendation,
    required this.preserved,
    required this.changed,
  });

  final ExercicioModel exercise;
  final ExerciseSubstitutionKind kind;
  final ExerciseRecommendation recommendation;
  final List<String> preserved;
  final List<String> changed;
}

/// Objective comparison data. It intentionally contains no clinical claims.
class ExerciseComparison {
  const ExerciseComparison({
    required this.first,
    required this.second,
    required this.sharedMuscles,
    required this.firstOnlyMuscles,
    required this.secondOnlyMuscles,
    required this.sameMovement,
    required this.sameEquipment,
    required this.sameDifficulty,
    required this.summary,
  });

  final ExercicioModel first;
  final ExercicioModel second;
  final List<String> sharedMuscles;
  final List<String> firstOnlyMuscles;
  final List<String> secondOnlyMuscles;
  final bool sameMovement;
  final bool sameEquipment;
  final bool sameDifficulty;
  final List<String> summary;
}

/// A collection derived from the current catalog, never a hardcoded exercise list.
class ExerciseCollection {
  const ExerciseCollection({
    required this.id,
    required this.label,
    required this.exercises,
  });

  final String id;
  final String label;
  final List<ExercicioModel> exercises;
}

/// Pure, deterministic rules used by the Library, Plans and Workout flows.
///
/// The legacy [ExercicioModel] does not yet store a formal movement pattern,
/// so the rule derives a conservative pattern from names and tags. A later
/// canonical catalog can replace [_movementFor] without changing consumers.
class ExerciseLibraryIntelligence {
  const ExerciseLibraryIntelligence();

  static final RegExp _pushPattern = RegExp(
    r'supino|flexao|desenvolvimento|press',
  );
  static final RegExp _pullPattern = RegExp(r'remada|puxada|barra fixa|pull');
  static final RegExp _squatPattern = RegExp(r'agachamento|afundo|leg press');
  static final RegExp _hingePattern = RegExp(
    r'terra|stiff|romeno|good morning',
  );
  static final RegExp _isolationPattern = RegExp(
    r'rosca|extensora|flexora|elevacao|triceps',
  );
  static final RegExp _fullBodyPattern = RegExp(r'burpee|clean|thruster');

  List<ExerciseRecommendation> related({
    required ExercicioModel exercise,
    required Iterable<ExercicioModel> catalog,
    int limit = 8,
  }) {
    final source = _featuresFor(exercise);
    final ranked = <_IndexedRecommendation>[];
    var index = 0;
    for (final candidate in catalog) {
      final candidateFeatures = _featuresFor(candidate);
      if (_sameExerciseFeatures(source, candidateFeatures)) {
        index++;
        continue;
      }
      final recommendation = _scoreFeatures(
        candidate,
        source,
        candidateFeatures,
      );
      if (recommendation.score > 0) {
        ranked.add(_IndexedRecommendation(index, recommendation));
      }
      index++;
    }
    ranked.sort((left, right) {
      final score = right.recommendation.score.compareTo(
        left.recommendation.score,
      );
      return score != 0 ? score : left.index.compareTo(right.index);
    });
    return ranked
        .take(limit)
        .map((item) => item.recommendation)
        .toList(growable: false);
  }

  List<ExerciseSubstitution> substitutions({
    required ExercicioModel exercise,
    required Iterable<ExercicioModel> catalog,
    int limit = 8,
  }) {
    final result = <ExerciseSubstitution>[];
    for (final recommendation in related(
      exercise: exercise,
      catalog: catalog,
      limit: catalog.length,
    )) {
      final candidate = recommendation.exercise;
      final kind = _substitutionKind(exercise, candidate);
      if (kind == null) continue;
      result.add(
        ExerciseSubstitution(
          exercise: candidate,
          kind: kind,
          recommendation: recommendation,
          preserved: _preservedFor(exercise, candidate),
          changed: _changedFor(exercise, candidate),
        ),
      );
      if (result.length == limit) break;
    }
    return result;
  }

  List<ExercicioModel> mostUsed({
    required Iterable<ExercicioModel> catalog,
    required Map<String, int> usageScoreById,
    int limit = 8,
  }) {
    final indexed = <_IndexedExercise>[];
    var index = 0;
    for (final exercise in catalog) {
      final score = usageScoreById[_idFor(exercise)] ?? 0;
      if (score > 0) indexed.add(_IndexedExercise(index, exercise, score));
      index++;
    }
    indexed.sort((left, right) {
      final score = right.score.compareTo(left.score);
      return score != 0 ? score : left.index.compareTo(right.index);
    });
    return indexed
        .take(limit)
        .map((item) => item.exercise)
        .toList(growable: false);
  }

  ExerciseComparison compare(ExercicioModel first, ExercicioModel second) {
    final firstMuscles = _musclesFor(first);
    final secondMuscles = _musclesFor(second);
    final shared = firstMuscles.intersection(secondMuscles).toList()..sort();
    final firstOnly = firstMuscles.difference(secondMuscles).toList()..sort();
    final secondOnly = secondMuscles.difference(firstMuscles).toList()..sort();
    final sameMovement = _movementFor(first) == _movementFor(second);
    final sameEquipment = _equipmentFor(
      first,
    ).intersection(_equipmentFor(second)).isNotEmpty;
    final sameDifficulty = _difficultyDistance(first, second) == 0;

    final summary = <String>[
      if (shared.isNotEmpty)
        'Preserva ${shared.join(', ')} como musculo em comum.',
      if (sameMovement) 'Preserva o mesmo padrao de movimento.',
      if (!sameMovement) 'Atende a um padrao de movimento diferente.',
      if (!sameEquipment) 'Exige equipamento diferente.',
      if (_difficultyDistance(first, second) > 0)
        'A segunda opcao exige nivel diferente.',
    ];
    if (summary.isEmpty) {
      summary.add('Compare equipamentos e instrucoes antes de escolher.');
    }
    return ExerciseComparison(
      first: first,
      second: second,
      sharedMuscles: shared,
      firstOnlyMuscles: firstOnly,
      secondOnlyMuscles: secondOnly,
      sameMovement: sameMovement,
      sameEquipment: sameEquipment,
      sameDifficulty: sameDifficulty,
      summary: summary,
    );
  }

  List<ExerciseCollection> collections(Iterable<ExercicioModel> catalog) {
    final source = catalog.toList(growable: false);
    return [
          _collection(
            'push',
            'Empurrar',
            source,
            (exercise) => _movementFor(exercise) == 'push',
          ),
          _collection(
            'pull',
            'Puxar',
            source,
            (exercise) => _movementFor(exercise) == 'pull',
          ),
          _collection(
            'legs',
            'Pernas',
            source,
            (exercise) =>
                _hasText(exercise, 'perna') ||
                _hasText(exercise, 'quadricep') ||
                _hasText(exercise, 'gluteo'),
          ),
          _collection(
            'full-body',
            'Corpo inteiro',
            source,
            (exercise) =>
                _hasText(exercise, 'corpo inteiro') ||
                _movementFor(exercise) == 'full-body',
          ),
          _collection(
            'bodyweight',
            'Peso corporal',
            source,
            (exercise) =>
                _hasEquipment(exercise, 'corpo') ||
                _hasEquipment(exercise, 'peso corporal'),
          ),
          _collection(
            'dumbbells',
            'Halteres',
            source,
            (exercise) => _hasEquipment(exercise, 'halter'),
          ),
          _collection(
            'machines',
            'Maquinas',
            source,
            (exercise) =>
                _hasEquipment(exercise, 'maquina') ||
                _hasEquipment(exercise, 'smith'),
          ),
          _collection(
            'mobility',
            'Mobilidade',
            source,
            (exercise) => _hasText(exercise, 'mobilidade'),
          ),
          _collection(
            'warmup',
            'Aquecimento',
            source,
            (exercise) => _hasText(exercise, 'aquecimento'),
          ),
        ]
        .where((collection) => collection.exercises.isNotEmpty)
        .toList(growable: false);
  }

  ExerciseRecommendation _scoreFeatures(
    ExercicioModel candidate,
    _ExerciseFeatures source,
    _ExerciseFeatures candidateFeatures,
  ) {
    final reasons = <ExerciseRecommendationReason>[];
    final sourcePrimary = source.primaryMuscle;
    final candidatePrimary = candidateFeatures.primaryMuscle;
    if (sourcePrimary.isNotEmpty && sourcePrimary == candidatePrimary) {
      reasons.add(
        const ExerciseRecommendationReason(
          code: 'same_primary_muscle',
          label: 'Mesmo musculo principal',
          description: 'Trabalha o mesmo musculo principal.',
          scoreContribution: 40,
        ),
      );
    }
    if (source.movement == candidateFeatures.movement &&
        source.movement != 'other') {
      reasons.add(
        const ExerciseRecommendationReason(
          code: 'same_movement',
          label: 'Mesmo padrao de movimento',
          description: 'Preserva o padrao principal de movimento.',
          scoreContribution: 25,
        ),
      );
    }
    if (source.equipment.intersection(candidateFeatures.equipment).isNotEmpty) {
      reasons.add(
        const ExerciseRecommendationReason(
          code: 'compatible_equipment',
          label: 'Equipamento compativel',
          description: 'Pode ser executado com equipamento compativel.',
          scoreContribution: 15,
        ),
      );
    }
    if ((source.difficulty - candidateFeatures.difficulty).abs() <= 1) {
      reasons.add(
        const ExerciseRecommendationReason(
          code: 'near_difficulty',
          label: 'Dificuldade proxima',
          description: 'Tem dificuldade proxima a do exercicio atual.',
          scoreContribution: 10,
        ),
      );
    }
    if (source.muscles.intersection(candidateFeatures.muscles).isNotEmpty) {
      reasons.add(
        const ExerciseRecommendationReason(
          code: 'shared_secondary_muscle',
          label: 'Musculos secundarios em comum',
          description: 'Compartilha musculos secundarios.',
          scoreContribution: 10,
        ),
      );
    }
    return ExerciseRecommendation(
      exercise: candidate,
      score: reasons.fold(
        0,
        (score, reason) => score + reason.scoreContribution,
      ),
      reasons: List.unmodifiable(reasons),
    );
  }

  ExerciseSubstitutionKind? _substitutionKind(
    ExercicioModel source,
    ExercicioModel candidate,
  ) {
    final samePrimary =
        _primaryMuscle(source).isNotEmpty &&
        _primaryMuscle(source) == _primaryMuscle(candidate);
    final sameMovement =
        _movementFor(source) == _movementFor(candidate) &&
        _movementFor(source) != 'other';
    final sameEquipment = _equipmentFor(
      source,
    ).intersection(_equipmentFor(candidate)).isNotEmpty;
    final difficulty = _difficultyRank(candidate) - _difficultyRank(source);
    if (samePrimary && sameMovement && sameEquipment) {
      return ExerciseSubstitutionKind.equivalent;
    }
    if ((_hasEquipment(source, 'barra') ||
            _hasEquipment(source, 'halter') ||
            _hasEquipment(source, 'maquina') ||
            _hasEquipment(source, 'cabo')) &&
        (_hasEquipment(candidate, 'corpo') ||
            _hasEquipment(candidate, 'peso corporal'))) {
      return ExerciseSubstitutionKind.noEquipment;
    }
    if (difficulty < 0) {
      return ExerciseSubstitutionKind.easier;
    }
    if (difficulty > 0) {
      return ExerciseSubstitutionKind.harder;
    }
    if (samePrimary && sameMovement) {
      return ExerciseSubstitutionKind.sameMovement;
    }
    if (samePrimary) {
      return ExerciseSubstitutionKind.sameMuscle;
    }
    if (sameEquipment) {
      return ExerciseSubstitutionKind.sameEquipment;
    }
    return null;
  }

  List<String> _preservedFor(
    ExercicioModel source,
    ExercicioModel candidate,
  ) => [
    if (_primaryMuscle(source).isNotEmpty &&
        _primaryMuscle(source) == _primaryMuscle(candidate))
      'musculo principal',
    if (_movementFor(source) == _movementFor(candidate) &&
        _movementFor(source) != 'other')
      'padrao de movimento',
    if (_equipmentFor(source).intersection(_equipmentFor(candidate)).isNotEmpty)
      'equipamento compativel',
  ];

  List<String> _changedFor(ExercicioModel source, ExercicioModel candidate) => [
    if (_difficultyDistance(source, candidate) > 0) 'dificuldade',
    if (_equipmentFor(source).intersection(_equipmentFor(candidate)).isEmpty)
      'equipamento',
    if (_primaryMuscle(source) != _primaryMuscle(candidate)) 'enfase muscular',
  ];

  ExerciseCollection _collection(
    String id,
    String label,
    List<ExercicioModel> catalog,
    bool Function(ExercicioModel exercise) matches,
  ) => ExerciseCollection(
    id: id,
    label: label,
    exercises: List.unmodifiable(catalog.where(matches)),
  );

  bool _sameExerciseFeatures(
    _ExerciseFeatures first,
    _ExerciseFeatures second,
  ) => first.id == second.id;

  String _idFor(ExercicioModel exercise) => exercise.id.trim().isNotEmpty
      ? exercise.id.trim()
      : ExerciseIdentity.buildExerciseKey(exerciseName: exercise.nome);

  _ExerciseFeatures _featuresFor(ExercicioModel exercise) {
    final muscles = _muscleFeatures(exercise);
    return _ExerciseFeatures(
      id: _idFor(exercise),
      primaryMuscle: muscles.primary,
      muscles: muscles.values,
      equipment: _equipmentFor(exercise),
      difficulty: _difficultyRank(exercise),
      movement: _movementFor(exercise),
    );
  }

  Set<String> _musclesFor(ExercicioModel exercise) =>
      _muscleFeatures(exercise).values;

  _MuscleFeatures _muscleFeatures(ExercicioModel exercise) {
    final muscles = <String>{};
    var primary = '';
    for (final muscle in [
      ...exercise.musculos,
      ...exercise.musculosSecundarios,
    ]) {
      final normalized = ExerciseIdentity.normalizeName(muscle);
      if (normalized.isEmpty) continue;
      if (primary.isEmpty) primary = normalized;
      muscles.add(normalized);
    }
    if (primary.isEmpty) {
      primary = ExerciseIdentity.normalizeName(exercise.categoria);
    }
    return _MuscleFeatures(primary, muscles);
  }

  String _primaryMuscle(ExercicioModel exercise) {
    if (exercise.musculos.isNotEmpty) {
      return ExerciseIdentity.normalizeName(exercise.musculos.first);
    }
    return ExerciseIdentity.normalizeName(exercise.categoria);
  }

  Set<String> _equipmentFor(ExercicioModel exercise) => exercise.equipamentos
      .map(ExerciseIdentity.normalizeName)
      .where((item) => item.isNotEmpty)
      .toSet();

  int _difficultyRank(ExercicioModel exercise) =>
      switch (ExerciseIdentity.normalizeName(exercise.dificuldade)) {
        'iniciante' => 0,
        'intermediario' => 1,
        'avancado' => 2,
        _ => 1,
      };

  int _difficultyDistance(ExercicioModel first, ExercicioModel second) =>
      (_difficultyRank(first) - _difficultyRank(second)).abs();

  String _movementFor(ExercicioModel exercise) {
    final value = [
      exercise.nome,
      exercise.categoria,
      exercise.objetivo,
      ...exercise.musculos,
      ...exercise.musculosSecundarios,
      ...exercise.tags,
    ].join(' ').toLowerCase();
    final detected = _detectMovement(value);
    if (detected != 'other') return detected;
    return _detectMovement(ExerciseIdentity.normalizeName(value));
  }

  String _detectMovement(String value) {
    if (_pushPattern.hasMatch(value)) {
      return 'push';
    }
    if (_pullPattern.hasMatch(value)) {
      return 'pull';
    }
    if (_squatPattern.hasMatch(value)) {
      return 'squat';
    }
    if (_hingePattern.hasMatch(value)) {
      return 'hinge';
    }
    if (_isolationPattern.hasMatch(value)) {
      return 'isolation';
    }
    if (_fullBodyPattern.hasMatch(value)) {
      return 'full-body';
    }
    return 'other';
  }

  bool _hasEquipment(ExercicioModel exercise, String value) => _equipmentFor(
    exercise,
  ).any((item) => item.contains(ExerciseIdentity.normalizeName(value)));

  bool _hasText(ExercicioModel exercise, String value) =>
      _textFor(exercise).contains(ExerciseIdentity.normalizeName(value));

  String _textFor(ExercicioModel exercise) => ExerciseIdentity.normalizeName(
    [
      exercise.nome,
      exercise.categoria,
      exercise.objetivo,
      ...exercise.musculos,
      ...exercise.musculosSecundarios,
      ...exercise.equipamentos,
      ...exercise.tags,
    ].join(' '),
  );
}

class _IndexedRecommendation {
  const _IndexedRecommendation(this.index, this.recommendation);

  final int index;
  final ExerciseRecommendation recommendation;
}

class _IndexedExercise {
  const _IndexedExercise(this.index, this.exercise, this.score);

  final int index;
  final ExercicioModel exercise;
  final int score;
}

class _ExerciseFeatures {
  const _ExerciseFeatures({
    required this.id,
    required this.primaryMuscle,
    required this.muscles,
    required this.equipment,
    required this.difficulty,
    required this.movement,
  });

  final String id;
  final String primaryMuscle;
  final Set<String> muscles;
  final Set<String> equipment;
  final int difficulty;
  final String movement;
}

class _MuscleFeatures {
  const _MuscleFeatures(this.primary, this.values);

  final String primary;
  final Set<String> values;
}
