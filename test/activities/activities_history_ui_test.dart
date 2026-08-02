import 'package:fitai/design_system/design_system.dart';
import 'package:fitai/features/activities/domain/activity_history_models.dart';
import 'package:fitai/features/activities/presentation/pages/activity_history_pages.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('timeline mostra busca, filtros e atividades canonicas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ActivitiesTimelinePage(loadHistory: _loadHistory)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Historico'), findsOneWidget);
    expect(find.text('Upper A'), findsOneWidget);
    expect(find.text('Lower A'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtrar atividades'));
    await tester.pumpAndSettle();

    expect(find.text('Grupo muscular'), findsOneWidget);
    expect(find.text('Pendente de sync'), findsOneWidget);
  });

  testWidgets('busca reduz a timeline sem excecao', (tester) async {
    await tester.pumpWidget(
      _app(ActivitiesTimelinePage(loadHistory: _loadHistory)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'agachamento');
    await tester.pumpAndSettle();

    expect(find.text('Lower A'), findsOneWidget);
    expect(find.text('Upper A'), findsNothing);
  });

  testWidgets('calendario e detalhe usam o snapshot offline', (tester) async {
    await tester.pumpWidget(
      _app(ActivitiesCalendarPage(loadHistory: _loadHistory)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calendario'), findsOneWidget);
    expect(find.textContaining('de'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _app(
        ActivityWorkoutDetailPage(
          sessionId: 'session-upper',
          loadHistory: _loadHistory,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da atividade'), findsOneWidget);
    expect(find.text('55 kg x 10'), findsOneWidget);
  });

  testWidgets('timeline suporta celular estreito e texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        ActivitiesTimelinePage(loadHistory: _loadHistory),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline e calendario se adaptam de celular a desktop', (
    tester,
  ) async {
    const viewports = <Size>[
      Size(320, 640),
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(600, 960),
      Size(768, 1024),
      Size(1024, 768),
      Size(1440, 900),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;

      await tester.pumpWidget(
        _app(ActivitiesTimelinePage(loadHistory: _loadHistory)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'timeline em $viewport');

      await tester.pumpWidget(
        _app(ActivitiesCalendarPage(loadHistory: _loadHistory)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'calendario em $viewport');
    }
  });
}

Widget _app(Widget home, {TextScaler? textScaler}) => MaterialApp(
  theme: FitTheme.dark(),
  builder: (context, child) => textScaler == null
      ? child!
      : MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
  home: home,
);

Future<WorkoutActivityHistorySnapshot> _loadHistory() async => _snapshot();

WorkoutActivityHistorySnapshot _snapshot() {
  final now = DateTime.now();
  final upper = WorkoutHistory(
    id: 'session-upper',
    planId: 'plan-upper',
    workoutId: 'upper-a',
    planName: 'Plano Upper',
    workoutName: 'Upper A',
    startedAt: now.subtract(const Duration(hours: 2)),
    finishedAt: now.subtract(const Duration(hours: 1)),
    metrics: const WorkoutMetrics(
      durationSeconds: 3600,
      totalVolume: 1650,
      totalLoad: 165,
      exerciseCount: 1,
      setCount: 3,
      totalRepetitions: 30,
    ),
    exercises: [
      ExerciseHistory(
        exerciseId: 'supino-reto',
        name: 'Supino reto',
        muscles: const ['Peito'],
        category: 'Musculacao',
        completedAt: now.subtract(const Duration(hours: 1)),
        volume: 1650,
        totalRepetitions: 30,
        sets: [
          CompletedSet(
            id: 'set-upper',
            index: 0,
            weight: 55,
            repetitions: 10,
            restSeconds: 60,
            completedAt: now.subtract(const Duration(hours: 1)),
            syncStatus: WorkoutSyncStatus.synced,
          ),
        ],
      ),
    ],
    syncStatus: WorkoutSyncStatus.synced,
  );
  final lower = WorkoutHistory(
    id: 'session-lower',
    planId: 'plan-lower',
    workoutId: 'lower-a',
    planName: 'Plano Lower',
    workoutName: 'Lower A',
    startedAt: now.subtract(const Duration(days: 1, hours: 2)),
    finishedAt: now.subtract(const Duration(days: 1, hours: 1)),
    metrics: const WorkoutMetrics(
      durationSeconds: 3300,
      totalVolume: 2400,
      totalLoad: 240,
      exerciseCount: 1,
      setCount: 3,
      totalRepetitions: 18,
    ),
    exercises: [
      ExerciseHistory(
        exerciseId: 'agachamento-livre',
        name: 'Agachamento livre',
        muscles: const ['Quadriceps'],
        category: 'Musculacao',
        completedAt: now.subtract(const Duration(days: 1, hours: 1)),
        volume: 2400,
        totalRepetitions: 18,
        sets: [
          CompletedSet(
            id: 'set-lower',
            index: 0,
            weight: 80,
            repetitions: 6,
            completedAt: now.subtract(const Duration(days: 1, hours: 1)),
            syncStatus: WorkoutSyncStatus.pending,
          ),
        ],
      ),
    ],
    syncStatus: WorkoutSyncStatus.pending,
  );
  return WorkoutActivityHistorySnapshot(
    workouts: [upper, lower],
    summaries: [upper.summary, lower.summary],
    exercisePrs: const [],
    personalRecords: const [],
    timeline: const [],
    calendar: const [],
    streak: const WorkoutStreak(currentDays: 2, longestDays: 4),
  );
}
