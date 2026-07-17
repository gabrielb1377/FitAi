import 'package:fitai/features/home/presentation/controllers/home_controller.dart';
import 'package:fitai/features/home/presentation/pages/home_coach_page.dart';
import 'package:fitai/features/home/presentation/pages/home_goals_page.dart';
import 'package:fitai/features/home/presentation/pages/home_page.dart';
import 'package:fitai/design_system/fit_design_system.dart';
import 'package:fitai/models/fitai_meta_model.dart';
import 'package:fitai/screens/corridas/corridas_page.dart';
import 'package:fitai/screens/passos_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('abre o Coach a partir da Home', (tester) async {
    await _pumpHome(tester);

    await _tapVisible(tester, find.text('Abrir Coach'));

    expect(find.byType(HomeCoachPage), findsOneWidget);
  });

  testWidgets('abre Metas a partir da Home', (tester) async {
    await _pumpHome(tester);

    await _tapVisible(tester, find.text('Ver metas').first);

    expect(find.byType(HomeGoalsPage), findsOneWidget);
  });

  testWidgets('abre Corridas pelo acesso rapido', (tester) async {
    await _pumpHome(tester);

    await _tapVisible(
      tester,
      find.widgetWithText(FitQuickActionCard, 'Corridas'),
    );

    expect(find.byType(CorridasPage), findsOneWidget);
  });

  testWidgets('abre Passos pelo acesso rapido', (tester) async {
    await _pumpHome(tester);

    await _tapVisible(
      tester,
      find.widgetWithText(FitQuickActionCard, 'Passos'),
    );

    expect(find.byType(PassosPage), findsOneWidget);
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  final controller = HomeController(
    historyLoader: () async => const [],
    coachLoader: () async => const [],
    goalsLoader: () async => const FitaiMetasResumo(metas: []),
    achievementsLoader: () async => const [],
    notificationsLoader: () async => const [],
    networkCheck: () async => true,
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: HomePage(
        nome: 'Atleta',
        distancia: 0,
        passos: 0,
        xp: 0,
        nivel: 1,
        controller: controller,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}
