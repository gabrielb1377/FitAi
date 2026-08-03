import 'dart:convert';

import 'package:fitai/features/activities/data/activities_timeline_repository.dart';
import 'package:fitai/features/activities/domain/activity_query.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'migra indices reconstruiveis e pagina 100 corridas sem duplicacao',
    () async {
      final now = DateTime(2026, 8, 2, 12);
      final runs = List<CorridaModel>.generate(
        100,
        (index) => _run(index, now.subtract(Duration(hours: index))),
      );
      await _seed(runs: runs);

      await StorageService.migrarAtividadesIndexadas();
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('activitiesIndexSchemaVersion'), 2);
      expect(
        preferences.getStringList('activitiesRunningIndexV1'),
        hasLength(100),
      );

      final first = await StorageService.carregarCorridasPaginadas(limit: 20);
      final second = await StorageService.carregarCorridasPaginadas(
        cursor: first.nextCursor,
        limit: 20,
      );
      final third = await StorageService.carregarCorridasPaginadas(
        cursor: second.nextCursor,
        limit: 20,
      );

      final ids = [
        ...first.items,
        ...second.items,
        ...third.items,
      ].map((run) => run.id).toList(growable: false);
      expect(first.items, hasLength(20));
      expect(second.items, hasLength(20));
      expect(third.items, hasLength(20));
      expect(ids.toSet(), hasLength(60));
      expect(third.hasMore, isTrue);
    },
  );

  test('indice pagina mil corridas com cursor estavel', () async {
    final now = DateTime(2026, 8, 2, 12);
    await _seed(
      runs: List<CorridaModel>.generate(
        1000,
        (index) => _run(index, now.subtract(Duration(minutes: index))),
      ),
    );
    final watch = Stopwatch()..start();
    final ids = <String>{};
    ActivityTimelineCursor? cursor;
    do {
      final page = await StorageService.carregarCorridasPaginadas(
        cursor: cursor,
        limit: 50,
      );
      final countBefore = ids.length;
      ids.addAll(page.items.map((run) => run.id));
      expect(ids.length, countBefore + page.items.length);
      cursor = page.nextCursor;
    } while (cursor != null);
    watch.stop();

    expect(ids, hasLength(1000));
    // ignore: avoid_print
    print(
      '[ActivitiesScale] 1000 corridas paginadas: ${watch.elapsedMicroseconds} us',
    );
  });

  test(
    'consulta passos no intervalo e pagina sem materializar resultado fora dele',
    () async {
      final start = DateTime(2021, 1, 1, 12);
      final steps = List<DailyStepsModel>.generate(1826, (index) {
        final day = start.add(Duration(days: index));
        return _steps(day, steps: 5000 + (index % 6000));
      });
      await _seed(steps: steps);

      final month = await StorageService.carregarDailyStepsNoIntervalo(
        from: DateTime(2024, 2, 1),
        to: DateTime(2024, 2, 29, 23, 59, 59),
      );
      final first = await StorageService.carregarDailyStepsPaginados(limit: 31);
      final second = await StorageService.carregarDailyStepsPaginados(
        cursor: first.nextCursor,
        limit: 31,
      );

      expect(month, hasLength(29));
      expect(
        month.every((record) => record.date.startsWith('2024-02')),
        isTrue,
      );
      expect(first.items, hasLength(31));
      final firstIds = first.items.map((record) => record.recordId).toSet();
      expect(
        second.items.any((record) => firstIds.contains(record.recordId)),
        isFalse,
      );
    },
  );

  test('um ano de passos usa pagina por cursor e intervalo mensal', () async {
    final start = DateTime(2025, 1, 1, 12);
    await _seed(
      steps: List<DailyStepsModel>.generate(
        365,
        (index) => _steps(start.add(Duration(days: index)), steps: 7500),
      ),
    );

    final page = await StorageService.carregarDailyStepsPaginados(limit: 31);
    final april = await StorageService.carregarDailyStepsNoIntervalo(
      from: DateTime(2025, 4, 1),
      to: DateTime(2025, 4, 30, 23, 59, 59),
    );

    expect(page.items, hasLength(31));
    expect(page.hasMore, isTrue);
    expect(april, hasLength(30));
  });

  test(
    'timeline unificada preserva ordem, filtro e cursor entre corridas e passos',
    () async {
      final date = DateTime(2026, 8, 2, 12);
      await _seed(
        runs: [
          _run(1, date.subtract(const Duration(hours: 1))),
          _run(2, date.subtract(const Duration(days: 1))),
        ],
        steps: [
          _steps(date, steps: 9000),
          _steps(date.subtract(const Duration(days: 2)), steps: 7000),
        ],
      );
      const repository = ActivitiesTimelineRepository();

      final all = await repository.loadTimeline(pageSize: 2);
      final next = await repository.loadTimeline(
        pageSize: 2,
        cursor: all.nextCursor,
      );
      final runs = await repository.loadTimeline(
        filter: ActivityTimelineFilter.runs,
      );
      final steps = await repository.loadTimeline(
        filter: ActivityTimelineFilter.steps,
      );

      expect(all.items, hasLength(2));
      expect(
        all.items.first.occurredAt.isAfter(all.items.last.occurredAt),
        isTrue,
      );
      expect({
        ...all.items.map((item) => item.id),
        ...next.items.map((item) => item.id),
      }, hasLength(4));
      expect(
        runs.items.every((item) => item.record.type.name == 'running'),
        isTrue,
      );
      expect(
        steps.items.every((item) => item.record.type.name == 'steps'),
        isTrue,
      );
    },
  );

  test(
    'calendario unificado diferencia ausencia de passos, meta e multiplas corridas',
    () async {
      final month = DateTime(2026, 8);
      await _seed(
        runs: [
          _run(1, DateTime(2026, 8, 5, 8)),
          _run(2, DateTime(2026, 8, 5, 19)),
        ],
        steps: [_steps(DateTime(2026, 8, 5), steps: 10000)],
      );

      const repository = ActivitiesTimelineRepository();
      final calendar = await repository.loadCalendarMonth(month);
      final populated = calendar.dayFor(DateTime(2026, 8, 5));
      final unavailable = calendar.dayFor(DateTime(2026, 8, 6));

      expect(populated?.runs, hasLength(2));
      expect(populated?.stepsGoalReached, isTrue);
      expect(unavailable?.hasStepsData, isFalse);
      expect(unavailable?.hasRun, isFalse);
    },
  );

  test('calendario separa meses, hoje e futuro sem criar dados', () async {
    await _seed(steps: [_steps(DateTime(2026, 8, 2), steps: 9000)]);
    const repository = ActivitiesTimelineRepository();

    final august = await repository.loadCalendarMonth(DateTime(2026, 8));
    final september = await repository.loadCalendarMonth(DateTime(2026, 9));

    expect(august.dayFor(DateTime(2026, 8, 2))?.hasStepsData, isTrue);
    expect(august.dayFor(DateTime(2026, 8, 3))?.hasStepsData, isFalse);
    expect(september.dayFor(DateTime(2026, 9, 30))?.hasStepsData, isFalse);
  });
}

Future<void> _seed({
  List<CorridaModel> runs = const [],
  List<DailyStepsModel> steps = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'historicoCorridas': runs.map((run) => jsonEncode(run.toJson())).toList(),
    'dailyStepsHistory': steps
        .map((record) => jsonEncode(record.toJson()))
        .toList(),
  });
}

CorridaModel _run(int index, DateTime endedAt) => CorridaModel(
  id: 'run-$index-${endedAt.microsecondsSinceEpoch}',
  distancia: 5,
  segundos: 1500,
  data: endedAt.toIso8601String(),
  startTime: endedAt.subtract(const Duration(minutes: 25)).toIso8601String(),
  endTime: endedAt.toIso8601String(),
  pace: 5,
  averageSpeed: 12,
);

DailyStepsModel _steps(DateTime day, {required int steps}) => DailyStepsModel(
  date: day.toIso8601String(),
  steps: steps,
  goal: 8000,
  source: DailyStepsModel.sourceDevice,
  recordedAt: day,
  updatedAt: day,
);
