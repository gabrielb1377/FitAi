import '../domain/workout_history_models.dart';
import '../../workout_vertical_slice/data/workout_vertical_local_store.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import '../../../models/historico_serie_treino_model.dart';
import '../../../models/historico_treino_model.dart';

typedef WorkoutExerciseNameResolver = String? Function(String exerciseId);
typedef LegacyWorkoutHistoryLoader =
    Future<List<HistoricoTreinoModel>> Function();
typedef LegacyExerciseHistoryLoader =
    Future<List<HistoricoSerieTreinoModel>> Function();

/// Metadados de catalogo projetados para o historico sem criar uma segunda
/// representacao persistida do exercicio. Os valores continuam pertencendo ao
/// plano/catalogo que originou a serie.
class WorkoutExerciseMetadata {
  const WorkoutExerciseMetadata({
    this.name,
    this.muscles = const [],
    this.category,
  });

  final String? name;
  final List<String> muscles;
  final String? category;
}

typedef WorkoutExerciseMetadataResolver =
    WorkoutExerciseMetadata? Function(String exerciseId);

/// Projeta o historico de musculacao a partir do journal offline-first do
/// treino. Nenhum evento, serie ou historico e copiado para outra base local.
class WorkoutHistoryRepository {
  WorkoutHistoryRepository({
    required this.localStore,
    this.exerciseNameResolver,
    this.exerciseMetadataResolver,
    this.legacyHistoryLoader,
    this.legacyExerciseHistoryLoader,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WorkoutVerticalLocalStore localStore;
  final WorkoutExerciseNameResolver? exerciseNameResolver;
  final WorkoutExerciseMetadataResolver? exerciseMetadataResolver;
  final LegacyWorkoutHistoryLoader? legacyHistoryLoader;
  final LegacyExerciseHistoryLoader? legacyExerciseHistoryLoader;
  final DateTime Function() _clock;

  Future<PlanWorkoutHistorySnapshot> load() async {
    final source = await localStore.read();
    final legacyHistory = await _loadLegacyHistory();
    final legacySets = await _loadLegacySets();
    return _buildSnapshot(
      _mergeWorkouts(
        canonical: _projectCanonicalWorkouts(source),
        legacy: _projectLegacyWorkouts(legacyHistory, legacySets),
      ),
    );
  }

  /// Projecao sincrona do journal canonico, utilizada por testes e por
  /// consumidores que ja possuem o snapshot local. A compatibilidade legada
  /// e aplicada somente em [load], sem gravar uma segunda representacao.
  PlanWorkoutHistorySnapshot project(WorkoutSliceSnapshot source) =>
      _buildSnapshot(_projectCanonicalWorkouts(source));

  List<WorkoutHistory> _projectCanonicalWorkouts(WorkoutSliceSnapshot source) {
    final sessions =
        source.sessions
            .where(
              (session) =>
                  session.status == WorkoutSessionStatus.completed &&
                  session.finishedAt != null,
            )
            .toList()
          ..sort(
            (left, right) => left.finishedAt!.compareTo(right.finishedAt!),
          );
    if (sessions.isEmpty) return const <WorkoutHistory>[];

    final setsBySession = <String, List<WorkoutSetLocal>>{};
    final logicalSetKeys = <String>{};
    for (final set in source.sets) {
      final key = '${set.sessionId}|${set.exerciseId}|${set.setIndex}';
      if (!logicalSetKeys.add(key)) {
        continue;
      }
      setsBySession.putIfAbsent(set.sessionId, () => []).add(set);
    }

    final workouts = <WorkoutHistory>[];
    for (final session in sessions) {
      final sets = [...(setsBySession[session.id] ?? const <WorkoutSetLocal>[])]
        ..sort((left, right) {
          final exercise = left.exerciseId.compareTo(right.exerciseId);
          return exercise != 0
              ? exercise
              : left.setIndex.compareTo(right.setIndex);
        });
      workouts.add(_buildWorkout(session, sets));
    }

    return workouts;
  }

  PlanWorkoutHistorySnapshot _buildSnapshot(List<WorkoutHistory> workouts) {
    if (workouts.isEmpty) return const PlanWorkoutHistorySnapshot.empty();
    final chronological = [...workouts]
      ..sort((left, right) => left.finishedAt.compareTo(right.finishedAt));
    final personalRecords = _personalRecords(chronological);
    final exercisePrs = _exercisePrs(chronological);
    final calendar = _calendar(chronological, personalRecords);
    final streak = _streak(chronological);
    final timeline = _timeline(chronological, personalRecords, streak);
    final newestFirst = chronological.reversed.toList(growable: false);

    return PlanWorkoutHistorySnapshot(
      workouts: newestFirst,
      summaries: newestFirst.map((workout) => workout.summary).toList(),
      exercisePrs: exercisePrs,
      personalRecords: personalRecords.reversed.toList(growable: false),
      timeline: timeline.reversed.toList(growable: false),
      calendar: calendar,
      streak: streak,
    );
  }

  Future<List<HistoricoTreinoModel>> _loadLegacyHistory() async {
    final loader = legacyHistoryLoader;
    if (loader == null) return const [];
    try {
      return await loader();
    } on Object {
      // O journal canônico permanece suficiente quando um cache legado falha.
      return const [];
    }
  }

  Future<List<HistoricoSerieTreinoModel>> _loadLegacySets() async {
    final loader = legacyExerciseHistoryLoader;
    if (loader == null) return const [];
    try {
      return await loader();
    } on Object {
      return const [];
    }
  }

  List<WorkoutHistory> _mergeWorkouts({
    required List<WorkoutHistory> canonical,
    required List<WorkoutHistory> legacy,
  }) {
    final ids = <String>{};
    final merged = <WorkoutHistory>[];
    for (final workout in canonical) {
      if (ids.add(workout.id)) merged.add(workout);
    }
    for (final workout in legacy) {
      // A identidade de sessao e a identidade logica do historico. Quando a
      // mesma sessao existe nos dois formatos, o journal e a unica fonte.
      if (ids.add(workout.id)) merged.add(workout);
    }
    return merged;
  }

  List<WorkoutHistory> _projectLegacyWorkouts(
    List<HistoricoTreinoModel> history,
    List<HistoricoSerieTreinoModel> allSets,
  ) {
    final ids = <String>{};
    final projected = <WorkoutHistory>[];
    for (final item in history) {
      final id = _legacyWorkoutId(item);
      if (!ids.add(id)) continue;
      final sets = allSets
          .where((set) => _belongsToLegacyWorkout(set, item, id))
          .toList(growable: false);
      projected.add(_buildLegacyWorkout(item, id, sets));
    }
    return projected;
  }

  WorkoutHistory _buildLegacyWorkout(
    HistoricoTreinoModel item,
    String id,
    List<HistoricoSerieTreinoModel> sets,
  ) {
    final exercises = _buildLegacyExercises(sets);
    final setCount = item.seriesConcluidas > 0
        ? item.seriesConcluidas
        : sets.length;
    final totalVolume = item.volumeTotal > 0
        ? item.volumeTotal
        : sets.fold<double>(0, (total, set) => total + set.volume);
    final totalLoad = sets.fold<double>(0, (total, set) => total + set.peso);
    final durationSeconds = item.tempoSegundos < 0 ? 0 : item.tempoSegundos;
    return WorkoutHistory(
      id: id,
      planId: 'legacy-history',
      workoutId: item.id.trim().isEmpty ? id : item.id.trim(),
      workoutName: item.nomeTreino,
      startedAt: item.dataHora.subtract(Duration(seconds: durationSeconds)),
      finishedAt: item.dataHora,
      metrics: WorkoutMetrics(
        durationSeconds: durationSeconds,
        totalVolume: totalVolume,
        totalLoad: totalLoad,
        exerciseCount: item.exerciciosConcluidos > 0
            ? item.exerciciosConcluidos
            : exercises.length,
        setCount: setCount,
        totalRepetitions: sets.fold(0, (total, set) => total + set.repeticoes),
      ),
      exercises: exercises,
      syncStatus: WorkoutSyncStatus.local,
      calories: item.caloriasEstimadas > 0
          ? item.caloriasEstimadas.toDouble()
          : null,
    );
  }

  List<ExerciseHistory> _buildLegacyExercises(
    List<HistoricoSerieTreinoModel> sets,
  ) {
    final groups = <String, List<HistoricoSerieTreinoModel>>{};
    final deduplicated = <String>{};
    for (final set in sets) {
      if (!deduplicated.add(set.deduplicationKey)) continue;
      final id = set.exercicioId.trim().isEmpty
          ? 'legacy:${set.chaveExercicio}'
          : set.exercicioId.trim();
      groups.putIfAbsent(id, () => []).add(set);
    }
    return groups.entries
        .map((entry) {
          final ordered = [...entry.value]
            ..sort(
              (left, right) => left.serieNumero.compareTo(right.serieNumero),
            );
          final metadata = exerciseMetadataResolver?.call(entry.key);
          final completed = ordered
              .map(
                (set) => CompletedSet(
                  id: set.id.trim().isEmpty
                      ? '${set.deduplicationKey}:${set.serieNumero}'
                      : set.id,
                  index: set.serieNumero <= 0 ? 0 : set.serieNumero - 1,
                  weight: set.peso,
                  repetitions: set.repeticoes,
                  restSeconds: set.descansoSegundos <= 0
                      ? null
                      : set.descansoSegundos,
                  notes: set.comentario.trim().isEmpty ? null : set.comentario,
                  completedAt: set.dataHora,
                  syncStatus: WorkoutSyncStatus.local,
                ),
              )
              .toList(growable: false);
          final notes = completed
              .map((set) => set.notes)
              .whereType<String>()
              .toSet()
              .toList(growable: false);
          return ExerciseHistory(
            exerciseId: entry.key,
            name: metadata?.name?.trim().isNotEmpty == true
                ? metadata!.name!.trim()
                : ordered.first.nomeExercicio,
            sets: completed,
            volume: completed.fold(0, (total, set) => total + set.volume),
            totalRepetitions: completed.fold(
              0,
              (total, set) => total + set.repetitions,
            ),
            completedAt: completed.last.completedAt,
            muscles: metadata?.muscles ?? const [],
            category: metadata?.category,
            notes: notes.isEmpty ? null : notes,
          );
        })
        .toList(growable: false);
  }

  String _legacyWorkoutId(HistoricoTreinoModel item) {
    final id = item.id.trim();
    if (id.isNotEmpty) return id;
    final name = item.nomeTreino.trim().toLowerCase().replaceAll(' ', '-');
    return 'legacy:${item.dataHora.microsecondsSinceEpoch}:$name';
  }

  bool _belongsToLegacyWorkout(
    HistoricoSerieTreinoModel set,
    HistoricoTreinoModel workout,
    String workoutId,
  ) {
    final sessionId = set.sessaoTreinoId.trim();
    if (sessionId.isNotEmpty) {
      return sessionId == workout.id.trim() || sessionId == workoutId;
    }
    return set.treinoId.trim().isNotEmpty && set.treinoId.trim() == workoutId;
  }

  WorkoutHistory _buildWorkout(
    WorkoutSessionLocal session,
    List<WorkoutSetLocal> sets,
  ) {
    final grouped = <String, List<WorkoutSetLocal>>{};
    for (final set in sets) {
      final identity = set.canonicalExerciseId?.trim();
      final historyExerciseId = identity == null || identity.isEmpty
          ? set.exerciseId
          : identity;
      grouped.putIfAbsent(historyExerciseId, () => []).add(set);
    }
    final exercises = grouped.entries
        .map((entry) => _buildExercise(entry.key, entry.value))
        .toList(growable: false);
    final duration = session.finishedAt!.difference(session.startedAt);
    final totalVolume = sets.fold<double>(
      0,
      (total, set) => total + set.weight * set.reps,
    );
    final totalLoad = sets.fold<double>(0, (total, set) => total + set.weight);
    return WorkoutHistory(
      id: session.id,
      planId: session.planId,
      workoutId: session.workoutId,
      planName: session.planName,
      workoutName: session.workoutName,
      startedAt: session.startedAt,
      finishedAt: session.finishedAt!,
      metrics: WorkoutMetrics(
        durationSeconds: duration.isNegative ? 0 : duration.inSeconds,
        totalVolume: totalVolume,
        totalLoad: totalLoad,
        exerciseCount: exercises.length,
        setCount: sets.length,
        totalRepetitions: sets.fold(0, (total, set) => total + set.reps),
      ),
      exercises: exercises,
      syncStatus: session.syncStatus,
      calories: session.calories,
    );
  }

  ExerciseHistory _buildExercise(
    String exerciseId,
    List<WorkoutSetLocal> sets,
  ) {
    final ordered = [...sets]
      ..sort((left, right) => left.setIndex.compareTo(right.setIndex));
    final completed = ordered
        .map(
          (set) => CompletedSet(
            id: set.id,
            index: set.setIndex,
            weight: set.weight,
            repetitions: set.reps,
            restSeconds: set.restSeconds,
            rpe: set.rpe,
            notes: set.notes,
            completedAt: set.completedAt,
            syncStatus: set.syncStatus,
          ),
        )
        .toList(growable: false);
    final rpes = completed
        .map((set) => set.rpe)
        .whereType<double>()
        .toList(growable: false);
    final notes = completed
        .map((set) => set.notes?.trim())
        .whereType<String>()
        .where((note) => note.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final metadata = exerciseMetadataResolver?.call(exerciseId);
    return ExerciseHistory(
      exerciseId: exerciseId,
      name: metadata?.name?.trim().isNotEmpty == true
          ? metadata!.name!.trim()
          : _exerciseName(ordered.first),
      sets: completed,
      volume: completed.fold(0, (total, set) => total + set.volume),
      totalRepetitions: completed.fold(
        0,
        (total, set) => total + set.repetitions,
      ),
      completedAt: completed.last.completedAt,
      muscles:
          metadata?.muscles
              .map((muscle) => muscle.trim())
              .where((muscle) => muscle.isNotEmpty)
              .toSet()
              .toList(growable: false) ??
          const [],
      category: metadata?.category?.trim().isNotEmpty == true
          ? metadata!.category!.trim()
          : null,
      averageRpe: rpes.isEmpty
          ? null
          : rpes.reduce((left, right) => left + right) / rpes.length,
      notes: notes.isEmpty ? null : notes,
    );
  }

  List<PersonalRecord> _personalRecords(List<WorkoutHistory> workouts) {
    final records = <PersonalRecord>[];
    final bestLoad = <String, double>{};
    final bestVolume = <String, double>{};
    final bestOneRepMax = <String, double>{};
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        _addRecordIfImproved(
          records: records,
          bestByExercise: bestLoad,
          exercise: exercise,
          sessionId: workout.id,
          type: PersonalRecordType.exerciseLoad,
          value: exercise.highestLoad,
          unit: 'kg',
          title: 'Maior carga em ${exercise.name}',
        );
        _addRecordIfImproved(
          records: records,
          bestByExercise: bestVolume,
          exercise: exercise,
          sessionId: workout.id,
          type: PersonalRecordType.exerciseVolume,
          value: exercise.volume,
          unit: 'kg',
          title: 'Maior volume em ${exercise.name}',
        );
        _addRecordIfImproved(
          records: records,
          bestByExercise: bestOneRepMax,
          exercise: exercise,
          sessionId: workout.id,
          type: PersonalRecordType.estimatedOneRepMax,
          value: exercise.estimatedOneRepMax,
          unit: 'kg',
          title: '1RM estimado em ${exercise.name}',
        );
      }
    }
    return records;
  }

  void _addRecordIfImproved({
    required List<PersonalRecord> records,
    required Map<String, double> bestByExercise,
    required ExerciseHistory exercise,
    required String sessionId,
    required PersonalRecordType type,
    required double value,
    required String unit,
    required String title,
  }) {
    if (value <= 0 || value <= (bestByExercise[exercise.exerciseId] ?? 0)) {
      return;
    }
    bestByExercise[exercise.exerciseId] = value;
    records.add(
      PersonalRecord(
        id: 'pr:$sessionId:${exercise.exerciseId}:${type.name}',
        type: type,
        title: title,
        value: value,
        unit: unit,
        achievedAt: exercise.completedAt,
        sessionId: sessionId,
        exerciseId: exercise.exerciseId,
      ),
    );
  }

  List<ExercisePR> _exercisePrs(List<WorkoutHistory> workouts) {
    final aggregate = <String, _ExercisePrAccumulator>{};
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        final current = aggregate.putIfAbsent(
          exercise.exerciseId,
          () => _ExercisePrAccumulator(exercise.name),
        );
        current.include(exercise, workout.id);
      }
    }
    return aggregate.entries
        .map(
          (entry) => ExercisePR(
            exerciseId: entry.key,
            exerciseName: entry.value.exerciseName,
            maxLoad: entry.value.maxLoad,
            maxVolume: entry.value.maxVolume,
            estimatedOneRepMax: entry.value.estimatedOneRepMax,
            achievedAt: entry.value.achievedAt,
            sessionId: entry.value.sessionId,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => right.achievedAt.compareTo(left.achievedAt));
  }

  List<WorkoutCalendarEntry> _calendar(
    List<WorkoutHistory> workouts,
    List<PersonalRecord> records,
  ) {
    final byDay = <DateTime, List<WorkoutHistory>>{};
    for (final workout in workouts) {
      byDay.putIfAbsent(_day(workout.finishedAt), () => []).add(workout);
    }
    final recordsByDay = <DateTime, int>{};
    for (final record in records) {
      final day = _day(record.achievedAt);
      recordsByDay[day] = (recordsByDay[day] ?? 0) + 1;
    }
    final entries =
        byDay.entries
            .map(
              (entry) => WorkoutCalendarEntry(
                date: entry.key,
                workoutCount: entry.value.length,
                totalDurationSeconds: entry.value.fold(
                  0,
                  (total, workout) => total + workout.metrics.durationSeconds,
                ),
                totalVolume: entry.value.fold(
                  0,
                  (total, workout) => total + workout.metrics.totalVolume,
                ),
                personalRecordCount: recordsByDay[entry.key] ?? 0,
                syncStatus: _highestSyncStatus(
                  entry.value.map((workout) => workout.syncStatus),
                ),
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => right.date.compareTo(left.date));
    return entries;
  }

  WorkoutStreak _streak(List<WorkoutHistory> workouts) {
    final days =
        workouts.map((workout) => _day(workout.finishedAt)).toSet().toList()
          ..sort();
    if (days.isEmpty) {
      return const WorkoutStreak(currentDays: 0, longestDays: 0);
    }
    var longest = 1;
    var running = 1;
    for (var index = 1; index < days.length; index++) {
      if (days[index].difference(days[index - 1]).inDays == 1) {
        running++;
      } else {
        running = 1;
      }
      if (running > longest) longest = running;
    }
    final latest = days.last;
    final today = _day(_clock());
    if (today.difference(latest).inDays > 1) {
      return WorkoutStreak(
        currentDays: 0,
        longestDays: longest,
        lastWorkoutDate: latest,
      );
    }
    var current = 1;
    for (var index = days.length - 1; index > 0; index--) {
      if (days[index].difference(days[index - 1]).inDays != 1) break;
      current++;
    }
    return WorkoutStreak(
      currentDays: current,
      longestDays: longest,
      lastWorkoutDate: latest,
    );
  }

  List<WorkoutTimelineEvent> _timeline(
    List<WorkoutHistory> workouts,
    List<PersonalRecord> records,
    WorkoutStreak streak,
  ) {
    final timeline = <WorkoutTimelineEvent>[];
    for (var index = 0; index < workouts.length; index++) {
      final workout = workouts[index];
      timeline.add(
        WorkoutTimelineEvent(
          id: 'workout:${workout.id}',
          type: WorkoutTimelineEventType.workoutCompleted,
          occurredAt: workout.finishedAt,
          title: 'Treino concluido',
          description:
              '${workout.metrics.setCount} series e ${workout.metrics.totalVolume.toStringAsFixed(0)} kg de volume.',
          sessionId: workout.id,
        ),
      );
      if (index == 0) {
        timeline.add(
          WorkoutTimelineEvent(
            id: 'first-workout:${workout.id}',
            type: WorkoutTimelineEventType.firstWorkout,
            occurredAt: workout.finishedAt,
            title: 'Primeiro treino concluido',
            description: 'Seu historico de treino comecou.',
            sessionId: workout.id,
          ),
        );
      }
      if (index > 0 && workouts[index - 1].planId != workout.planId) {
        timeline.add(
          WorkoutTimelineEvent(
            id: 'plan-change:${workout.id}',
            type: WorkoutTimelineEventType.planChanged,
            occurredAt: workout.startedAt,
            title: 'Plano alterado',
            description: workout.planName ?? 'Um novo plano foi iniciado.',
            sessionId: workout.id,
          ),
        );
      }
    }
    for (final record in records) {
      timeline.add(
        WorkoutTimelineEvent(
          id: 'record:${record.id}',
          type: WorkoutTimelineEventType.personalRecord,
          occurredAt: record.achievedAt,
          title: 'Novo recorde pessoal',
          description: record.title,
          sessionId: record.sessionId,
        ),
      );
    }
    if (streak.currentDays >= 3) {
      timeline.add(
        WorkoutTimelineEvent(
          id: 'streak:${streak.lastWorkoutDate!.toIso8601String()}',
          type: WorkoutTimelineEventType.streak,
          occurredAt: streak.lastWorkoutDate!,
          title: 'Sequencia ativa',
          description: '${streak.currentDays} dias consecutivos de treino.',
        ),
      );
    }
    timeline.sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    return timeline;
  }

  String _exerciseName(WorkoutSetLocal set) {
    final stored = set.exerciseName?.trim() ?? '';
    if (stored.isNotEmpty) return stored;
    final resolved = exerciseNameResolver?.call(set.exerciseId)?.trim() ?? '';
    return resolved.isNotEmpty ? resolved : set.exerciseId;
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  WorkoutSyncStatus _highestSyncStatus(Iterable<WorkoutSyncStatus> statuses) {
    const priority = {
      WorkoutSyncStatus.synced: 0,
      WorkoutSyncStatus.local: 1,
      WorkoutSyncStatus.pending: 2,
      WorkoutSyncStatus.syncing: 3,
      WorkoutSyncStatus.failed: 4,
      WorkoutSyncStatus.rejected: 5,
      WorkoutSyncStatus.conflict: 6,
    };
    return statuses.reduce(
      (current, value) =>
          (priority[value]! > priority[current]!) ? value : current,
    );
  }
}

class _ExercisePrAccumulator {
  _ExercisePrAccumulator(this.exerciseName);

  final String exerciseName;
  double maxLoad = 0;
  double maxVolume = 0;
  double estimatedOneRepMax = 0;
  DateTime achievedAt = DateTime.fromMillisecondsSinceEpoch(0);
  String sessionId = '';

  void include(ExerciseHistory exercise, String candidateSessionId) {
    var changed = false;
    if (exercise.highestLoad > maxLoad) {
      maxLoad = exercise.highestLoad;
      changed = true;
    }
    if (exercise.volume > maxVolume) {
      maxVolume = exercise.volume;
      changed = true;
    }
    if (exercise.estimatedOneRepMax > estimatedOneRepMax) {
      estimatedOneRepMax = exercise.estimatedOneRepMax;
      changed = true;
    }
    if (changed) {
      achievedAt = exercise.completedAt;
      sessionId = candidateSessionId;
    }
  }
}
