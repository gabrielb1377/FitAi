import 'package:fitai/features/activities/domain/steps_data_source.dart';
import 'package:fitai/screens/corridas/corridas_page.dart';
import 'package:fitai/screens/passos_page.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/steps_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final viewport in const <Size>[
    Size(320, 800),
    Size(600, 900),
    Size(1024, 768),
    Size(768, 360),
  ]) {
    testWidgets(
      'Corridas não gera overflow em ${viewport.width}x${viewport.height}',
      (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final service = RunningSessionService.forTesting();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: CorridasPage(runningService: service),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await service.discardActiveSession();
      },
    );
  }

  testWidgets('Passos suporta largura pequena e texto ampliado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = StepsService.forTesting(
      now: () => DateTime(2026, 8, 4, 10),
      seedEnabled: true,
      seedDataSource: const SeedStepsDataSource(steps: 7600),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: PassosPage(passos: 0, stepsService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passos de hoje'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
