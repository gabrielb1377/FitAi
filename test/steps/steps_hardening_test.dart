import 'package:fitai/features/activities/domain/steps_metrics.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 4, 12);

  DailyStepsModel record({
    required String date,
    required int steps,
    int goal = 8000,
  }) => DailyStepsModel(
    date: date,
    steps: steps,
    goal: goal,
    source: DailyStepsModel.sourceManual,
    recordedAt: now,
    updatedAt: now,
  );

  test('ausência de agregado não vira comparação igual a ontem', () {
    final comparison = StepsMetrics.dayComparison([
      record(date: '2026-08-04', steps: 9000),
    ], now: now);

    expect(comparison.difference, isNull);
    expect(comparison.hasTodayData, isTrue);
    expect(comparison.hasYesterdayData, isFalse);
    expect(comparison.hasCompleteData, isFalse);
  });

  test('lacuna de fonte é distinta de meta não atingida na sequência', () {
    final missing = StepsMetrics.streak([
      record(date: '2026-08-04', steps: 9000),
    ], now: now);
    final missedGoal = StepsMetrics.streak([
      record(date: '2026-08-04', steps: 3000),
      record(date: '2026-08-03', steps: 3000),
    ], now: now);

    expect(missing.days, 1);
    expect(missing.hasCompleteData, isFalse);
    expect(missedGoal.days, 0);
    expect(missedGoal.hasCompleteData, isTrue);
  });

  test('dia explícito preserva a data local para a identidade diária', () {
    final daily = DailyStepsModel(
      date: '2026-08-04',
      steps: 100,
      goal: 8000,
      source: DailyStepsModel.sourceLocal,
      recordedAt: DateTime.utc(2026, 8, 4, 23, 59),
      updatedAt: DateTime.utc(2026, 8, 4, 23, 59),
    );

    expect(daily.date, '2026-08-04');
    expect(daily.recordId, 'steps:local:2026-08-04');
  });

  test('estimativas continuam ausentes sem uma fonte que as forneça', () {
    final daily = record(date: '2026-08-04', steps: 9000);

    expect(daily.hasEstimatedDistance, isFalse);
    expect(daily.hasEstimatedCalories, isFalse);
    expect(daily.toJson()['estimatedDistanceMeters'], isNull);
    expect(daily.toJson()['estimatedCalories'], isNull);
  });
}
