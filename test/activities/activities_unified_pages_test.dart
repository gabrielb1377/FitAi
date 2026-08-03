import 'dart:convert';

import 'package:fitai/features/activities/presentation/pages/activities_calendar_page.dart';
import 'package:fitai/features/activities/presentation/pages/activities_timeline_page.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('timeline exibe corridas e passos e permite filtrar', (
    tester,
  ) async {
    await _seed();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const ActivitiesTimelinePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Linha do tempo'), findsOneWidget);
    expect(find.text('Corrida'), findsOneWidget);
    expect(find.text('Passos'), findsWidgets);
    await tester.tap(find.text('Passos').first);
    await tester.pumpAndSettle();
    expect(find.text('Corrida'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendario mostra dados ausentes sem inventar passos', (
    tester,
  ) async {
    await _seed();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ActivitiesCalendarPage(initialMonth: DateTime(2026, 8)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calendario'), findsOneWidget);
    expect(find.text('Dados indisponiveis neste dia.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _seed() async {
  final date = DateTime(2026, 8, 2, 12);
  final run = CorridaModel(
    id: 'run-widget',
    distancia: 5,
    segundos: 1500,
    data: date.toIso8601String(),
    startTime: date.subtract(const Duration(minutes: 25)).toIso8601String(),
    endTime: date.toIso8601String(),
    pace: 5,
    averageSpeed: 12,
  );
  final steps = DailyStepsModel(
    date: date.toIso8601String(),
    steps: 9000,
    goal: 8000,
    source: DailyStepsModel.sourceDevice,
    recordedAt: date,
    updatedAt: date,
  );
  SharedPreferences.setMockInitialValues({
    'historicoCorridas': [jsonEncode(run.toJson())],
    'dailyStepsHistory': [jsonEncode(steps.toJson())],
  });
}
