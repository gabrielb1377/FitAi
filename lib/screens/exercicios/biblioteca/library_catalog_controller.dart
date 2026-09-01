import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/local_account_data_boundary.dart';
import '../../../core/exercises/exercise_catalog_identity.dart';
import '../../../core/exercises/exercise_identity.dart';
import '../../../core/exercises/exercise_library_intelligence.dart';
import '../../../core/exercises/exercise_library_local_store.dart';
import '../../../data/exercicios/exercicios.dart';
import '../../../models/exercicio_model.dart';

typedef LibraryCatalogLoader = Future<List<ExercicioModel>> Function();
typedef LibraryUserScopeResolver = String Function();

enum LibrarySection { home, explore, favorites, recent }

/// Describes the external flow that opened the Library selection mode.
enum LibrarySelectionPurpose { plan, activeWorkoutAdd, activeWorkoutReplace }

enum LibrarySort { all, popular, recent, alphabetical }

enum LibraryLoadStatus { loading, ready, empty, error }

@immutable
class LibraryMuscleGroup {
  const LibraryMuscleGroup({
    required this.label,
    required this.aliases,
    required this.highlight,
  });

  final String label;
  final List<String> aliases;
  final Alignment highlight;
}

@immutable
class LibraryFilterSelection {
  const LibraryFilterSelection({
    this.muscleGroup,
    this.level,
    this.equipment,
    this.category,
    this.movement,
    this.objective,
    this.sort = LibrarySort.all,
  });

  final String? muscleGroup;
  final String? level;
  final String? equipment;
  final String? category;
  final String? movement;
  final String? objective;
  final LibrarySort sort;

  bool get isActive =>
      muscleGroup != null ||
      level != null ||
      equipment != null ||
      category != null ||
      movement != null ||
      objective != null ||
      sort != LibrarySort.all;

  LibraryFilterSelection copyWith({
    Object? muscleGroup = _unset,
    Object? level = _unset,
    Object? equipment = _unset,
    Object? category = _unset,
    Object? movement = _unset,
    Object? objective = _unset,
    LibrarySort? sort,
  }) {
    return LibraryFilterSelection(
      muscleGroup: identical(muscleGroup, _unset)
          ? this.muscleGroup
          : muscleGroup as String?,
      level: identical(level, _unset) ? this.level : level as String?,
      equipment: identical(equipment, _unset)
          ? this.equipment
          : equipment as String?,
      category: identical(category, _unset)
          ? this.category
          : category as String?,
      movement: identical(movement, _unset)
          ? this.movement
          : movement as String?,
      objective: identical(objective, _unset)
          ? this.objective
          : objective as String?,
      sort: sort ?? this.sort,
    );
  }

  static const _unset = Object();
}

class LibraryCatalogController extends ChangeNotifier {
  LibraryCatalogController({
    LibraryCatalogLoader? catalogLoader,
    ExerciseLibraryLocalStore? localStore,
    ExerciseLibraryIntelligence? intelligence,
    LibraryUserScopeResolver? userScopeResolver,
    this.initialCategory,
  }) : _catalogLoader = catalogLoader ?? _loadBundledCatalog,
       _providedLocalStore = localStore,
       _intelligence = intelligence ?? const ExerciseLibraryIntelligence(),
       _userScopeResolver = userScopeResolver ?? _defaultUserScope;

  static const recentStorageKey = 'fitai_exercicios_recentemente_visualizados';

  static const muscleGroups = <LibraryMuscleGroup>[
    LibraryMuscleGroup(
      label: 'Peito',
      aliases: ['Peito', 'Peitoral'],
      highlight: Alignment(0, -0.45),
    ),
    LibraryMuscleGroup(
      label: 'Costas',
      aliases: ['Costas', 'Dorsal', 'Lombar'],
      highlight: Alignment(0, -0.35),
    ),
    LibraryMuscleGroup(
      label: 'Ombros',
      aliases: ['Ombros', 'Deltoide', 'Deltóide'],
      highlight: Alignment(-0.58, -0.5),
    ),
    LibraryMuscleGroup(
      label: 'Quadriceps',
      aliases: ['Pernas', 'Quadriceps', 'Quadríceps', 'Posterior'],
      highlight: Alignment(-0.25, 0.55),
    ),
    LibraryMuscleGroup(
      label: 'Bíceps',
      aliases: ['Biceps', 'Bíceps'],
      highlight: Alignment(-0.7, -0.12),
    ),
    LibraryMuscleGroup(
      label: 'Tríceps',
      aliases: ['Triceps', 'Tríceps'],
      highlight: Alignment(0.7, -0.12),
    ),
    LibraryMuscleGroup(
      label: 'Core',
      aliases: ['Abdomen', 'Abdômen', 'Core'],
      highlight: Alignment(0, 0.05),
    ),
    LibraryMuscleGroup(
      label: 'Panturrilhas',
      aliases: ['Panturrilha', 'Panturrilhas'],
      highlight: Alignment(0.28, 0.82),
    ),
    LibraryMuscleGroup(
      label: 'Posterior',
      aliases: ['Posterior', 'Posteriores', 'Isquiotibiais'],
      highlight: Alignment(0.25, 0.55),
    ),
    LibraryMuscleGroup(
      label: 'Gluteos',
      aliases: ['Gluteos', 'Glúteos'],
      highlight: Alignment(0, 0.47),
    ),
    LibraryMuscleGroup(
      label: 'Corpo inteiro',
      aliases: ['Corpo inteiro', 'Full body', 'Geral'],
      highlight: Alignment(0, 0),
    ),
  ];

  static const levels = ['Iniciante', 'Intermediário', 'Avançado'];
  static const equipment = [
    'Livre',
    'Máquina',
    'Halteres',
    'Cabo',
    'Corpo Livre',
    'Elástico',
  ];

  static const categories = [
    'Força',
    'Cardio',
    'Mobilidade',
    'Aquecimento',
    'Alongamento',
  ];

  static const movements = ['Empurrar', 'Puxar', 'Agachar', 'Hinge', 'Isolado'];

  static const objectives = [
    'Hipertrofia',
    'Força',
    'Condicionamento',
    'Mobilidade',
  ];

  static final _freeEquipmentPattern = RegExp(r'barra|anilha|banco|livre');
  static final _machineEquipmentPattern = RegExp(r'maquina|smith|leg press');
  static final _cableEquipmentPattern = RegExp(r'cabo|polia');
  static final _bodyweightEquipmentPattern = RegExp(r'corpo|peso corporal');
  static final _elasticEquipmentPattern = RegExp(r'elastico|faixa|band');
  static final _pushMovementPattern = RegExp(
    r'supino|flexao|desenvolvimento|press',
  );
  static final _pullMovementPattern = RegExp(r'remada|puxada|barra fixa|pull');
  static final _squatMovementPattern = RegExp(r'agachamento|afundo|leg press');
  static final _hingeMovementPattern = RegExp(
    r'terra|stiff|romeno|good morning',
  );
  static final _isolationMovementPattern = RegExp(
    r'rosca|extensora|flexora|elevacao|triceps',
  );

  final LibraryCatalogLoader _catalogLoader;
  final ExerciseLibraryLocalStore? _providedLocalStore;
  final ExerciseLibraryIntelligence _intelligence;
  final LibraryUserScopeResolver _userScopeResolver;
  final String? initialCategory;

  ExerciseLibraryLocalStore? _localStore;
  String? _localStoreScope;
  ExerciseCatalogIdentity? _catalogIdentity;
  List<ExercicioModel> _exercises = const [];
  Map<String, _LibrarySearchIndex> _searchIndex = const {};
  final Map<String, List<ExercicioModel>> _visibleExercisesCache = {};
  Set<String> _favoriteIds = const {};
  List<String> _recentIds = const [];
  Map<String, int> _usageScoreById = const {};
  String _query = '';
  LibraryFilterSelection _filters = const LibraryFilterSelection();
  LibrarySection _section = LibrarySection.home;
  LibraryLoadStatus _status = LibraryLoadStatus.loading;
  Object? _error;

  List<ExercicioModel> get exercises => List.unmodifiable(_exercises);
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<String> get recentIds => List.unmodifiable(_recentIds);
  Map<String, int> get usageScoreById => Map.unmodifiable(_usageScoreById);
  String get query => _query;
  LibraryFilterSelection get filters => _filters;
  LibrarySection get section => _section;
  LibraryLoadStatus get status => _status;
  Object? get error => _error;
  bool get isOfflineReady => _status == LibraryLoadStatus.ready;

  int get activeFilterCount => [
    _filters.muscleGroup,
    _filters.level,
    _filters.equipment,
    _filters.category,
    _filters.movement,
    _filters.objective,
  ].whereType<String>().length;

  Future<void> initialize() async {
    _status = LibraryLoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _exercises = List<ExercicioModel>.from(await _catalogLoader());
      _catalogIdentity = ExerciseCatalogIdentity(_exercises);
      _searchIndex = _buildSearchIndex(_exercises);
      _visibleExercisesCache.clear();
      if (_exercises.isEmpty) {
        _status = LibraryLoadStatus.empty;
        notifyListeners();
        return;
      }

      await _loadLocalState();
      if (initialCategory?.trim().isNotEmpty ?? false) {
        _filters = _filters.copyWith(muscleGroup: initialCategory!.trim());
        _section = LibrarySection.explore;
      }
      _status = LibraryLoadStatus.ready;
    } catch (error, stackTrace) {
      _error = error;
      _status = LibraryLoadStatus.error;
      _debugLog('falha ao carregar catálogo', error, stackTrace);
    }
    notifyListeners();
  }

  Future<void> retry() => initialize();

  void showHome() {
    _section = LibrarySection.home;
    _query = '';
    _filters = const LibraryFilterSelection();
    notifyListeners();
  }

  void showExplore({String? muscleGroup}) {
    _section = LibrarySection.explore;
    if (muscleGroup != null) {
      _filters = _filters.copyWith(muscleGroup: muscleGroup);
    }
    notifyListeners();
  }

  void showFavorites() {
    _section = LibrarySection.favorites;
    _query = '';
    notifyListeners();
  }

  void showRecent() {
    _section = LibrarySection.recent;
    _query = '';
    notifyListeners();
  }

  void updateQuery(String value) {
    _query = value.trim();
    if (_section == LibrarySection.home && _query.isNotEmpty) {
      _section = LibrarySection.explore;
    }
    notifyListeners();
  }

  void clearQuery() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  void applyFilters(LibraryFilterSelection value) {
    _filters = value;
    _section = LibrarySection.explore;
    notifyListeners();
  }

  void clearFilters() {
    _filters = const LibraryFilterSelection();
    notifyListeners();
  }

  void setExploreSort(LibrarySort sort) {
    _filters = _filters.copyWith(sort: sort);
    notifyListeners();
  }

  bool isFavorite(ExercicioModel exercise) =>
      _favoriteIds.contains(exercise.id);

  Future<bool> toggleFavorite(ExercicioModel exercise) async {
    await _ensureLocalStore();
    final state = await _store().toggleFavorite(_idFor(exercise));
    _applyLocalState(state);
    final favorite = _favoriteIds.contains(_idFor(exercise));
    notifyListeners();
    return favorite;
  }

  Future<void> registerViewed(ExercicioModel exercise) =>
      registerUse(exercise, ExerciseUsageEvent.viewed);

  Future<void> registerUse(
    ExercicioModel exercise,
    ExerciseUsageEvent event,
  ) async {
    await _ensureLocalStore();
    final state = await _store().recordUse(_idFor(exercise), event);
    _applyLocalState(state);
    notifyListeners();
  }

  Future<void> clearRecents() async {
    await _ensureLocalStore();
    final state = await _store().clearRecents();
    _applyLocalState(state);
    notifyListeners();
  }

  List<ExercicioModel> get featuredExercises {
    final result = <ExercicioModel>[];
    for (final preferred in ['peito_001', 'pernas_001']) {
      final match = _exercises.where((item) => item.id == preferred);
      if (match.isNotEmpty) result.add(match.first);
    }
    for (final exercise in _exercises) {
      if (result.length >= 2) break;
      if (!result.contains(exercise)) result.add(exercise);
    }
    return result.take(2).toList(growable: false);
  }

  List<ExercicioModel> get recentExercises {
    final byId = <String, ExercicioModel>{
      for (final exercise in _exercises) ...{
        _idFor(exercise): exercise,
        exercise.nome.trim(): exercise,
      },
    };
    return _recentIds
        .map((id) => byId[id])
        .whereType<ExercicioModel>()
        .toList(growable: false);
  }

  List<ExercicioModel> relatedExercises(ExercicioModel exercise) {
    return relatedRecommendations(
      exercise,
    ).map((item) => item.exercise).toList(growable: false);
  }

  List<ExerciseRecommendation> relatedRecommendations(
    ExercicioModel exercise,
  ) => _intelligence.related(exercise: exercise, catalog: _exercises);

  List<ExerciseSubstitution> substitutionsFor(ExercicioModel exercise) =>
      _intelligence.substitutions(exercise: exercise, catalog: _exercises);

  ExerciseComparison compareExercises(
    ExercicioModel first,
    ExercicioModel second,
  ) => _intelligence.compare(first, second);

  List<ExerciseCollection> get collections =>
      _intelligence.collections(_exercises);

  List<ExercicioModel> get mostUsedExercises => _intelligence.mostUsed(
    catalog: _exercises,
    usageScoreById: _usageScoreById,
  );

  int countForFilters(LibraryFilterSelection filters) =>
      _filteredExercises(filters: filters, query: _query).length;

  int countForMuscleGroup(String group) {
    final aliases = _normalizedGroupAliases(group);
    return _exercises
        .where((exercise) => _matchesGroup(_indexFor(exercise), aliases))
        .length;
  }

  List<ExercicioModel> get visibleExercises {
    final cacheKey = _visibleExercisesCacheKey();
    final cached = _visibleExercisesCache[cacheKey];
    if (cached != null) return cached;

    final favoriteOnly = _section == LibrarySection.favorites;
    final recentOnly = _section == LibrarySection.recent;
    final result = <ExercicioModel>[];
    for (final exercise in _filteredExercises(
      filters: _filters,
      query: _query,
    )) {
      if (favoriteOnly && !_favoriteIds.contains(_idFor(exercise))) continue;
      if (recentOnly && !_recentIds.contains(_idFor(exercise))) continue;
      result.add(exercise);
    }

    switch (_filters.sort) {
      case LibrarySort.alphabetical:
        result.sort((a, b) => a.nome.compareTo(b.nome));
        break;
      case LibrarySort.popular:
        result.sort((a, b) {
          final usage = (_usageScoreById[_idFor(b)] ?? 0).compareTo(
            _usageScoreById[_idFor(a)] ?? 0,
          );
          return usage != 0 ? usage : a.nome.compareTo(b.nome);
        });
        break;
      case LibrarySort.recent:
        result.sort((a, b) {
          final aIndex = _recentIds.indexOf(_idFor(a));
          final bIndex = _recentIds.indexOf(_idFor(b));
          final aRank = aIndex < 0 ? 1 << 20 : aIndex;
          final bRank = bIndex < 0 ? 1 << 20 : bIndex;
          return aRank.compareTo(bRank);
        });
        break;
      case LibrarySort.all:
        break;
    }
    final resolved = List<ExercicioModel>.unmodifiable(result);
    if (_visibleExercisesCache.length >= 32) {
      _visibleExercisesCache.clear();
    }
    _visibleExercisesCache[cacheKey] = resolved;
    return resolved;
  }

  List<ExercicioModel> _filteredExercises({
    required LibraryFilterSelection filters,
    required String query,
  }) {
    final filterQuery = _filterQuery(filters: filters, query: query);
    final result = <ExercicioModel>[];
    for (final exercise in _exercises) {
      final index = _indexFor(exercise);
      if (!_matchesGroup(index, filterQuery.groupAliases) ||
          !_matchesLevel(index, filterQuery.level) ||
          !_matchesEquipment(index, filterQuery.equipment) ||
          !_matchesCategory(index, filterQuery.category) ||
          !_matchesMovement(index, filterQuery.movement) ||
          !_matchesObjective(index, filterQuery.objective) ||
          !_matchesSearch(index, filterQuery.searchTokens)) {
        continue;
      }
      result.add(exercise);
    }
    return result;
  }

  Future<void> _loadLocalState() async {
    try {
      await _ensureLocalStore();
      _applyLocalState(await _store().load());
    } catch (error, stackTrace) {
      _favoriteIds = const {};
      _recentIds = const [];
      _usageScoreById = const {};
      _debugLog(
        'cache local indisponível; catálogo mantido',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _ensureLocalStore() async {
    if (_providedLocalStore != null) {
      _localStore = _providedLocalStore;
      return;
    }
    final scope = _userScopeResolver().trim();
    if (_localStore != null && _localStoreScope == scope) return;
    _localStore = SharedPreferencesExerciseLibraryLocalStore(
      userScope: scope.isEmpty
          ? SharedPreferencesExerciseLibraryLocalStore.anonymousScope
          : scope,
    );
    _localStoreScope = scope;
  }

  ExerciseLibraryLocalStore _store() {
    final store = _localStore;
    if (store == null) {
      throw StateError('Biblioteca local ainda nao foi inicializada.');
    }
    return store;
  }

  static String _defaultUserScope() =>
      AccountSessionLifecycle.activeUserId ??
      SharedPreferencesExerciseLibraryLocalStore.anonymousScope;

  void _applyLocalState(ExerciseLibraryLocalState state) {
    _favoriteIds = Set<String>.from(state.favoriteIds);
    _recentIds = List<String>.from(state.recentIds);
    _usageScoreById = Map<String, int>.from(state.usageScoreById);
    _visibleExercisesCache.clear();
    for (final exercise in _exercises) {
      exercise.favorito = _favoriteIds.contains(_idFor(exercise));
    }
  }

  String _visibleExercisesCacheKey() => [
    _section.name,
    _query,
    _filters.muscleGroup ?? '',
    _filters.level ?? '',
    _filters.equipment ?? '',
    _filters.category ?? '',
    _filters.movement ?? '',
    _filters.objective ?? '',
    _filters.sort.name,
  ].join('\u0000');

  String _idFor(ExercicioModel exercise) => exercise.id.trim().isNotEmpty
      ? exercise.id.trim()
      : ExerciseIdentity.buildExerciseKey(exerciseName: exercise.nome);

  bool _matchesGroup(
    _LibrarySearchIndex index,
    List<String>? normalizedAliases,
  ) {
    if (normalizedAliases == null || normalizedAliases.isEmpty) return true;
    final text = index.groupText;
    return normalizedAliases.any(text.contains);
  }

  bool _matchesLevel(_LibrarySearchIndex index, String? level) {
    if (level == null) return true;
    return index.difficulty == level;
  }

  bool _matchesEquipment(_LibrarySearchIndex index, String? equipmentFilter) {
    if (equipmentFilter == null) return true;
    final text = index.equipmentText;
    final selected = equipmentFilter;
    return switch (selected) {
      'livre' => _freeEquipmentPattern.hasMatch(text),
      'maquina' => _machineEquipmentPattern.hasMatch(text),
      'halteres' => text.contains('halter'),
      'cabo' => _cableEquipmentPattern.hasMatch(text),
      'corpo livre' => _bodyweightEquipmentPattern.hasMatch(text),
      'elastico' => _elasticEquipmentPattern.hasMatch(text),
      _ => text.contains(selected),
    };
  }

  bool _matchesCategory(_LibrarySearchIndex index, String? category) {
    if (category == null) return true;
    final text = index.categoryText;
    return switch (category) {
      'forca' => !text.contains('cardio') && !text.contains('mobilidade'),
      'cardio' => text.contains('cardio') || text.contains('condicionamento'),
      'mobilidade' => text.contains('mobilidade'),
      'aquecimento' => text.contains('aquecimento'),
      'alongamento' => text.contains('alongamento'),
      final selected => text.contains(selected),
    };
  }

  bool _matchesMovement(_LibrarySearchIndex index, String? movement) {
    if (movement == null) return true;
    final text = index.searchableText;
    return switch (movement) {
      'empurrar' => _pushMovementPattern.hasMatch(text),
      'puxar' => _pullMovementPattern.hasMatch(text),
      'agachar' => _squatMovementPattern.hasMatch(text),
      'hinge' => _hingeMovementPattern.hasMatch(text),
      'isolado' => _isolationMovementPattern.hasMatch(text),
      _ => true,
    };
  }

  bool _matchesObjective(_LibrarySearchIndex index, String? objective) {
    if (objective == null) return true;
    return index.objective == objective;
  }

  bool _matchesSearch(_LibrarySearchIndex index, List<String> tokens) {
    return tokens.every(index.searchableText.contains);
  }

  Iterable<String> _searchTokens(String query) sync* {
    const aliases = <String, List<String>>{
      'bench': ['supino'],
      'press': ['supino'],
      'row': ['remada'],
      'pulldown': ['puxada'],
      'curl': ['rosca'],
      'squat': ['agachamento'],
      'deadlift': ['terra'],
      'dumbbell': ['halter'],
      'barbell': ['barra'],
      'cable': ['cabo'],
    };
    for (final token in query.split(' ').where((item) => item.isNotEmpty)) {
      final singular = token.endsWith('s') && token.length > 3
          ? token.substring(0, token.length - 1)
          : token;
      yield (aliases[token] ?? [singular]).first;
    }
  }

  String _searchableText(ExercicioModel exercise) {
    return normalizeLibraryText(
      [
        exercise.nome,
        exercise.categoria,
        exercise.descricao,
        exercise.dificuldade,
        exercise.objetivo,
        ...exercise.musculos,
        ...exercise.musculosSecundarios,
        ...exercise.equipamentos,
        ...exercise.tags,
        ...?_catalogIdentity?.aliasesFor(exercise),
        ..._exerciseAliases(exercise),
      ].join(' '),
    );
  }

  Map<String, _LibrarySearchIndex> _buildSearchIndex(
    Iterable<ExercicioModel> exercises,
  ) {
    final result = <String, _LibrarySearchIndex>{};
    for (final exercise in exercises) {
      final id = _idFor(exercise);
      result.putIfAbsent(
        id,
        () => _LibrarySearchIndex.fromExercise(
          exercise,
          searchableText: _searchableText(exercise),
        ),
      );
    }
    return result;
  }

  _LibrarySearchIndex _indexFor(ExercicioModel exercise) {
    final id = _idFor(exercise);
    return _searchIndex[id] ??= _LibrarySearchIndex.fromExercise(
      exercise,
      searchableText: _searchableText(exercise),
    );
  }

  _LibraryFilterQuery _filterQuery({
    required LibraryFilterSelection filters,
    required String query,
  }) {
    return _LibraryFilterQuery(
      groupAliases: _normalizedGroupAliases(filters.muscleGroup),
      level: _normalizedValue(filters.level),
      equipment: _normalizedValue(filters.equipment),
      category: _normalizedValue(filters.category),
      movement: _normalizedValue(filters.movement),
      objective: _normalizedValue(filters.objective),
      searchTokens: _searchTokens(
        normalizeLibraryText(query),
      ).toList(growable: false),
    );
  }

  List<String>? _normalizedGroupAliases(String? group) {
    if (group == null || group.trim().isEmpty) return null;
    final selected = muscleGroups.where((item) => item.label == group);
    final aliases = selected.isEmpty ? <String>[group] : selected.first.aliases;
    return aliases.map(normalizeLibraryText).toList(growable: false);
  }

  String? _normalizedValue(String? value) =>
      value == null || value.trim().isEmpty
      ? null
      : normalizeLibraryText(value);

  Iterable<String> _exerciseAliases(ExercicioModel exercise) sync* {
    final name = normalizeLibraryText(exercise.nome);
    if (name.contains('supino')) {
      yield* const ['bench', 'bench press', 'chest press'];
    }
    if (name.contains('remada')) {
      yield* const ['row', 'seated row'];
    }
    if (name.contains('puxada')) {
      yield* const ['pulldown', 'pull down'];
    }
    if (name.contains('rosca')) {
      yield* const ['curl'];
    }
    if (name.contains('agachamento')) {
      yield* const ['squat'];
    }
    if (name.contains('terra')) {
      yield* const ['deadlift'];
    }
    if (name.contains('halter')) {
      yield* const ['dumbbell'];
    }
    if (name.contains('barra')) {
      yield* const ['barbell'];
    }
    if (name.contains('cabo') || name.contains('polia')) {
      yield* const ['cable'];
    }
  }

  static Future<List<ExercicioModel>> _loadBundledCatalog() async =>
      bancoExercicios;

  void _debugLog(String message, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('[Biblioteca] $message: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

@immutable
class _LibrarySearchIndex {
  const _LibrarySearchIndex({
    required this.searchableText,
    required this.groupText,
    required this.equipmentText,
    required this.categoryText,
    required this.difficulty,
    required this.objective,
  });

  factory _LibrarySearchIndex.fromExercise(
    ExercicioModel exercise, {
    required String searchableText,
  }) {
    return _LibrarySearchIndex(
      searchableText: searchableText,
      groupText: normalizeLibraryText(
        [
          exercise.categoria,
          ...exercise.musculos,
          ...exercise.musculosSecundarios,
        ].join(' '),
      ),
      equipmentText: normalizeLibraryText(exercise.equipamentos.join(' ')),
      categoryText: normalizeLibraryText(
        [exercise.categoria, exercise.objetivo, ...exercise.tags].join(' '),
      ),
      difficulty: normalizeLibraryText(exercise.dificuldade),
      objective: normalizeLibraryText(exercise.objetivo),
    );
  }

  final String searchableText;
  final String groupText;
  final String equipmentText;
  final String categoryText;
  final String difficulty;
  final String objective;
}

@immutable
class _LibraryFilterQuery {
  const _LibraryFilterQuery({
    required this.groupAliases,
    required this.level,
    required this.equipment,
    required this.category,
    required this.movement,
    required this.objective,
    required this.searchTokens,
  });

  final List<String>? groupAliases;
  final String? level;
  final String? equipment;
  final String? category;
  final String? movement;
  final String? objective;
  final List<String> searchTokens;
}

String normalizeLibraryText(String value) {
  var normalized = value.toLowerCase().trim();
  const replacements = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  for (final replacement in replacements.entries) {
    normalized = normalized.replaceAll(replacement.key, replacement.value);
  }
  return normalized;
}
