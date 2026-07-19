import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/exercicios/exercicios.dart';
import '../../../models/exercicio_model.dart';
import '../../../services/storage_service.dart';

typedef LibraryCatalogLoader = Future<List<ExercicioModel>> Function();

enum LibrarySection { home, explore, favorites }

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
    this.sort = LibrarySort.all,
  });

  final String? muscleGroup;
  final String? level;
  final String? equipment;
  final LibrarySort sort;

  bool get isActive =>
      muscleGroup != null ||
      level != null ||
      equipment != null ||
      sort != LibrarySort.all;

  LibraryFilterSelection copyWith({
    Object? muscleGroup = _unset,
    Object? level = _unset,
    Object? equipment = _unset,
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
      sort: sort ?? this.sort,
    );
  }

  static const _unset = Object();
}

class LibraryCatalogController extends ChangeNotifier {
  LibraryCatalogController({
    LibraryCatalogLoader? catalogLoader,
    this.initialCategory,
  }) : _catalogLoader = catalogLoader ?? _loadBundledCatalog;

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
      label: 'Pernas',
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
      label: 'Abdômen',
      aliases: ['Abdomen', 'Abdômen', 'Core'],
      highlight: Alignment(0, 0.05),
    ),
    LibraryMuscleGroup(
      label: 'Panturrilhas',
      aliases: ['Panturrilha', 'Panturrilhas'],
      highlight: Alignment(0.28, 0.82),
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

  final LibraryCatalogLoader _catalogLoader;
  final String? initialCategory;

  List<ExercicioModel> _exercises = const [];
  Set<String> _favoriteIds = const {};
  List<String> _recentIds = const [];
  String _query = '';
  LibraryFilterSelection _filters = const LibraryFilterSelection();
  LibrarySection _section = LibrarySection.home;
  LibraryLoadStatus _status = LibraryLoadStatus.loading;
  Object? _error;

  List<ExercicioModel> get exercises => List.unmodifiable(_exercises);
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<String> get recentIds => List.unmodifiable(_recentIds);
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
  ].whereType<String>().length;

  Future<void> initialize() async {
    _status = LibraryLoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _exercises = List<ExercicioModel>.from(await _catalogLoader());
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
    final favorite = await StorageService.alternarFavoritoExercicio(
      exercise.id,
    );
    final updated = Set<String>.from(_favoriteIds);
    favorite ? updated.add(exercise.id) : updated.remove(exercise.id);
    _favoriteIds = updated;
    exercise.favorito = favorite;
    notifyListeners();
    return favorite;
  }

  Future<void> registerViewed(ExercicioModel exercise) async {
    final prefs = await SharedPreferences.getInstance();
    final id = exercise.id.trim().isEmpty ? exercise.nome : exercise.id;
    final current = prefs.getStringList(recentStorageKey) ?? const <String>[];
    final updated = <String>[
      id,
      ...current.where((item) => item != id),
    ].take(20).toList(growable: false);
    await prefs.setStringList(recentStorageKey, updated);
    _recentIds = updated;
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

  List<ExercicioModel> get visibleExercises {
    final favoriteOnly = _section == LibrarySection.favorites;
    final normalizedQuery = normalizeLibraryText(_query);
    final result = _exercises
        .where((exercise) {
          if (favoriteOnly && !_favoriteIds.contains(exercise.id)) return false;
          if (!_matchesGroup(exercise, _filters.muscleGroup)) return false;
          if (!_matchesLevel(exercise, _filters.level)) return false;
          if (!_matchesEquipment(exercise, _filters.equipment)) return false;
          if (normalizedQuery.isEmpty) return true;
          return _searchableText(exercise).contains(normalizedQuery);
        })
        .toList(growable: true);

    switch (_filters.sort) {
      case LibrarySort.alphabetical:
        result.sort((a, b) => a.nome.compareTo(b.nome));
      case LibrarySort.recent:
        result.sort((a, b) {
          final aIndex = _recentIds.indexOf(a.id);
          final bIndex = _recentIds.indexOf(b.id);
          final aRank = aIndex < 0 ? 1 << 20 : aIndex;
          final bRank = bIndex < 0 ? 1 << 20 : bIndex;
          return aRank.compareTo(bRank);
        });
      case LibrarySort.all:
      case LibrarySort.popular:
        break;
    }
    return List.unmodifiable(result);
  }

  Future<void> _loadLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = await Future.wait<Object>([
        StorageService.carregarFavoritosExercicios(),
        Future<Object>.value(
          prefs.getStringList(recentStorageKey) ?? const <String>[],
        ),
      ]);
      _favoriteIds = Set<String>.from(values[0] as Set<String>);
      _recentIds = List<String>.from(
        values[1] as List<String>,
      ).take(20).toList();
      for (final exercise in _exercises) {
        exercise.favorito = _favoriteIds.contains(exercise.id);
      }
    } catch (error, stackTrace) {
      _favoriteIds = const {};
      _recentIds = const [];
      _debugLog(
        'cache local indisponível; catálogo mantido',
        error,
        stackTrace,
      );
    }
  }

  bool _matchesGroup(ExercicioModel exercise, String? group) {
    if (group == null || group.trim().isEmpty) return true;
    final selected = muscleGroups.where((item) => item.label == group);
    final aliases = selected.isEmpty ? <String>[group] : selected.first.aliases;
    final text = normalizeLibraryText(
      [
        exercise.categoria,
        ...exercise.musculos,
        ...exercise.musculosSecundarios,
      ].join(' '),
    );
    return aliases.any((alias) => text.contains(normalizeLibraryText(alias)));
  }

  bool _matchesLevel(ExercicioModel exercise, String? level) {
    if (level == null) return true;
    return normalizeLibraryText(exercise.dificuldade) ==
        normalizeLibraryText(level);
  }

  bool _matchesEquipment(ExercicioModel exercise, String? equipmentFilter) {
    if (equipmentFilter == null) return true;
    final text = normalizeLibraryText(exercise.equipamentos.join(' '));
    final selected = normalizeLibraryText(equipmentFilter);
    return switch (selected) {
      'livre' => RegExp(r'barra|anilha|banco|livre').hasMatch(text),
      'maquina' => RegExp(r'maquina|smith|leg press').hasMatch(text),
      'halteres' => text.contains('halter'),
      'cabo' => RegExp(r'cabo|polia').hasMatch(text),
      'corpo livre' => RegExp(r'corpo|peso corporal').hasMatch(text),
      'elastico' => RegExp(r'elastico|faixa|band').hasMatch(text),
      _ => text.contains(selected),
    };
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
      ].join(' '),
    );
  }

  static Future<List<ExercicioModel>> _loadBundledCatalog() async =>
      bancoExercicios;

  void _debugLog(String message, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('[Biblioteca] $message: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
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
