import 'package:fitai/design_system/design_system.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:fitai/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: FitTheme.dark(),
    home: Scaffold(body: SafeArea(child: child)),
  );
}

void main() {
  test('barrel oficial expoe tema e tokens compativeis', () {
    final legacyTheme = AppTheme.dark;
    final officialTheme = FitTheme.dark();

    expect(legacyTheme.brightness, Brightness.dark);
    expect(legacyTheme.colorScheme.primary, officialTheme.colorScheme.primary);
    expect(AppColors.primary, FitColors.primary);
    expect(AppRadii.md, FitRadius.card);
    expect(AppMotion.normal, FitDuration.legacyAppNormal);
  });

  testWidgets(
    'componentes oficiais e legados preservam callback e renderizacao',
    (tester) async {
      var fitCalls = 0;
      var appCalls = 0;

      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: Column(
              children: [
                FitButton(label: 'Acao Fit', onPressed: () => fitCalls++),
                AppButton(label: 'Acao App', onPressed: () => appCalls++),
                const FitCard(child: Text('Card Fit')),
                const AppGradientCard(child: Text('Card App')),
                const FitChip(label: 'Chip Fit'),
                const AppChip(label: 'Chip App'),
                FitButton(
                  label: 'Fit indisponivel',
                  onPressed: () => fitCalls++,
                  enabled: false,
                ),
                const SizedBox(height: FitSpacing.s12),
                FitBottomNavigation(
                  selectedIndex: 0,
                  destinations: const [
                    FitNavigationDestination(
                      label: 'Home',
                      icon: FitIcons.home,
                    ),
                    FitNavigationDestination(
                      label: 'Planos',
                      icon: FitIcons.plans,
                    ),
                  ],
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Acao Fit'));
      await tester.tap(find.text('Acao App'));
      await tester.tap(find.text('Fit indisponivel'));
      await tester.pump();

      expect(fitCalls, 1);
      expect(appCalls, 1);
      expect(find.text('Card Fit'), findsOneWidget);
      expect(find.text('Card App'), findsOneWidget);
      expect(find.text('Chip Fit'), findsOneWidget);
      expect(find.text('Chip App'), findsOneWidget);
      expect(find.byType(FitBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
