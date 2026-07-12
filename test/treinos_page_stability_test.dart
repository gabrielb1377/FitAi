import 'package:fitai/screens/treinos/treinos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre sem RangeError quando nao existem planos pessoais', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TreinosPage()));
    await tester.pumpAndSettle();

    expect(find.text('Meus Planos'), findsOneWidget);
    expect(find.text('Voce ainda nao criou nenhum plano.'), findsOneWidget);
    expect(find.text('Criar com IA'), findsOneWidget);
    expect(find.text('Criar manualmente'), findsOneWidget);
    expect(find.text('Explorar planos prontos'), findsOneWidget);
    expect(find.textContaining('Meus planos ('), findsNothing);
    expect(find.text('Nenhum plano ativo'), findsNothing);
  });
}
