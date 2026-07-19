import 'package:fitai/screens/treinos/treinos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('abre sem RangeError quando nao existem planos pessoais', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: TreinosPage(
          useDeveloperFallback: false,
          checkBackend: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Planos'), findsOneWidget);
    expect(find.text('Meus planos'), findsWidgets);
    expect(find.text('Seu proximo plano comeca aqui.'), findsOneWidget);
    expect(find.text('Criar com IA'), findsOneWidget);
    expect(find.text('Criar manualmente'), findsOneWidget);
    expect(find.text('Explorar biblioteca'), findsOneWidget);
    expect(find.textContaining('Meus planos ('), findsNothing);
    expect(find.text('Nenhum plano ativo'), findsNothing);
  });
}
