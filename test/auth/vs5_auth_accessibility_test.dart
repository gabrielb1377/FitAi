import 'dart:ui' show Tristate;

import 'package:fitai/design_system/components/fit_inputs.dart';
import 'package:fitai/features/auth/presentation/pages/login_page.dart';
import 'package:fitai/features/auth/presentation/pages/onboarding_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('VS5 Login expoe titulo, campos, erro e acao ao leitor de tela', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_host(const LoginPage()));

    final title = tester.getSemantics(
      find.bySemanticsLabel('Bem-vindo de volta.').first,
    );
    final email = tester.getSemantics(find.bySemanticsLabel('E-mail').first);
    final password = tester.getSemantics(find.bySemanticsLabel('Senha').first);
    final submit = tester.getSemantics(find.bySemanticsLabel('Entrar').first);

    expect(title.flagsCollection.isHeader, isTrue);
    expect(email.flagsCollection.isTextField, isTrue);
    expect(password.flagsCollection.isTextField, isTrue);
    expect(submit.flagsCollection.isButton, isTrue);

    await tester.tap(find.text('Entrar'));
    await tester.pump();
    final errorField = tester.getSemantics(find.byType(FitTextField).first);
    expect(errorField.hint, 'Informe um e-mail valido.');
    semantics.dispose();
  });

  testWidgets('VS5 Login recebe foco e permite travessia por teclado', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const LoginPage()));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final firstFocus = FocusManager.instance.primaryFocus;
    expect(firstFocus, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final secondFocus = FocusManager.instance.primaryFocus;
    expect(secondFocus, isNotNull);
    expect(secondFocus, isNot(same(firstFocus)));
  });

  testWidgets('VS5 Onboarding anuncia progresso, selecao e alvos de toque', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_host(const OnboardingPage()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Etapa 1 de 4'), findsOneWidget);
    final option = find.bySemanticsLabel('Hipertrofia').first;
    expect(tester.getSemantics(option).flagsCollection.isButton, isTrue);
    expect(
      tester.getSize(find.byType(OutlinedButton).first).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('Hipertrofia'));
    await tester.pump();
    expect(
      tester.getSemantics(option).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    await tester.scrollUntilVisible(
      find.text('Proximo'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Proximo'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ChoiceChip).first).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });
}

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);
