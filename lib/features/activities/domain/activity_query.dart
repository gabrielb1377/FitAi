import '../../../models/corrida_model.dart';
import '../../../models/daily_steps_model.dart';
import 'activity_record.dart';

/// Filtros suportados pela leitura unificada de Atividades.
///
/// Musculacao propositalmente nao faz parte desta enumeracao: ela pertence a
/// Planos e ao respectivo historico de treino.
enum ActivityTimelineFilter { all, runs, steps }

/// Cursor estavel para paginas ordenadas da mais recente para a mais antiga.
class ActivityTimelineCursor {
  const ActivityTimelineCursor({required this.occurredAt, required this.id});

  final DateTime occurredAt;
  final String id;

  bool includesAfter(DateTime value, String valueId) {
    final timestamp = value.compareTo(occurredAt);
    return timestamp < 0 || (timestamp == 0 && valueId.compareTo(id) < 0);
  }
}

/// Resultado paginado sem reter uma segunda copia persistida do historico.
class ActivityStoragePage<T> {
  const ActivityStoragePage({required this.items, this.nextCursor});

  final List<T> items;
  final ActivityTimelineCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Item de timeline que conserva o registro generico e seu instante de ordem.
class ActivityTimelineItem {
  const ActivityTimelineItem({required this.record, required this.occurredAt});

  final ActivityRecord<ActivityDetails> record;
  final DateTime occurredAt;

  String get id => record.id;

  ActivityTimelineCursor get cursor =>
      ActivityTimelineCursor(occurredAt: occurredAt, id: id);
}

class ActivityTimelinePage {
  const ActivityTimelinePage({required this.items, this.nextCursor});

  final List<ActivityTimelineItem> items;
  final ActivityTimelineCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Projecao de um dia do calendario unificado. Passos ausentes continuam
/// nulos para diferenciar indisponibilidade de zero passos.
class UnifiedActivityCalendarDay {
  const UnifiedActivityCalendarDay({
    required this.date,
    required this.runs,
    required this.steps,
  });

  final DateTime date;
  final List<CorridaModel> runs;
  final DailyStepsModel? steps;

  bool get hasRun => runs.isNotEmpty;
  bool get hasStepsData => steps != null;
  bool get stepsGoalReached => steps?.goalCompleted ?? false;
}

class UnifiedActivityCalendarMonth {
  const UnifiedActivityCalendarMonth({required this.month, required this.days});

  final DateTime month;
  final Map<String, UnifiedActivityCalendarDay> days;

  UnifiedActivityCalendarDay? dayFor(DateTime date) =>
      days[activityDateKey(date)];
}

String activityDateKey(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
