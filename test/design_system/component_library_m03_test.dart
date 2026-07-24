import 'package:fitai/debug/design_system_showcase/pages/buttons_showcase_page.dart';
import 'package:fitai/debug/design_system_showcase/pages/cards_showcase_page.dart';
import 'package:fitai/debug/design_system_showcase/pages/common_showcase_page.dart';
import 'package:fitai/debug/design_system_showcase/pages/feedback_showcase_page.dart';
import 'package:fitai/debug/design_system_showcase/pages/inputs_showcase_page.dart';
import 'package:fitai/debug/design_system_showcase/pages/navigation_showcase_page.dart';
import 'package:fitai/design_system/fit_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) {
    return MaterialApp(
      theme: FitTheme.dark(),
      home: Scaffold(body: child),
    );
  }

  group('Component Library M03', () {
    testWidgets('botões expõem ação, loading e estado desabilitado', (
      tester,
    ) async {
      var presses = 0;
      await tester.pumpWidget(
        app(
          Column(
            children: [
              FitPrimaryButton(label: 'Salvar', onPressed: () => presses++),
              const FitLoadingButton(
                label: 'Processando',
                loading: true,
                onPressed: _noop,
              ),
              const FitDangerButton(
                label: 'Excluir',
                enabled: false,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(presses, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final danger = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Excluir'),
      );
      expect(danger.onPressed, isNull);
    });

    testWidgets('inputs controlados preservam o valor informado', (
      tester,
    ) async {
      final controller = TextEditingController();
      var sliderValue = 2.0;
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  FitEmailField(controller: controller),
                  FitStepper(
                    label: 'Dias',
                    value: sliderValue,
                    min: 1,
                    max: 4,
                    onChanged: (value) => setState(() => sliderValue = value),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'gabriel@fitia.dev');
      await tester.tap(find.byTooltip('Aumentar'));
      await tester.pump();

      expect(controller.text, 'gabriel@fitia.dev');
      expect(sliderValue, 3);
    });

    testWidgets('feedback e containers contextuais abrem corretamente', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FitTheme.dark(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    FitPrimaryButton(
                      label: 'Snack',
                      onPressed: () =>
                          const FitSnackBar(message: 'Salvo').show(context),
                    ),
                    FitPrimaryButton(
                      label: 'Sheet',
                      onPressed: () => FitBottomSheetContainer.show<void>(
                        context: context,
                        title: 'Ações',
                        child: const Text('Conteúdo'),
                      ),
                    ),
                    FitPrimaryButton(
                      label: 'Dialog',
                      onPressed: () => FitDialogContainer.show<void>(
                        context: context,
                        title: 'Confirmação',
                        message: 'Mensagem',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Snack'));
      await tester.pump();
      expect(find.text('Salvo'), findsOneWidget);

      await tester.tap(find.text('Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Ações'), findsOneWidget);
      Navigator.of(tester.element(find.text('Ações'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmação'), findsOneWidget);
    });

    testWidgets('showcase não apresenta overflow em celular estreito', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const pages = <Widget>[
        ButtonsShowcasePage(),
        InputsShowcasePage(),
        CardsShowcasePage(),
        NavigationShowcasePage(),
        FeedbackShowcasePage(),
        CommonShowcasePage(),
      ];

      for (final page in pages) {
        await tester.pumpWidget(
          MaterialApp(theme: FitTheme.dark(), home: page),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow em ${page.runtimeType}',
        );
      }
    });
  });
}

void _noop() {}
