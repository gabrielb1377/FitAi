import 'dart:convert';

import '../../../core/exercises/exercise_catalog_binding.dart';
import '../../../core/exercises/exercise_catalog_identity.dart';
import '../../../data/exercicios/exercicios.dart';

/// Adapts the existing relational API DTO without inventing missing plan data.
/// Catalog identity is verified; occurrence IDs and day ordering stay remote.
abstract final class RemotePlanMapper {
  static final _identity = ExerciseCatalogIdentity(bancoExercicios);
  static final _binder = ExerciseCatalogBinder(bancoExercicios);

  static Map<String, dynamic> map(Map<String, dynamic> dto, String owner) {
    if (dto['userId'] != owner ||
        dto['id'] is! String ||
        dto['deletedAt'] != null) {
      throw StateError('Invalid remote plan ownership or lifecycle.');
    }
    final days = <Map<String, dynamic>>[];
    final exercises = <String, Map<String, dynamic>>{};
    for (final rawDay in dto['days'] as List? ?? const []) {
      final day = Map<String, dynamic>.from(rawDay as Map);
      final ids = <String>[];
      for (final rawItem in day['exercises'] as List? ?? const []) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final exercise = Map<String, dynamic>.from(item['exercise'] as Map);
        final id = exercise['id'] as String;
        final resolution = _identity.resolve(exerciseId: id);
        final binding = _binder.bindTemplate(
          templateItemId: id,
          remoteExerciseId: id,
          exerciseName: exercise['name'] as String,
          canonicalExerciseId: resolution?.entry.canonicalId ?? '',
        );
        if (!binding.isResolved) {
          throw StateError('Unresolved remote exercise identity.');
        }
        final snapshot = binding.entry!.exercise
            .copyWith(
              id: id,
              canonicalExerciseId: binding.canonicalExerciseId,
              canonicalName: binding.canonicalName,
              remoteExerciseId: id,
              series: item['sets'] as int,
              repeticoes: (item['repsText'] ?? item['reps']).toString(),
              descansoSegundos: item['restSeconds'] as int,
              rir: item['rir'] as String? ?? '',
              cadencia: item['cadence'] as String? ?? '',
              observacoesTreino: item['notes'] as String? ?? '',
            )
            .toJson();
        // TreinoModel has one prescription per occurrence, shared across days.
        // Different prescriptions must not silently collapse into one.
        final previous = exercises[id];
        if (previous != null && jsonEncode(previous) != jsonEncode(snapshot)) {
          throw StateError('Conflicting remote occurrence prescriptions.');
        }
        exercises[id] = snapshot;
        ids.add(id);
      }
      days.add({
        'codigo': day['name'],
        'nome': day['muscleGroup'],
        'ordem': day['order'],
        'exercicioIds': ids,
      });
    }
    return {
      'id': dto['id'],
      'nome': dto['name'],
      'descricao': dto['description'],
      'objetivo': dto['goal'],
      'nivel': dto['level'],
      'divisao': dto['split'],
      'tempoEstimado': dto['estimatedMinutes'],
      'diasPorSemana': dto['daysPerWeek'],
      'origem': dto['source'],
      'criadoPorIA': dto['source'] == 'ia',
      'readyPlanId': dto['readyPlanId'],
      'dataCriacao': dto['createdAt'],
      'planoDias': days,
      'exercicios': exercises.values.toList(),
      '_remoteUpdatedAt': dto['updatedAt'],
    };
  }
}
