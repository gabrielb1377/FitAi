import 'package:flutter/foundation.dart';

import '../../domain/activity_history_models.dart';
import '../../../workout_vertical_slice/domain/workout_vertical_models.dart';

typedef ActivitiesHistoryLoader =
    Future<WorkoutActivityHistorySnapshot> Function();

/// Estado de apresentacao para consultar a projecao canônica do historico.
///
/// Nao persiste e nao transforma eventos do treino: filtros e busca sao
/// aplicados apenas sobre o snapshot produzido por [WorkoutHistoryRepository].
class ActivitiesHistoryController extends ChangeNotifier {
  ActivitiesHistoryController({
    required this.loadHistory,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ActivitiesHistoryLoader loadHistory;
  final DateTime Function() _clock;

  WorkoutActivityHistorySnapshot snapshot =
      const WorkoutActivityHistorySnapshot.empty();
  bool isLoading = true;
  String? errorMessage;
  String query = '';
  ActivityHistoryPeriod period = ActivityHistoryPeriod.last30Days;
  String? planId;
  String? muscle;
  String? category;
  bool onlyOffline = false;
  bool onlyPersonalRecords = false;
  bool _disposed = false;
  Future<void>? _activeRefresh;

  bool get hasData => snapshot.workouts.isNotEmpty;

  bool get isShowingCachedOfflineData => filteredWorkouts.any(
    (workout) => workout.syncStatus != WorkoutSyncStatus.synced,
  );

  List<WorkoutHistory> get filteredWorkouts {
    final normalizedQuery = _normalize(query);
    final cutoff = period.cutoff(_clock());
    final personalRecordSessions = snapshot.personalRecords
        .map((record) => record.sessionId)
        .toSet();

    return snapshot.workouts
        .where((workout) {
          if (cutoff != null && workout.finishedAt.isBefore(cutoff)) {
            return false;
          }
          if (planId != null && workout.planId != planId) return false;
          if (onlyOffline && workout.syncStatus == WorkoutSyncStatus.synced) {
            return false;
          }
          if (onlyPersonalRecords &&
              !personalRecordSessions.contains(workout.id)) {
            return false;
          }
          if (muscle != null &&
              !workout.exercises.any(
                (exercise) => exercise.muscles.any(
                  (value) => _normalize(value) == _normalize(muscle!),
                ),
              )) {
            return false;
          }
          if (category != null &&
              !workout.exercises.any(
                (exercise) =>
                    _normalize(exercise.category ?? '') ==
                    _normalize(category!),
              )) {
            return false;
          }
          if (normalizedQuery.isEmpty) return true;
          final searchTarget = [
            workout.workoutName,
            workout.planName,
            ...workout.exercises.map((exercise) => exercise.name),
            ...workout.exercises.expand((exercise) => exercise.muscles),
            ...workout.exercises.map((exercise) => exercise.category ?? ''),
            _formatDateForSearch(workout.finishedAt),
          ].join(' ');
          return _normalize(searchTarget).contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<String> get availablePlans =>
      snapshot.workouts
          .map((workout) => workout.planName?.trim())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();

  List<String> get availableMuscles =>
      snapshot.workouts
          .expand((workout) => workout.exercises)
          .expand((exercise) => exercise.muscles)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();

  List<String> get availableCategories =>
      snapshot.workouts
          .expand((workout) => workout.exercises)
          .map((exercise) => exercise.category?.trim())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();

  WorkoutHistory? workoutById(String id) {
    for (final workout in snapshot.workouts) {
      if (workout.id == id) return workout;
    }
    return null;
  }

  /// Coalesces notifications from the journey controller into one local read.
  Future<void> refresh({bool preserveError = false}) {
    if (_disposed) return Future<void>.value();
    final activeRefresh = _activeRefresh;
    if (activeRefresh != null) return activeRefresh;

    final operation = _refreshInternal(preserveError: preserveError);
    _activeRefresh = operation;
    operation.whenComplete(() {
      if (identical(_activeRefresh, operation)) {
        _activeRefresh = null;
      }
    });
    return operation;
  }

  Future<void> _refreshInternal({required bool preserveError}) async {
    isLoading = true;
    if (!preserveError) errorMessage = null;
    notifyListeners();
    try {
      snapshot = await loadHistory();
    } on Object {
      errorMessage = 'Nao foi possivel carregar o historico local.';
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void setQuery(String value) {
    if (query == value) return;
    query = value;
    notifyListeners();
  }

  void setPeriod(ActivityHistoryPeriod value) {
    if (period == value) return;
    period = value;
    notifyListeners();
  }

  void updateFilters({
    String? nextPlanId,
    bool clearPlan = false,
    String? nextMuscle,
    bool clearMuscle = false,
    String? nextCategory,
    bool clearCategory = false,
    bool? nextOnlyOffline,
    bool? nextOnlyPersonalRecords,
  }) {
    planId = clearPlan ? null : nextPlanId ?? planId;
    muscle = clearMuscle ? null : nextMuscle ?? muscle;
    category = clearCategory ? null : nextCategory ?? category;
    onlyOffline = nextOnlyOffline ?? onlyOffline;
    onlyPersonalRecords = nextOnlyPersonalRecords ?? onlyPersonalRecords;
    notifyListeners();
  }

  void clearFilters() {
    period = ActivityHistoryPeriod.last30Days;
    planId = null;
    muscle = null;
    category = null;
    onlyOffline = false;
    onlyPersonalRecords = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static String _normalize(String value) {
    const accents = <String, String>{
      'a': 'a',
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'e': 'e',
      'é': 'e',
      'ê': 'e',
      'i': 'i',
      'í': 'i',
      'o': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'u': 'u',
      'ú': 'u',
      'ç': 'c',
    };
    final lower = value.toLowerCase().trim();
    return lower
        .split('')
        .map((character) => accents[character] ?? character)
        .join();
  }

  static String _formatDateForSearch(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

enum ActivityHistoryPeriod {
  last7Days('7 dias'),
  last30Days('30 dias'),
  all('Tudo');

  const ActivityHistoryPeriod(this.label);

  final String label;

  DateTime? cutoff(DateTime now) => switch (this) {
    ActivityHistoryPeriod.last7Days => now.subtract(const Duration(days: 7)),
    ActivityHistoryPeriod.last30Days => now.subtract(const Duration(days: 30)),
    ActivityHistoryPeriod.all => null,
  };
}
