import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/workout_vertical_models.dart';

/// Snapshot unico para que a serie e seu evento de outbox sejam gravados juntos.
abstract interface class WorkoutVerticalLocalStore {
  Future<WorkoutSliceSnapshot> read();
  Future<void> write(WorkoutSliceSnapshot snapshot);
}

class SharedPreferencesWorkoutVerticalLocalStore
    implements WorkoutVerticalLocalStore {
  SharedPreferencesWorkoutVerticalLocalStore(this._preferences);

  static const storageKey = 'fitai.workoutVerticalSlice.v1';

  final SharedPreferences _preferences;

  @override
  Future<WorkoutSliceSnapshot> read() async {
    final serialized = _preferences.getString(storageKey);
    if (serialized == null || serialized.isEmpty) {
      return const WorkoutSliceSnapshot.empty();
    }
    try {
      return WorkoutSliceSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(serialized) as Map),
      );
    } on FormatException catch (error) {
      throw StateError('Dados locais do treino invalidos: ${error.message}');
    }
  }

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    final persisted = await _preferences.setString(
      storageKey,
      jsonEncode(snapshot.toJson()),
    );
    if (!persisted) {
      throw StateError('Nao foi possivel salvar o treino no dispositivo.');
    }
  }
}
