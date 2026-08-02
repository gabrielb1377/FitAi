import 'package:fitai/features/activities/domain/steps_data_source.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/screens/passos_page.dart';
import 'package:fitai/screens/widgets/activities/steps_history_section.dart';
import 'package:fitai/services/steps_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('mostra resumo, período, calendário e histórico de dados seed', (
    tester,
  ) async {
    final service = StepsService.forTesting(
      now: () => DateTime(2026, 8, 4, 10),
      seedEnabled: true,
      seedDataSource: const SeedStepsDataSource(steps: 7600),
    );

    await tester.pumpWidget(_host(service));
    await tester.pumpAndSettle();

    expect(find.text('Passos de hoje'), findsOneWidget);
    expect(find.text('Visão semanal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Calendário'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('passos-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Calendário'), findsOneWidget);
  });

  testWidgets('histórico apresenta um resumo diário com fonte e meta', (
    tester,
  ) async {
    final record = DailyStepsModel(
      date: '2026-08-04',
      steps: 9000,
      goal: 8000,
      source: DailyStepsModel.sourceManual,
      recordedAt: DateTime(2026, 8, 4, 8),
      updatedAt: DateTime(2026, 8, 4, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepsHistorySection(
            records: [record],
            periodLabel: 'Últimos 7 dias',
          ),
        ),
      ),
    );

    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('9000'), findsOneWidget);
    expect(find.textContaining('Registro manual'), findsOneWidget);
  });

  testWidgets('edita meta com texto ampliado sem overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = StepsService.forTesting(
      now: () => DateTime(2026, 8, 4, 10),
      seedEnabled: true,
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: _host(service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9000');
    await tester.tap(find.text('Salvar meta'));
    await tester.pumpAndSettle();

    expect(service.dailyGoal, 9000);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(StepsService service) {
  return MaterialApp(home: PassosPage(passos: 0, stepsService: service));
}
