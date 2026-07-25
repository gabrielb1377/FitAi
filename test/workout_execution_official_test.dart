import 'dart:convert';

import 'package:fitai/features/plans/workout_execution/pages/workout_preview_page.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/historico_serie_treino_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_day_data.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('WORK-001 mostra a prévia com dados reais do plano', (
    tester,
  ) async {
    final plan = _plan();
    final day = buildPlanDays(plan).first;

    await tester.pumpWidget(_app(WorkoutPreviewPage(plan: plan, day: day)));

    expect(find.text('Upper A'), findsOneWidget);
    expect(find.text('Resumo do treino'), findsOneWidget);
    expect(find.text('Destaques'), findsOneWidget);
    expect(find.text('Ver lista'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump();
    expect(find.text('Iniciar treino'), findsOneWidget);
  });

  testWidgets('WORK-003 mantém descanso entre séries inline', (tester) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();

    await _tapCompleteSet(tester);

    expect(find.text('Descanso entre séries'), findsOneWidget);
    expect(find.text('+15 s'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);

    await _ensureAndTap(tester, find.text('Pausar'));
    await tester.pump();
    expect(find.text('Descanso pausado'), findsOneWidget);

    await _ensureAndTap(tester, find.text('Retomar'));
    await tester.pump();
    expect(find.text('Descanso entre séries'), findsOneWidget);
  });

  testWidgets(
    'WORK-006 a WORK-005 respeitam resumo, descanso e próximo exercício',
    (tester) async {
      await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
      await tester.pump();

      await _tapCompleteSet(tester);
      await _ensureAndTap(tester, find.text('Pular').last);
      await tester.pump();
      await _tapCompleteSet(tester);
      await _ensureAndTap(tester, find.text('Pular').last);
      await tester.pump();
      await _tapCompleteSet(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Exercício concluído'), findsOneWidget);
      await tester.tap(find.text('Iniciar descanso'));
      await tester.pump();
      expect(find.text('Recupere-se'), findsOneWidget);

      await _ensureAndTap(tester, find.text('Pular'));
      await tester.pump();
      expect(find.text('Próximo exercício'), findsOneWidget);

      await tester.tap(find.text('Começar exercício'));
      await tester.pump();
      expect(find.text('Agachamento livre'), findsOneWidget);
    },
  );

  testWidgets('WORK-018 pausa e oferece descarte com confirmação', (
    tester,
  ) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Mais opções'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();

    expect(find.text('Treino pausado'), findsOneWidget);
    expect(find.text('Continuar treino'), findsOneWidget);
    expect(find.text('Descartar treino'), findsOneWidget);

    await tester.tap(find.text('Descartar treino'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar treino?'), findsOneWidget);
  });

  testWidgets(
    'execução não sofre overflow em tela estreita com texto ampliado',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          TreinoEmAndamentoPage(treino: _plan(longExerciseName: true)),
          textScale: 1.3,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('WORK-009 combina histórico persistido e sessão atual', (
    tester,
  ) async {
    final saved = HistoricoSerieTreinoModel(
      id: 'history-set-1',
      treinoId: 'old-workout',
      sessaoTreinoId: 'old-session',
      nomeTreino: 'Upper anterior',
      exercicioId: 'supino-reto',
      nomeExercicio: 'Supino reto',
      serieNumero: 1,
      peso: 80,
      repeticoes: 10,
      descansoSegundos: 60,
      dataHora: DateTime(2026, 7, 11, 10),
    );
    SharedPreferences.setMockInitialValues({
      'historicoSeriesTreino': [jsonEncode(saved.toJson())],
    });

    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();
    await _tapCompleteSet(tester);
    await _ensureAndTap(tester, find.text('Pular').last);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Histórico'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Histórico'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Histórico do exercício'), findsOneWidget);
    expect(find.text('Sessão atual'), findsOneWidget);
    expect(find.text('0 kg × 12 reps'), findsOneWidget);
    expect(find.text('11/07/2026'), findsOneWidget);
    expect(find.text('80 kg × 10 reps'), findsOneWidget);
    expect(find.text('Nenhuma série registrada ainda'), findsNothing);
  });

  testWidgets('concluir série bloqueia toque duplo', (tester) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();

    final complete = find.text('CONCLUIR SÉRIE');
    await tester.scrollUntilVisible(
      complete,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(complete);
    await tester.tap(complete);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1 de 3'), findsOneWidget);
  });

  testWidgets('carga e repetições sobrevivem à navegação entre exercícios', (
    tester,
  ) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '9');
    await tester.enterText(fields.at(1), '42,5');
    await tester.tap(find.text('Próximo exercício'));
    await tester.pump();
    await tester.tap(find.text('Anterior'));
    await tester.pump();

    final restored = tester.widgetList<TextField>(find.byType(TextField));
    expect(restored.elementAt(0).controller?.text, '9');
    expect(restored.elementAt(1).controller?.text, '42,5');
  });
}

Future<void> _tapCompleteSet(WidgetTester tester) async {
  final complete = find.text('CONCLUIR SÉRIE');
  if (complete.evaluate().isEmpty) {
    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pump();
  }
  await tester.ensureVisible(complete);
  await tester.pump();
  await tester.tap(complete);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _ensureAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Widget _app(Widget home, {double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: home,
    ),
  );
}

TreinoModel _plan({bool longExerciseName = false}) {
  final first = _exercise(
    id: 'supino-reto',
    name: longExerciseName
        ? 'Supino reto com barra em banco inclinado controlado'
        : 'Supino reto',
  );
  final second = _exercise(id: 'agachamento-livre', name: 'Agachamento livre');
  return TreinoModel(
    id: 'workout-execution-test',
    nome: 'Upper A',
    descricao: 'Treino de teste.',
    objetivo: 'Hipertrofia',
    nivel: 'Intermediário',
    divisao: 'Upper / Lower',
    tempoEstimado: 50,
    diasPorSemana: 1,
    planoDias: const [
      TreinoDiaModel(
        codigo: 'Dia A',
        nome: 'Upper A',
        ordem: 1,
        exercicioIds: ['supino-reto', 'agachamento-livre'],
      ),
    ],
    criadoPorIA: false,
    exercicios: [first, second],
    dataCriacao: DateTime(2026).toIso8601String(),
  );
}

ExercicioModel _exercise({required String id, required String name}) {
  return ExercicioModel(
    id: id,
    nome: name,
    categoria: 'Peito',
    descricao: 'Exercício de teste.',
    comoExecutar: 'Executar com controle.',
    cuidados: 'Manter técnica.',
    musculos: const ['Peito'],
    musculosSecundarios: const ['Tríceps'],
    equipamentos: const ['Barra'],
    locais: const ['Academia'],
    dificuldade: 'Intermediário',
    objetivo: 'Hipertrofia',
    imagem: '',
    video: '',
    tags: const ['Composto'],
    caloriasHora: 300,
    series: 3,
    repeticoes: '8-12',
    descansoSegundos: 60,
  );
}
