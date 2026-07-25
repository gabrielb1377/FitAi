import 'package:fitai/features/plans/workout_execution/pages/workout_preview_page.dart';
import 'package:fitai/models/exercicio_model.dart';
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

    expect(find.text('Prévia do treino'), findsOneWidget);
    expect(find.text('Upper A'), findsNWidgets(2));
    expect(find.text('Exercícios do treino'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -560));
    await tester.pump();
    expect(find.text('Iniciar treino'), findsOneWidget);
    expect(find.text('Ver lista de exercícios'), findsOneWidget);
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
  await tester.pump();
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
