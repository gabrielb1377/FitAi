import '../../../models/daily_steps_model.dart';

/// Agregados deriváveis do histórico local, sem persistência paralela.
class StepsPeriodSummary {
  const StepsPeriodSummary({
    required this.total,
    required this.average,
    required this.activeDays,
    required this.goalReachedDays,
    required this.bestDay,
  });

  final int total;
  final int average;
  final int activeDays;
  final int goalReachedDays;
  final DailyStepsModel? bestDay;
}

/// Não trata ausência de leitura como quebra de sequência.
class StepsStreakResult {
  const StepsStreakResult({required this.days, required this.hasCompleteData});

  final int days;
  final bool hasCompleteData;
}

/// Não converte um dia ausente em zero passos para a comparação diária.
class StepsDayComparison {
  const StepsDayComparison({
    required this.difference,
    required this.hasTodayData,
    required this.hasYesterdayData,
  });

  final int? difference;
  final bool hasTodayData;
  final bool hasYesterdayData;

  bool get hasCompleteData => hasTodayData && hasYesterdayData;
}

/// Regras puras para visão semanal, mensal e sequência de passos.
abstract final class StepsMetrics {
  static StepsPeriodSummary summarize(
    Iterable<DailyStepsModel> records, {
    required DateTime from,
    required DateTime to,
  }) {
    final selected = records.where((record) => _inRange(record, from, to));
    final list = selected.toList(growable: false);
    if (list.isEmpty) {
      return const StepsPeriodSummary(
        total: 0,
        average: 0,
        activeDays: 0,
        goalReachedDays: 0,
        bestDay: null,
      );
    }
    final total = list.fold<int>(0, (sum, record) => sum + record.steps);
    DailyStepsModel? best;
    for (final record in list) {
      if (best == null || record.steps > best.steps) best = record;
    }
    return StepsPeriodSummary(
      total: total,
      average: (total / list.length).round(),
      activeDays: list.where((record) => record.steps > 0).length,
      goalReachedDays: list.where((record) => record.goalCompleted).length,
      bestDay: best,
    );
  }

  /// Conta dias consecutivos com a meta atingida. Um dia atual ainda aberto
  /// não quebra uma sequência que terminou ontem.
  static int activeStreak(
    Iterable<DailyStepsModel> records, {
    required DateTime now,
  }) => streak(records, now: now).days;

  static StepsStreakResult streak(
    Iterable<DailyStepsModel> records, {
    required DateTime now,
  }) {
    final byDate = <String, DailyStepsModel>{
      for (final record in records) record.date: record,
    };
    var cursor = _day(now);
    final today =
        byDate[DailyStepsModel.normalizeDateKey(cursor.toIso8601String())];
    if (today == null || !today.goalCompleted) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var days = 0;
    while (true) {
      final key = DailyStepsModel.normalizeDateKey(cursor.toIso8601String());
      final record = byDate[key];
      if (record == null) {
        return StepsStreakResult(days: days, hasCompleteData: false);
      }
      if (!record.goalCompleted) {
        return StepsStreakResult(days: days, hasCompleteData: true);
      }
      days++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  static int comparisonWithYesterday(
    Iterable<DailyStepsModel> records, {
    required DateTime now,
  }) => dayComparison(records, now: now).difference ?? 0;

  static StepsDayComparison dayComparison(
    Iterable<DailyStepsModel> records, {
    required DateTime now,
  }) {
    final today = _day(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final byDate = {for (final record in records) record.date: record};
    final todayRecord =
        byDate[DailyStepsModel.normalizeDateKey(today.toIso8601String())];
    final yesterdayRecord =
        byDate[DailyStepsModel.normalizeDateKey(yesterday.toIso8601String())];
    return StepsDayComparison(
      difference: todayRecord == null || yesterdayRecord == null
          ? null
          : todayRecord.steps - yesterdayRecord.steps,
      hasTodayData: todayRecord != null,
      hasYesterdayData: yesterdayRecord != null,
    );
  }

  static bool _inRange(DailyStepsModel record, DateTime from, DateTime to) {
    final day = DateTime.tryParse(record.date);
    if (day == null) return false;
    final current = _day(day);
    return !current.isBefore(_day(from)) && !current.isAfter(_day(to));
  }

  static DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
