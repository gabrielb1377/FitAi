import 'dart:async';

import 'package:fitai/design_system/fit_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {TextScaler? textScaler}) {
  return MaterialApp(
    theme: FitTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
      child: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

void main() {
  testWidgets(
    'FitButton executa callback, respeita disabled e bloqueia duplo toque async',
    (tester) async {
      var syncCalls = 0;
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              FitButton(label: 'Salvar', onPressed: () => syncCalls++),
              FitButton(
                label: 'Indisponivel',
                onPressed: () => syncCalls++,
                enabled: false,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Salvar'));
      await tester.tap(find.text('Indisponivel'));
      expect(syncCalls, 1);

      final completer = Completer<void>();
      var asyncCalls = 0;
      await tester.pumpWidget(
        _app(
          FitButton(
            label: 'Enviar',
            onPressedAsync: () {
              asyncCalls++;
              return completer.future;
            },
          ),
        ),
      );

      await tester.tap(find.text('Enviar'));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      expect(asyncCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.text('Enviar'), findsOneWidget);
    },
  );

  testWidgets(
    'FitCard clicavel e chip selecionavel preservam callbacks e estado',
    (tester) async {
      var tapped = false;
      var selected = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  FitCard(
                    title: 'Resumo',
                    onTap: () => tapped = true,
                    variant: FitCardVariant.clickable,
                    child: const Text('Conteudo'),
                  ),
                  FitFilterChip(
                    label: 'Filtro',
                    selected: selected,
                    onSelected: (value) => setState(() => selected = value),
                    variant: FitChipVariant.selectable,
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Resumo'));
      await tester.tap(find.text('Filtro'));
      await tester.pump();

      expect(tapped, isTrue);
      expect(selected, isTrue);
    },
  );

  testWidgets('FitSearchField limpa valor e chama busca submetida', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'supino');
    addTearDown(controller.dispose);
    String? submitted;
    await tester.pumpWidget(
      _app(
        FitSearchField(
          controller: controller,
          label: 'Buscar exercicios',
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pump();
    expect(controller.text, isEmpty);

    await tester.enterText(find.byType(TextField), 'agachamento');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submitted, 'agachamento');
  });

  testWidgets(
    'FitProgress normaliza limites e estados basicos suportam texto ampliado',
    (tester) async {
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: Column(
              children: [
                const FitProgressBar(value: 2, label: 'Meta'),
                const FitCircularProgress(value: -1, showPercentage: true),
                FitEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Sem itens',
                  description: 'Crie o primeiro item.',
                  actionLabel: 'Criar',
                  onAction: () {},
                ),
                FitErrorState(error: 'Falha temporaria.', onRetry: () {}),
              ],
            ),
          ),
          textScaler: const TextScaler.linear(1.5),
        ),
      );

      final linear = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final circular = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator).first,
      );
      expect(linear.value, 1);
      expect(circular.value, 0);
      expect(find.text('Sem itens'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
