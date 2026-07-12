import 'package:fitai/screens/perfil/perfil_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('organiza o perfil mesmo sem historico local', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: PerfilPage(
          nome: 'Gabriel',
          peso: '70 kg',
          altura: '175 cm',
          idade: '18',
          nivel: 3,
          conquistaPrimeiraCorrida: false,
          conquista10Km: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gabriel'), findsOneWidget);
    expect(find.text('Resumo de evolucao'), findsOneWidget);
    expect(find.text('Seus recordes aparecerao aqui.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Metas'), 250);
    expect(find.text('Metas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Configuracoes'), 250);
    expect(find.text('Configuracoes'), findsOneWidget);
  });
}
