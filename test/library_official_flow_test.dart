import 'dart:async';

import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/screens/exercicios/biblioteca_exercicios_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LIB-001 apresenta grupos e exercícios em destaque', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Grupos musculares'), findsOneWidget);
    expect(find.text('Peito'), findsWidgets);
    expect(find.text('Exercícios em destaque'), findsOneWidget);
    expect(find.text('Supino Reto com Barra'), findsOneWidget);
    expect(find.byTooltip('Filtros'), findsOneWidget);
  });

  testWidgets('LIB-002 explora e pesquisa sem perder o catálogo', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver todos').first);
    await tester.pumpAndSettle();

    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Populares'), findsOneWidget);
    expect(find.text('Recentes'), findsOneWidget);
    expect(find.text('A-Z'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'remada');
    await tester.pump();
    expect(find.text('Remada na Polia Baixa'), findsOneWidget);
    expect(find.text('Supino Reto com Barra'), findsNothing);
  });

  testWidgets('pesquisa local aceita ingles, plural e ordem livre', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bench press');
    await tester.pump();
    expect(find.text('Supino Reto com Barra'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'barras supino');
    await tester.pump();
    expect(find.text('Supino Reto com Barra'), findsOneWidget);
  });

  testWidgets('LIB-003 aplica filtros oficiais', (tester) async {
    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Grupo muscular'), findsOneWidget);
    expect(find.text('Nível'), findsOneWidget);
    expect(find.text('Equipamento'), findsOneWidget);
    expect(find.text('Ordenar por'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Movimento'), findsOneWidget);
    expect(find.text('Objetivo'), findsOneWidget);
    expect(find.textContaining('resultados'), findsOneWidget);

    await tester.tap(find.text('Peito').last);
    await tester.scrollUntilVisible(
      find.text('Intermediário').last,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('library-filters-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Intermediário').last);
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Supino Reto com Barra'), findsOneWidget);
    expect(find.text('Agachamento Livre'), findsNothing);
  });

  testWidgets('LIB-004 a LIB-007 preservam resumo e abas do exercício', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Supino Reto com Barra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supino Reto com Barra'));
    await tester.pumpAndSettle();

    expect(find.text('Músculos trabalhados'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Adicionar ao plano'), findsOneWidget);

    await tester.ensureVisible(find.text('Ver mais'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mais'));
    await tester.pumpAndSettle();
    expect(find.text('Instruções'), findsOneWidget);
    expect(find.text('Ver animação 3D'), findsOneWidget);

    await tester.tap(find.text('Músculos'));
    await tester.pumpAndSettle();
    expect(find.text('Músculos secundários'), findsOneWidget);

    await tester.tap(find.text('Erros comuns'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(4));
  });

  testWidgets('LIB-008 abre favoritos pela ação contextual', (tester) async {
    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Favoritar').first);
    await tester.pumpAndSettle();
    expect(find.text('Ver favoritos'), findsOneWidget);

    await tester.tap(find.text('Ver favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Supino Reto com Barra'), findsOneWidget);
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
  });

  testWidgets('relacionados permitem abrir comparacao objetiva', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Supino Reto com Barra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supino Reto com Barra'));
    await tester.pumpAndSettle();
    final compareButton = find
        .byKey(const ValueKey('library_compare_button'))
        .last;
    final detailScroll = find
        .descendant(
          of: find.byKey(const ValueKey('LIB-004')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      compareButton,
      240,
      scrollable: detailScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(compareButton);
    await tester.pumpAndSettle();

    expect(find.text('Comparar exercicios'), findsOneWidget);
    expect(find.text('Padrao de movimento'), findsOneWidget);
    expect(find.text('Equipamento'), findsWidgets);
  });

  testWidgets('loading, erro, vazio e offline possuem estados dedicados', (
    tester,
  ) async {
    final pending = Completer<List<ExercicioModel>>();
    final loadingController = LibraryCatalogController(
      catalogLoader: () => pending.future,
    );
    addTearDown(loadingController.dispose);
    await tester.pumpWidget(
      _app(BibliotecaExerciciosPage(controller: loadingController)),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Carregando conteudo'), findsWidgets);

    pending.complete(_exercises());
    await tester.pumpAndSettle();

    final errorController = LibraryCatalogController(
      catalogLoader: () async => throw StateError('catálogo indisponível'),
    );
    addTearDown(errorController.dispose);
    await tester.pumpWidget(
      _app(BibliotecaExerciciosPage(controller: errorController)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca indisponível'), findsOneWidget);

    final emptyController = LibraryCatalogController(
      catalogLoader: () async => const [],
    );
    addTearDown(emptyController.dispose);
    await tester.pumpWidget(
      _app(BibliotecaExerciciosPage(controller: emptyController)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca vazia'), findsOneWidget);

    await tester.pumpWidget(_app(_library(offline: true)));
    await tester.pumpAndSettle();
    expect(find.text('Exercícios salvos no dispositivo.'), findsOneWidget);
  });

  testWidgets('biblioteca não apresenta overflow em celular estreito', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_library()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Ver todos').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('recentes permanecem locais e ordenados pelo ultimo acesso', () async {
    final controller = LibraryCatalogController(
      catalogLoader: () async => _exercises(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.registerViewed(_exercises()[1]);
    await controller.registerViewed(_exercises().first);
    controller.showRecent();

    expect(controller.recentExercises.first.id, 'peito_001');
    expect(controller.visibleExercises.map((item) => item.id), [
      'peito_001',
      'pernas_001',
    ]);
  });
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.dark, home: home);

Widget _library({bool offline = false}) {
  return BibliotecaExerciciosPage(
    offline: offline,
    controller: LibraryCatalogController(
      catalogLoader: () async => _exercises(),
    ),
  );
}

List<ExercicioModel> _exercises() => [
  _exercise(
    id: 'peito_001',
    name: 'Supino Reto com Barra',
    category: 'Peito',
    muscles: const ['Peitoral Maior'],
    secondary: const ['Tríceps', 'Ombros'],
    equipment: const ['Barra', 'Banco'],
  ),
  _exercise(
    id: 'pernas_001',
    name: 'Agachamento Livre',
    category: 'Pernas',
    muscles: const ['Quadríceps'],
    secondary: const ['Glúteos'],
    equipment: const ['Barra'],
    difficulty: 'Avançado',
  ),
  _exercise(
    id: 'costas_001',
    name: 'Remada na Polia Baixa',
    category: 'Costas',
    muscles: const ['Dorsal'],
    equipment: const ['Cabo'],
  ),
  _exercise(
    id: 'ombros_001',
    name: 'Desenvolvimento com Halteres',
    category: 'Ombros',
    muscles: const ['Deltóide'],
    equipment: const ['Halteres'],
  ),
  _exercise(
    id: 'biceps_001',
    name: 'Rosca Direta com Barra',
    category: 'Bíceps',
    muscles: const ['Bíceps'],
    equipment: const ['Barra'],
    difficulty: 'Iniciante',
  ),
  _exercise(
    id: 'triceps_001',
    name: 'Tríceps Testa',
    category: 'Tríceps',
    muscles: const ['Tríceps'],
    equipment: const ['Barra'],
  ),
];

ExercicioModel _exercise({
  required String id,
  required String name,
  required String category,
  required List<String> muscles,
  List<String> secondary = const [],
  required List<String> equipment,
  String difficulty = 'Intermediário',
}) {
  return ExercicioModel(
    id: id,
    nome: name,
    categoria: category,
    descricao: 'Exercício composto para desenvolver força e massa muscular.',
    comoExecutar:
        'Ajuste a posição. Mantenha os apoios firmes. Desça com controle. '
        'Complete a amplitude. Retorne à posição inicial.',
    cuidados:
        'Não arqueie demais as costas. Não perca o apoio dos pés. '
        'Não acelere a descida. Evite abrir demais os cotovelos.',
    musculos: muscles,
    musculosSecundarios: secondary,
    equipamentos: equipment,
    locais: const ['Academia'],
    dificuldade: difficulty,
    objetivo: 'Hipertrofia',
    imagem: '',
    video: '',
    tags: const ['Composto'],
    caloriasHora: 320,
    series: 4,
    repeticoes: '8-12',
    descansoSegundos: 90,
  );
}
