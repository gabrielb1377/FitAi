import 'package:fitai/screens/atividades_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('mostra Corridas e Passos mesmo sem dados locais', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: AtividadesPage(
          passos: 0,
          distancia: 0,
          velocidadeMedia: 0,
          segundos: 0,
          corridaIniciada: false,
          iniciarCorrida: () {},
          pararCorrida: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atividades'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Corridas'),
      320,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('activities-overview-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Corridas'), findsOneWidget);
    expect(find.text('Abrir Corridas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Passos'),
      320,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('activities-overview-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Passos'), findsOneWidget);
    expect(find.text('Abrir Passos'), findsOneWidget);
  });
}
