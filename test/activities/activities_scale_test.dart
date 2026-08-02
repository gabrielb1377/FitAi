import 'package:fitai/features/activities/data/running_activity_mapper.dart';
import 'package:fitai/features/activities/domain/steps_metrics.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agregados de passos preservam resultados em cinco anos de dados', () {
    final now = DateTime(2026, 8, 2, 12);
    final started = Stopwatch()..start();
    final records = List<DailyStepsModel>.generate(1826, (index) {
      final day = now.subtract(Duration(days: index));
      return DailyStepsModel(
        date: day.toIso8601String(),
        steps: 6000 + (index % 5000),
        goal: 8000,
        source: DailyStepsModel.sourceDevice,
        recordedAt: day,
        updatedAt: day,
      );
    });

    final summary = StepsMetrics.summarize(
      records,
      from: now.subtract(const Duration(days: 29)),
      to: now,
    );
    final comparison = StepsMetrics.dayComparison(records, now: now);
    started.stop();

    expect(summary.activeDays, 30);
    expect(summary.total, greaterThan(0));
    expect(comparison.hasCompleteData, isTrue);
    // Registra a evidência de escala sem transformar o teste em benchmark frágil.
    // ignore: avoid_print
    print(
      '[ActivitiesScale] passos: ${records.length} registros, '
      '${started.elapsedMicroseconds} us',
    );
  });

  test('mapeamento genérico preserva mil corridas sem duplicar detalhes', () {
    final started = Stopwatch()..start();
    final runs = List<CorridaModel>.generate(
      1000,
      (index) => CorridaModel(
        id: 'run-$index',
        data: '2026-08-02T10:00:00.000',
        distancia: 5 + (index % 10) / 10,
        segundos: 1500 + index,
        pace: 5.2,
        averageSpeed: 11.5,
      ),
    );

    final activities = runs
        .map((run) => run.toActivityRecord())
        .toList(growable: false);
    started.stop();

    expect(activities, hasLength(1000));
    expect(activities.map((activity) => activity.id).toSet(), hasLength(1000));
    // ignore: avoid_print
    print(
      '[ActivitiesScale] corridas: ${activities.length} registros, '
      '${started.elapsedMicroseconds} us',
    );
  });
}
