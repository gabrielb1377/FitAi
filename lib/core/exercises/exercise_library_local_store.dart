import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_identity.dart';
import 'exercise_library_intelligence.dart';

/// Personal Library data stored locally and available without a connection.
class ExerciseLibraryLocalState {
  const ExerciseLibraryLocalState({
    this.favoriteIds = const [],
    this.recentIds = const [],
    this.usageScoreById = const {},
  });

  final List<String> favoriteIds;
  final List<String> recentIds;
  final Map<String, int> usageScoreById;

  ExerciseLibraryLocalState copyWith({
    List<String>? favoriteIds,
    List<String>? recentIds,
    Map<String, int>? usageScoreById,
  }) => ExerciseLibraryLocalState(
    favoriteIds: favoriteIds ?? this.favoriteIds,
    recentIds: recentIds ?? this.recentIds,
    usageScoreById: usageScoreById ?? this.usageScoreById,
  );

  Map<String, Object> toJson() => {
    'version': 1,
    'favoriteIds': favoriteIds,
    'recentIds': recentIds,
    'usageScoreById': usageScoreById,
  };

  factory ExerciseLibraryLocalState.fromJson(Map<String, dynamic> json) {
    final rawUsage = json['usageScoreById'];
    final usage = <String, int>{};
    if (rawUsage is Map) {
      for (final entry in rawUsage.entries) {
        final value = entry.value;
        final parsed = value is int ? value : int.tryParse(value.toString());
        if (parsed != null && parsed > 0) usage[entry.key.toString()] = parsed;
      }
    }
    return ExerciseLibraryLocalState(
      favoriteIds: _uniqueIds(json['favoriteIds']),
      recentIds: _uniqueIds(json['recentIds']).take(20).toList(growable: false),
      usageScoreById: usage,
    );
  }

  static List<String> _uniqueIds(Object? value) {
    if (value is! List) return const [];
    final ids = <String>[];
    for (final raw in value) {
      final id = raw.toString().trim();
      if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }
}

abstract interface class ExerciseLibraryLocalStore {
  Future<ExerciseLibraryLocalState> load();

  Future<ExerciseLibraryLocalState> toggleFavorite(String exerciseId);

  Future<ExerciseLibraryLocalState> recordUse(
    String exerciseId,
    ExerciseUsageEvent event,
  );

  Future<ExerciseLibraryLocalState> clearRecents();
}

/// Single SharedPreferences record for user-owned library state.
///
/// The legacy favorite and recent keys are migrated and mirrored so older
/// screens remain compatible while the Library moves to the canonical store.
class SharedPreferencesExerciseLibraryLocalStore
    implements ExerciseLibraryLocalStore {
  SharedPreferencesExerciseLibraryLocalStore({
    Future<SharedPreferences> Function()? preferencesLoader,
    this.userScope = anonymousScope,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const anonymousScope = 'anonymous';
  static const _legacyFavoriteKey = 'favoritosExercicios';
  static const _legacyRecentKey = 'fitai_exercicios_recentemente_visualizados';
  static const _storagePrefix = 'fitai.exerciseLibrary.local.v1';
  static const _recentLimit = 20;

  final Future<SharedPreferences> Function() _preferencesLoader;
  final String userScope;

  String get storageKey => '$_storagePrefix.${_normalizeScope(userScope)}';

  @override
  Future<ExerciseLibraryLocalState> load() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(storageKey);
    final decoded = _decode(raw);
    final invalidCache = raw != null && raw.isNotEmpty && decoded == null;
    if (invalidCache) {
      await preferences.remove(storageKey);
    }
    final current = decoded ?? const ExerciseLibraryLocalState();
    final legacyFavorites =
        preferences.getStringList(_legacyFavoriteKey) ?? const <String>[];
    final legacyRecents =
        preferences.getStringList(_legacyRecentKey) ?? const <String>[];
    final merged = ExerciseLibraryLocalState(
      favoriteIds: _mergeIds(current.favoriteIds, legacyFavorites),
      recentIds: _mergeIds(
        current.recentIds,
        legacyRecents,
      ).take(_recentLimit).toList(growable: false),
      usageScoreById: current.usageScoreById,
    );
    if (invalidCache ||
        !_sameState(current, merged) ||
        preferences.getString(storageKey) == null) {
      await _write(preferences, merged);
    }
    return merged;
  }

  @override
  Future<ExerciseLibraryLocalState> toggleFavorite(String exerciseId) async {
    final id = _canonicalId(exerciseId);
    if (id.isEmpty) throw ArgumentError.value(exerciseId, 'exerciseId');
    final preferences = await _preferencesLoader();
    final current = await load();
    final favorites = List<String>.from(current.favoriteIds);
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.insert(0, id);
    }
    final updated = current.copyWith(favoriteIds: favorites);
    await _write(preferences, updated);
    return updated;
  }

  @override
  Future<ExerciseLibraryLocalState> recordUse(
    String exerciseId,
    ExerciseUsageEvent event,
  ) async {
    final id = _canonicalId(exerciseId);
    if (id.isEmpty) throw ArgumentError.value(exerciseId, 'exerciseId');
    final preferences = await _preferencesLoader();
    final current = await load();
    final recent = <String>[
      id,
      ...current.recentIds.where((item) => item != id),
    ].take(_recentLimit).toList(growable: false);
    final usage = Map<String, int>.from(current.usageScoreById);
    usage[id] = (usage[id] ?? 0) + event.weight;
    final updated = current.copyWith(recentIds: recent, usageScoreById: usage);
    await _write(preferences, updated);
    return updated;
  }

  @override
  Future<ExerciseLibraryLocalState> clearRecents() async {
    final preferences = await _preferencesLoader();
    final current = await load();
    final updated = current.copyWith(recentIds: const []);
    await _write(preferences, updated);
    return updated;
  }

  ExerciseLibraryLocalState? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return ExerciseLibraryLocalState.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } on FormatException {
      // This cache is isolated from all other application data. It is safe to reset.
    }
    return null;
  }

  Future<void> _write(
    SharedPreferences preferences,
    ExerciseLibraryLocalState state,
  ) async {
    final localSaved = await preferences.setString(
      storageKey,
      jsonEncode(state.toJson()),
    );
    if (!localSaved) {
      throw StateError('Nao foi possivel salvar a Biblioteca local.');
    }

    // Compatibility bridge while legacy exercise screens still use these keys.
    final favoritesSaved = await preferences.setStringList(
      _legacyFavoriteKey,
      state.favoriteIds,
    );
    final recentsSaved = await preferences.setStringList(
      _legacyRecentKey,
      state.recentIds,
    );
    if (!favoritesSaved || !recentsSaved) {
      throw StateError('Nao foi possivel confirmar a Biblioteca local.');
    }
  }

  static List<String> _mergeIds(
    Iterable<String> preferred,
    Iterable<String> fallback,
  ) {
    final result = <String>[];
    for (final raw in [...preferred, ...fallback]) {
      final id = _canonicalId(raw);
      if (id.isNotEmpty && !result.contains(id)) result.add(id);
    }
    return result;
  }

  static bool _sameState(
    ExerciseLibraryLocalState first,
    ExerciseLibraryLocalState second,
  ) =>
      _sameList(first.favoriteIds, second.favoriteIds) &&
      _sameList(first.recentIds, second.recentIds) &&
      _sameMap(first.usageScoreById, second.usageScoreById);

  static bool _sameList(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  static bool _sameMap(Map<String, int> first, Map<String, int> second) {
    if (first.length != second.length) return false;
    for (final entry in first.entries) {
      if (second[entry.key] != entry.value) return false;
    }
    return true;
  }

  static String _canonicalId(String value) {
    final raw = value.trim();
    return raw.isEmpty ? '' : raw;
  }

  static String _normalizeScope(String value) {
    final normalized = ExerciseIdentity.normalizeName(
      value,
    ).replaceAll(' ', '_');
    return normalized.isEmpty ? anonymousScope : normalized;
  }
}
