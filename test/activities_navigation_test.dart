import 'package:fitai/screens/corridas/corridas_page.dart';
import 'package:fitai/screens/passos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('voltar de Corridas restaura a rota anterior', (tester) async {
    await tester.pumpWidget(_host(_corridasPage()));
    await tester.tap(find.text('Abrir destino'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Corridas'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Hub de atividades'), findsOneWidget);
  });

  testWidgets('voltar de Passos restaura a rota anterior', (tester) async {
    await tester.pumpWidget(_host(const PassosPage(passos: 0)));
    await tester.tap(find.text('Abrir destino'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Passos'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Hub de atividades'), findsOneWidget);
  });
}

Widget _host(Widget destination) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hub de atividades'),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => destination),
                ),
                child: const Text('Abrir destino'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

CorridasPage _corridasPage() => const CorridasPage();
