import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/screens/corridas/widgets/running_insights_panel.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fitai_12_running_metrics_test.dart' as fixtures;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser('a');
  });
  tearDown(() => AccountSessionLifecycle.setActiveUser(null));
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('RUN-METRIC-UI-$width summary readable at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: const TextScaler.linear(2),
              ),
              child: SingleChildScrollView(
                child: RunningInsightsPanel(
                  run: fixtures.run('ui', [300, 330], partial: 0.43),
                  showSummary: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resumo da corrida'), findsOneWidget);
      expect(find.textContaining('Maior distância'), findsOneWidget);
      expect(tester.takeException(), isNull);
      AccountSessionLifecycle.setActiveUser('b');
      await tester.pumpAndSettle();
      expect(find.text('Resumo da corrida'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
