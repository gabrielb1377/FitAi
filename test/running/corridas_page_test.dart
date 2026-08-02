import 'package:fitai/screens/corridas/corridas_page.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('permite pausar, retomar e cancelar uma corrida ativa', (
    tester,
  ) async {
    final service = RunningSessionService.forTesting();
    await service.start();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CorridasPage(runningService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Finalizar'), findsOneWidget);
    expect(find.text('Cancelar corrida'), findsOneWidget);

    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();
    expect(service.isPaused, isTrue);
    expect(find.text('Retomar'), findsOneWidget);

    await tester.tap(find.text('Retomar'));
    await tester.pumpAndSettle();
    expect(service.isRunning, isTrue);

    await tester.tap(find.text('Cancelar corrida'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar corrida?'), findsOneWidget);

    await tester.tap(find.text('Cancelar corrida').last);
    await tester.pumpAndSettle();

    expect(service.hasActiveSession, isFalse);
  });
}
