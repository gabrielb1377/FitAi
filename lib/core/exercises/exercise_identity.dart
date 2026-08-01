import '../../models/exercicio_model.dart';

/// Identidade estavel usada para relacionar exercicios entre telas e historicos.
abstract final class ExerciseIdentity {
  static final RegExp _separators = RegExp(r'[_-]+');
  static final RegExp _unsupportedCharacters = RegExp(r'[^a-z0-9 ]+');
  static final RegExp _whitespace = RegExp(r'\s+');

  static String normalizeName(String value) {
    var normalized = value.toLowerCase().trim();
    const replacements = {
      'a': 'a',
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'e': 'e',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'i': 'i',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'o': 'o',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'u': 'u',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'c': 'c',
      'ç': 'c',
    };

    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    return normalized
        .replaceAll(_separators, ' ')
        .replaceAll(_unsupportedCharacters, ' ')
        .replaceAll(_whitespace, ' ')
        .trim();
  }

  static String buildExerciseKey({
    String? exerciseId,
    String? exerciseKey,
    required String exerciseName,
  }) {
    final id = exerciseId?.trim() ?? '';
    if (id.isNotEmpty) return 'id:$id';

    final key = normalizeName(exerciseKey ?? '');
    if (key.isNotEmpty) return 'key:$key';

    final name = normalizeName(exerciseName);
    return name.isEmpty ? 'name:unknown' : 'name:$name';
  }

  static bool matchesExercise({
    required String storedExerciseId,
    required String storedExerciseKey,
    required String storedExerciseName,
    required ExercicioModel exercise,
  }) {
    final exerciseId = exercise.id.trim();
    if (exerciseId.isNotEmpty && storedExerciseId.trim() == exerciseId) {
      return true;
    }

    final seriesKey = buildExerciseKey(
      exerciseId: storedExerciseId,
      exerciseKey: storedExerciseKey,
      exerciseName: storedExerciseName,
    );
    final exerciseKey = buildExerciseKey(
      exerciseId: exercise.id,
      exerciseName: exercise.nome,
    );
    if (seriesKey == exerciseKey) return true;

    return normalizeName(storedExerciseName) == normalizeName(exercise.nome);
  }
}
