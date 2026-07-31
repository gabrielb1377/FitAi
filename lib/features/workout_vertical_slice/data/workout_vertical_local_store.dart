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
  SharedPreferencesWorkoutVerticalLocalStore(
    this._preferences, {
    String userScope = anonymousScope,
  }) : _userScope = _normalizeScope(userScope);

  /// Chave legada mantida para compatibilidade com o harness tecnico anonimo.
  static const storageKey = 'fitai.workoutVerticalSlice.v1';
  static const anonymousScope = 'anonymous';

  final SharedPreferences _preferences;
  final String _userScope;

  /// Snapshots autenticados nunca compartilham a mesma chave. Assim um logout
  /// preserva os dados locais do usuario anterior sem expo-los ao proximo.
  static String storageKeyFor(String userScope) {
    final normalized = _normalizeScope(userScope);
    return normalized == anonymousScope
        ? storageKey
        : '$storageKey.user.$normalized';
  }

  String get scopedStorageKey => storageKeyFor(_userScope);

  @override
  Future<WorkoutSliceSnapshot> read() async {
    final serialized = _preferences.getString(scopedStorageKey);
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
      scopedStorageKey,
      jsonEncode(snapshot.toJson()),
    );
    if (!persisted) {
      throw StateError('Nao foi possivel salvar o treino no dispositivo.');
    }
  }

  static String _normalizeScope(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return anonymousScope;
    return normalized.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }
}
