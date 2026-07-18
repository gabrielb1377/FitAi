import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/create_plan_page.dart';
import 'package:fitai/screens/treinos/exercicio_detalhe_page.dart';
import 'package:fitai/screens/treinos/treino_detalhes_page.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/screens/treinos/treino_finalizado_page.dart';
import 'package:fitai/services/exercise_history_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PLAN-002 oferece os tres fluxos e abre o manual', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const CreatePlanPage()));

    expect(find.text('Plano com IA'), findsOneWidget);
    expect(find.text('Plano Manual'), findsOneWidget);
    expect(find.text('Importar Plano'), findsOneWidget);

    await tester.tap(find.text('Plano Manual'));
    await tester.pumpAndSettle();

    expect(find.text('Criar plano manual'), findsOneWidget);
    expect(find.text('Monte seu plano do seu jeito'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('PLAN-005 ate PLAN-008 preservam a hierarquia do plano', (
    tester,
  ) async {
    final plan = _plan();
    await tester.pumpWidget(_app(TreinoDetalhesPage(treino: plan)));

    expect(find.text('Plano Upper Lower'), findsOneWidget);
    expect(find.text('Proximo treino'), findsOneWidget);

    await tester.tap(find.text('Ver plano completo'));
    await tester.pumpAndSettle();
    expect(find.text('Semanas do plano'), findsOneWidget);

    await tester.tap(find.text('Semana 1'));
    await tester.pumpAndSettle();
    expect(find.text('Costas e Biceps'), findsOneWidget);
    expect(find.text('Remada curvada'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsOneWidget);

    await tester.tap(find.text('Remada curvada'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(ExercicioDetalhePage), findsOneWidget);
    expect(find.text('Execucao'), findsOneWidget);
    expect(find.text('Musculos'), findsOneWidget);
    expect(find.text('Dicas'), findsOneWidget);
  });

  testWidgets('PLAN-009 e PLAN-010 exibem os controles oficiais', (
    tester,
  ) async {
    final plan = _plan().somenteDia(_plan().planoDias.first);
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: plan)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PROGRESSO DO TREINO'), findsOneWidget);
    expect(find.text('EXERCÍCIO ATUAL'), findsOneWidget);
    expect(find.text('CONCLUIR SÉRIE'), findsOneWidget);
    expect(find.text('REST'), findsOneWidget);
    expect(find.text('Próximo exercício'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Coach IA'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Mais opções'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    SharedPreferences.setMockInitialValues({'xp': 80, 'nivel': 3});
    await tester.pumpWidget(
      _app(
        const TreinoFinalizadoPage(
          nomeTreino: 'Upper A',
          tempo: '45:10',
          volume: '8.200 kg',
          xp: 42,
          exerciciosConcluidos: 6,
          seriesConcluidas: 18,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Treino concluido!'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('+42'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(find.text('Ver resumo'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
  });

  testWidgets('PLAN-008 volta para a rota anterior quando ela existe', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ExercicioDetalhePage(exercicio: _exercise()),
              ),
            ),
            child: const Text('Abrir exercicio'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir exercicio'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir exercicio'), findsOneWidget);
  });

  testWidgets('PLAN-009 preserva a serie atual configurada no exercicio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(TreinoEmAndamentoPage(treino: _plan(sets: 4))),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pump();
    final completeSet = find.text('CONCLUIR SÉRIE');
    await tester.tap(completeSet);
    await tester.pump();
    expect(find.text('1 de 4'), findsOneWidget);

    await tester.ensureVisible(completeSet);
    await tester.tap(completeSet);
    await tester.pump();
    expect(find.text('2 de 4'), findsOneWidget);
  });

  testWidgets('PLAN-009 pede confirmacao antes de encerrar uma sessao', (
    tester,
  ) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();

    await tester.tap(find.byTooltip('Encerrar treino'));
    await tester.pumpAndSettle();

    expect(find.text('Sair do treino?'), findsOneWidget);
    expect(find.text('Sair sem salvar'), findsOneWidget);
  });

  testWidgets('PLAN-009 nao apresenta overflow em Android pequeno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(TreinoEmAndamentoPage(treino: _plan(sets: 4))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Mais opções'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('PLAN-009 salva historico uma unica vez ao concluir a sessao', (
    tester,
  ) async {
    final plan = _plan(sets: 1);
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: plan)));
    await tester.pump();

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pump();
    final completeSet = find.text('CONCLUIR SÉRIE');
    await tester.tap(completeSet);
    await tester.tap(completeSet);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byType(TreinoFinalizadoPage), findsOneWidget);
    final history = await const ExerciseHistoryService().loadExerciseHistory(
      _exercise(sets: 1),
    );
    expect(history.executions, hasLength(1));
    expect(history.executions.single.sets, hasLength(1));
  });

  testWidgets('PLAN-010 abre resumo e retorna pelo comando explicito', (
    tester,
  ) async {
    var returnedToPlan = false;
    await tester.pumpWidget(
      _app(
        TreinoFinalizadoPage(
          tempo: '41:20',
          volume: '4.200 kg',
          xp: 35,
          onVoltar: () => returnedToPlan = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await tester.pump();
    final viewSummary = find.text('Ver resumo');
    await tester.tap(viewSummary);
    await tester.pumpAndSettle();
    expect(find.text('Resumo da sessao concluida'), findsOneWidget);

    await tester.tap(find.text('Voltar para Planos'));
    await tester.pump();
    expect(returnedToPlan, isTrue);
  });
}

Widget _app(Widget home) {
  return MaterialApp(theme: AppTheme.dark, home: home);
}

TreinoModel _plan({int sets = 3}) {
  final exercise = _exercise(sets: sets);
  return TreinoModel(
    id: 'plan-test',
    nome: 'Plano Upper Lower',
    descricao: 'Plano de teste com dados completos.',
    objetivo: 'Hipertrofia',
    nivel: 'Intermediario',
    divisao: 'Upper Lower',
    tempoEstimado: 50,
    diasPorSemana: 1,
    planoDias: const [
      TreinoDiaModel(
        codigo: 'Dia A',
        nome: 'Costas e Biceps',
        ordem: 1,
        exercicioIds: ['remada-curvada'],
      ),
    ],
    criadoPorIA: false,
    exercicios: [exercise],
    dataCriacao: DateTime.now().toIso8601String(),
  );
}

ExercicioModel _exercise({int sets = 3}) {
  return ExercicioModel(
    id: 'remada-curvada',
    nome: 'Remada curvada',
    categoria: 'Costas',
    descricao: 'Movimento composto para dorsais.',
    comoExecutar: 'Mantenha a coluna neutra e puxe a barra.',
    cuidados: 'Evite arredondar a lombar.',
    musculos: const ['Dorsais'],
    musculosSecundarios: const ['Biceps'],
    equipamentos: const ['Barra'],
    locais: const ['Academia'],
    dificuldade: 'Intermediario',
    objetivo: 'Hipertrofia',
    imagem: '',
    video: '',
    tags: const ['Composto'],
    caloriasHora: 300,
    series: sets,
    repeticoes: '8-12',
    descansoSegundos: 90,
  );
}
