import '../../../models/corrida_model.dart';
import '../../../models/running_split_model.dart';
import 'steps_day_policy.dart';

enum RunningRecordType {
  fastest1K,
  fastest5K,
  fastest10K,
  longestDistance,
  bestAveragePace,
}

/// Records are read projections, not persisted rewards or XP events.
class RunningPersonalRecord {
  const RunningPersonalRecord({
    required this.type,
    required this.runId,
    required this.value,
  });
  final RunningRecordType type;
  final String runId;

  /// Seconds for distance records, km for longest, seconds/km for average pace.
  final double value;
}

class RunningPeriodMetrics {
  const RunningPeriodMetrics({
    required this.numberOfRuns,
    required this.totalDistanceKm,
    required this.totalActiveSeconds,
    this.hasCompleteDistance = true,
  });
  final int numberOfRuns;
  final double totalDistanceKm;
  final int totalActiveSeconds;
  final bool hasCompleteDistance;
  double? get averagePaceSecondsPerKm =>
      hasCompleteDistance && totalDistanceKm > 0
      ? totalActiveSeconds / totalDistanceKm
      : null;
}

class RunningComparison {
  const RunningComparison({
    required this.previousRunId,
    required this.distanceDeltaKm,
    required this.paceDeltaSecondsPerKm,
  });
  final String previousRunId;
  final double distanceDeltaKm;

  /// Negative means faster. Both runs must be within 20% in distance.
  final double paceDeltaSecondsPerKm;
}

class RunningPostRunSummary {
  const RunningPostRunSummary({
    required this.run,
    required this.splits,
    required this.recordsAchieved,
    this.comparison,
  });
  final CorridaModel run;
  final List<RunningSplitModel> splits;
  final List<RunningPersonalRecord> recordsAchieved;
  final RunningComparison? comparison;
  double get distanceKm => run.distancia;
  int get activeSeconds => run.segundos;
  double? get averagePaceSecondsPerKm =>
      distanceKm > 0 ? activeSeconds / distanceKm : null;
  double? get averageSpeedKmh =>
      activeSeconds > 0 ? distanceKm * 3600 / activeSeconds : null;
  int? get steps => run.steps;
  double? get calories => run.hasReliableCalories ? run.calories : null;

  /// GPS altitude has no vertical-accuracy/source contract; do not fabricate gain.
  String get elevationStatus => 'ELEVATION_DATA_UNAVAILABLE';
}

/// Deterministic, per-user projections of the existing canonical run history.
class RunningMetrics {
  const RunningMetrics({this.dayPolicy = const StepsDayPolicy()});
  final StepsDayPolicy dayPolicy;

  List<CorridaModel> history(Iterable<CorridaModel> runs, String userId) {
    final byId = <String, CorridaModel>{};
    for (final run in runs) {
      if (run.userId != userId || run.id.trim().isEmpty) continue;
      final prior = byId[run.id];
      // Deletion is sticky; a stale duplicate cannot resurrect an activity.
      if (prior == null ||
          (!prior.isDeleted &&
              (run.isDeleted || _revision(run) > _revision(prior)))) {
        byId[run.id] = run;
      }
    }
    final valid = byId.values.where(_valid).toList();
    valid.sort((a, b) {
      final order = _completedAt(a)!.compareTo(_completedAt(b)!);
      return order != 0 ? order : a.id.compareTo(b.id);
    });
    return List.unmodifiable(valid);
  }

  List<RunningPersonalRecord> records(
    Iterable<CorridaModel> runs,
    String userId,
  ) {
    final records = <RunningRecordType, RunningPersonalRecord>{};
    for (final run in history(runs, userId)) {
      for (final candidate in _candidates(run)) {
        final prior = records[candidate.type];
        final better =
            prior == null ||
            (candidate.type == RunningRecordType.longestDistance
                ? candidate.value > prior.value
                : candidate.value < prior.value);
        if (better) records[candidate.type] = candidate;
      }
    }
    return List.unmodifiable(records.values);
  }

  RunningPostRunSummary? summary(
    Iterable<CorridaModel> runs,
    String userId,
    String runId,
  ) {
    final valid = history(runs, userId);
    final index = valid.indexWhere((run) => run.id == runId);
    if (index < 0) return null;
    final run = valid[index];
    final before = valid.take(index).toList();
    final previousRecords = {
      for (final record in records(before, userId)) record.type: record,
    };
    final achieved = _candidates(run).where((candidate) {
      final prior = previousRecords[candidate.type];
      return prior == null ||
          (candidate.type == RunningRecordType.longestDistance
              ? candidate.value > prior.value
              : candidate.value < prior.value);
    }).toList();
    CorridaModel? baseline;
    for (final previous in before.reversed) {
      if (run.distancia >= 1 &&
          previous.distancia >= 1 &&
          (previous.distancia - run.distancia).abs() / run.distancia <= 0.2 &&
          _completedAt(previous)!.isBefore(_completedAt(run)!)) {
        baseline = previous;
        break;
      }
    }
    return RunningPostRunSummary(
      run: run,
      splits: RunningSplitModel.fromRun(run),
      recordsAchieved: List.unmodifiable(achieved),
      comparison: baseline == null
          ? null
          : RunningComparison(
              previousRunId: baseline.id,
              distanceDeltaKm: run.distancia - baseline.distancia,
              paceDeltaSecondsPerKm:
                  run.segundos / run.distancia -
                  baseline.segundos / baseline.distancia,
            ),
    );
  }

  RunningPeriodMetrics weekly(
    Iterable<CorridaModel> runs,
    String userId,
    DateTime reference,
  ) {
    final date = _calendarDate(reference);
    final start = date.subtract(Duration(days: date.weekday - 1));
    return _period(runs, userId, start, start.add(const Duration(days: 7)));
  }

  RunningPeriodMetrics monthly(
    Iterable<CorridaModel> runs,
    String userId,
    DateTime reference,
  ) {
    final date = _calendarDate(reference);
    return _period(
      runs,
      userId,
      DateTime.utc(date.year, date.month),
      DateTime.utc(date.year, date.month + 1),
    );
  }

  RunningPeriodMetrics _period(
    Iterable<CorridaModel> runs,
    String userId,
    DateTime start,
    DateTime end,
  ) {
    final selected = history(runs, userId).where((run) {
      final date = _calendarDate(_completedAt(run)!);
      return !date.isBefore(start) && date.isBefore(end);
    }).toList();
    return RunningPeriodMetrics(
      numberOfRuns: selected.length,
      totalDistanceKm: selected.fold(
        0.0,
        (total, run) => total + run.distancia,
      ),
      totalActiveSeconds: selected.fold(
        0,
        (total, run) => total + run.segundos,
      ),
      hasCompleteDistance: selected.every((run) => run.distancia > 0),
    );
  }

  Iterable<RunningPersonalRecord> _candidates(CorridaModel run) sync* {
    if (run.distancia > 0) {
      yield RunningPersonalRecord(
        type: RunningRecordType.longestDistance,
        runId: run.id,
        value: run.distancia,
      );
    }
    if (run.distancia >= 1) {
      yield RunningPersonalRecord(
        type: RunningRecordType.bestAveragePace,
        runId: run.id,
        value: run.segundos / run.distancia,
      );
    }
    final full = RunningSplitModel.fromRun(
      run,
    ).where((split) => !split.isPartial).toList();
    // Conservative km-aligned windows, not a claimed sliding GPS best effort.
    for (final target in const [1, 5, 10]) {
      if (run.distancia < target || full.length < target) continue;
      int? best;
      var window = 0;
      for (var i = 0; i < full.length; i++) {
        window += full[i].elapsedSeconds;
        if (i >= target) window -= full[i - target].elapsedSeconds;
        if (i >= target - 1 &&
            window >= target * 100 &&
            (best == null || window < best)) {
          best = window;
        }
      }
      if (best == null) continue;
      yield RunningPersonalRecord(
        type: switch (target) {
          1 => RunningRecordType.fastest1K,
          5 => RunningRecordType.fastest5K,
          _ => RunningRecordType.fastest10K,
        },
        runId: run.id,
        value: best.toDouble(),
      );
    }
  }

  bool _valid(CorridaModel run) {
    final end = _completedAt(run);
    final start = DateTime.tryParse(run.startTime);
    return run.finished &&
        !run.paused &&
        !run.isDeleted &&
        run.distancia.isFinite &&
        run.distancia >= 0 &&
        run.segundos > 0 &&
        run.distancia * 3600 / run.segundos <= 36 &&
        end != null &&
        start != null &&
        !end.isBefore(start);
  }

  static DateTime? _completedAt(CorridaModel run) =>
      DateTime.tryParse(run.endTime ?? run.data);
  static int _revision(CorridaModel run) =>
      int.tryParse(run.remoteRevision) ?? 0;
  DateTime _calendarDate(DateTime instant) =>
      DateTime.parse('${dayPolicy.dayKey(instant)}T00:00:00Z');
}
