import '../../../models/historico_treino_model.dart';
import '../../../models/treino_model.dart';
import '../../../services/storage_service.dart';

class PlanWeekSnapshot {
  const PlanWeekSnapshot({
    required this.number,
    required this.startsAt,
    required this.completedWorkouts,
    required this.targetWorkouts,
    required this.isCurrent,
    required this.isFuture,
  });

  final int number;
  final DateTime startsAt;
  final int completedWorkouts;
  final int targetWorkouts;
  final bool isCurrent;
  final bool isFuture;

  double get progress => targetWorkouts <= 0
      ? 0
      : (completedWorkouts / targetWorkouts).clamp(0.0, 1.0).toDouble();

  bool get isCompleted => progress >= 1;
}

class PlanProgressSnapshot {
  const PlanProgressSnapshot({
    required this.completedWorkouts,
    required this.weeklyCompletedWorkouts,
    required this.weeklyTargetWorkouts,
    required this.nextDayIndex,
    required this.weeks,
    this.latestWorkout,
  });

  factory PlanProgressSnapshot.empty(TreinoModel plan) {
    final target = _targetFor(plan);
    return PlanProgressSnapshot(
      completedWorkouts: 0,
      weeklyCompletedWorkouts: 0,
      weeklyTargetWorkouts: target,
      nextDayIndex: 0,
      weeks: _buildWeeks(plan, const []),
    );
  }

  final int completedWorkouts;
  final int weeklyCompletedWorkouts;
  final int weeklyTargetWorkouts;
  final int nextDayIndex;
  final List<PlanWeekSnapshot> weeks;
  final HistoricoTreinoModel? latestWorkout;

  double get weeklyProgress => weeklyTargetWorkouts <= 0
      ? 0
      : (weeklyCompletedWorkouts / weeklyTargetWorkouts)
            .clamp(0.0, 1.0)
            .toDouble();

  static int _targetFor(TreinoModel plan) {
    if (plan.planoDias.isNotEmpty) return plan.planoDias.length;
    return plan.diasPorSemana <= 0 ? 1 : plan.diasPorSemana;
  }
}

class PlanProgressLoader {
  const PlanProgressLoader();

  Future<Map<String, PlanProgressSnapshot>> load(
    List<TreinoModel> plans,
  ) async {
    if (plans.isEmpty) return const {};
    final history = await StorageService.carregarHistoricoTreinos();
    return {for (final plan in plans) plan.id: _snapshot(plan, history)};
  }

  PlanProgressSnapshot _snapshot(
    TreinoModel plan,
    List<HistoricoTreinoModel> history,
  ) {
    final names = <String>{
      _normalize(plan.nome),
      for (final day in plan.planoDias) ...{
        _normalize(day.nome),
        _normalize(plan.somenteDia(day).nome),
      },
    }..removeWhere((name) => name.isEmpty);
    final matching = history.where((entry) {
      final name = _normalize(entry.nomeTreino);
      return names.contains(name);
    }).toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final weekStart = _startOfWeek(DateTime.now());
    final weekly = matching.where((entry) {
      return !_startOfWeek(entry.dataHora).isBefore(weekStart);
    }).length;
    final target = PlanProgressSnapshot._targetFor(plan);
    final dayCount = plan.planoDias.isEmpty ? target : plan.planoDias.length;

    return PlanProgressSnapshot(
      completedWorkouts: matching.length,
      weeklyCompletedWorkouts: weekly.clamp(0, target),
      weeklyTargetWorkouts: target,
      nextDayIndex: dayCount <= 0 ? 0 : matching.length % dayCount,
      latestWorkout: matching.isEmpty ? null : matching.first,
      weeks: _buildWeeks(plan, matching),
    );
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u00c0-\u024f]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

List<PlanWeekSnapshot> _buildWeeks(
  TreinoModel plan,
  List<HistoricoTreinoModel> history,
) {
  final now = DateTime.now();
  final currentStart = _startOfWeek(now);
  final createdAt = DateTime.tryParse(plan.dataCriacao)?.toLocal() ?? now;
  var firstStart = _startOfWeek(createdAt);
  if (firstStart.isAfter(currentStart)) firstStart = currentStart;

  final elapsed = currentStart.difference(firstStart).inDays ~/ 7;
  if (elapsed > 5) firstStart = currentStart.subtract(const Duration(days: 35));
  final target = PlanProgressSnapshot._targetFor(plan);
  final visiblePastAndCurrent = currentStart.difference(firstStart).inDays ~/ 7;
  final count = visiblePastAndCurrent + 3;

  return List.generate(count, (index) {
    final start = firstStart.add(Duration(days: index * 7));
    final end = start.add(const Duration(days: 7));
    final completed = history.where((entry) {
      final local = entry.dataHora.toLocal();
      return !local.isBefore(start) && local.isBefore(end);
    }).length;
    return PlanWeekSnapshot(
      number: index + 1,
      startsAt: start,
      completedWorkouts: completed.clamp(0, target),
      targetWorkouts: target,
      isCurrent: start == currentStart,
      isFuture: start.isAfter(currentStart),
    );
  });
}

DateTime _startOfWeek(DateTime value) {
  final local = value.toLocal();
  final date = DateTime(local.year, local.month, local.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}
