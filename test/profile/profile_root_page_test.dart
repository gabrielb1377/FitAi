import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_support.dart';

void main() {
  testWidgets('renderiza o dashboard com dados canonicos do Perfil', (
    tester,
  ) async {
    final controller = profileTestController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(profileTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Gabriel'), findsOneWidget);
    expect(find.text('Nivel 18'), findsWidgets);
    expect(find.textContaining('XP'), findsWidgets);
    expect(find.text('Dias ativos'), findsWidgets);
    expect(find.text('Treinos na semana'), findsWidgets);
    expect(find.text('Supino Reto'), findsOneWidget);
    expect(find.text('Conquistas'), findsOneWidget);
    expect(find.text('Atalhos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('informa dados locais parciais sem impedir a leitura', (
    tester,
  ) async {
    final controller = profileTestController(partial: true);
    addTearDown(controller.dispose);

    await tester.pumpWidget(profileTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Dados locais parciais'), findsOneWidget);
    expect(find.text('Upper A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('apresenta estado vazio quando nao ha dados locais', (
    tester,
  ) async {
    final controller = profileTestController(empty: true);
    addTearDown(controller.dispose);

    await tester.pumpWidget(profileTestApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Seu Perfil esta pronto para comecar'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oferece rotulos semanticos para as acoes e o resumo', (
    tester,
  ) async {
    final controller = profileTestController();
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(profileTestApp(controller));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('Resumo do perfil de Gabriel')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Editar perfil')), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('Exercicio favorito Supino Reto')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('abre o placeholder honesto de exportacao de dados', (
    tester,
  ) async {
    final controller = profileTestController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(profileTestApp(controller));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Exportar dados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Exportacao ainda indisponivel'), findsOneWidget);
  });

  testWidgets('preserva layout sem overflow em telas de 320 a 1440 pixels', (
    tester,
  ) async {
    const viewports = <Size>[
      Size(320, 640),
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(600, 960),
      Size(768, 1024),
      Size(1024, 768),
      Size(1440, 900),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in viewports) {
      final controller = profileTestController();
      addTearDown(controller.dispose);
      tester.view.physicalSize = viewport;

      await tester.pumpWidget(
        profileTestApp(
          controller,
          textScaler: viewport.width == 320
              ? const TextScaler.linear(2)
              : const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Perfil em $viewport');
    }
  });
}
