import '../../../models/corrida_model.dart';
import '../../../models/daily_steps_model.dart';
import '../../../services/storage_service.dart';
import '../domain/activity_query.dart';
import 'daily_steps_activity_mapper.dart';
import 'running_activity_mapper.dart';

/// Leitura unificada sobre o storage local ja existente.
///
/// O repositorio nao persiste timeline ou calendario: ele combina paginas dos
/// indices de Corridas e Passos para evitar uma segunda fonte de verdade.
class ActivitiesTimelineRepository {
  const ActivitiesTimelineRepository();

  static const defaultPageSize = 20;

  Future<ActivityTimelinePage> loadTimeline({
    ActivityTimelineFilter filter = ActivityTimelineFilter.all,
    ActivityTimelineCursor? cursor,
    int pageSize = defaultPageSize,
  }) async {
    assert(pageSize > 0);
    final sourcePageSize = pageSize * 2;
    final runPage = filter == ActivityTimelineFilter.steps
        ? const ActivityStoragePage<CorridaModel>(items: [])
        : await StorageService.carregarCorridasPaginadas(
            cursor: cursor,
            limit: sourcePageSize,
          );
    final stepsPage = filter == ActivityTimelineFilter.runs
        ? const ActivityStoragePage<DailyStepsModel>(items: [])
        : await StorageService.carregarDailyStepsPaginados(
            cursor: cursor,
            limit: sourcePageSize,
          );

    final items = <ActivityTimelineItem>[
      for (final run in runPage.items)
        ActivityTimelineItem(
          record: run.toActivityRecord(),
          occurredAt: _runOccurredAt(run),
        ),
      for (final steps in stepsPage.items)
        ActivityTimelineItem(
          record: steps.toActivityRecord(),
          occurredAt: _stepsOccurredAt(steps),
        ),
    ]..sort(_compareItems);

    final visible = items.take(pageSize).toList(growable: false);
    final sourceHasMore = runPage.hasMore || stepsPage.hasMore;
    final hasMore = items.length > visible.length || sourceHasMore;
    return ActivityTimelinePage(
      items: visible,
      nextCursor: hasMore && visible.isNotEmpty ? visible.last.cursor : null,
    );
  }

  Future<UnifiedActivityCalendarMonth> loadCalendarMonth(DateTime month) async {
    final normalized = DateTime(month.year, month.month);
    final from = normalized;
    final to = DateTime(normalized.year, normalized.month + 1, 0, 23, 59, 59);
    final results = await Future.wait([
      StorageService.carregarCorridasNoIntervalo(from: from, to: to),
      StorageService.carregarDailyStepsNoIntervalo(from: from, to: to),
    ]);
    final runs = results[0] as List<CorridaModel>;
    final steps = results[1] as List<DailyStepsModel>;
    final byDay = <String, UnifiedActivityCalendarDay>{};

    for (var day = 1; day <= to.day; day++) {
      final date = DateTime(normalized.year, normalized.month, day);
      byDay[activityDateKey(date)] = UnifiedActivityCalendarDay(
        date: date,
        runs: const [],
        steps: null,
      );
    }
    for (final run in runs) {
      final key = activityDateKey(_runOccurredAt(run));
      final current = byDay[key];
      if (current == null) continue;
      byDay[key] = UnifiedActivityCalendarDay(
        date: current.date,
        runs: [...current.runs, run],
        steps: current.steps,
      );
    }
    for (final record in steps) {
      final current = byDay[record.date];
      if (current == null) continue;
      byDay[record.date] = UnifiedActivityCalendarDay(
        date: current.date,
        runs: current.runs,
        steps: record,
      );
    }
    return UnifiedActivityCalendarMonth(month: normalized, days: byDay);
  }

  static int _compareItems(
    ActivityTimelineItem first,
    ActivityTimelineItem second,
  ) {
    final time = second.occurredAt.compareTo(first.occurredAt);
    return time != 0 ? time : second.id.compareTo(first.id);
  }

  static DateTime _runOccurredAt(CorridaModel run) =>
      DateTime.tryParse(run.endTime ?? run.data)?.toLocal() ??
      DateTime.tryParse(run.data)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime _stepsOccurredAt(DailyStepsModel record) =>
      DateTime.tryParse(record.date)?.toLocal() ?? record.recordedAt.toLocal();
}
