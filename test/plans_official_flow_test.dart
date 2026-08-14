import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/create_plan_page.dart';
import 'package:fitai/screens/treinos/exercicio_detalhe_page.dart';
import 'package:fitai/screens/treinos/treino_detalhes_page.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/screens/treinos/treino_finalizado_page.dart';
import 'package:fitai/screens/exercicios/biblioteca_exercicios_page.dart';
import 'package:fitai/services/exercise_history_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PLAN-002 exibe o formulario oficial de criacao', (tester) async {
    await tester.pumpWidget(_app(const CreatePlanPage()));

    expect(find.text('Criar novo plano'), findsOneWidget);
    expect(find.text('Nome do plano'), findsOneWidget);
    expect(find.text('Objetivo'), findsOneWidget);
    expect(find.text('Nível'), findsOneWidget);
    expect(find.text('Divisão'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Descrição (opcional)'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Descrição (opcional)'), findsOneWidget);
    expect(find.byTooltip('Salvar plano'), findsOneWidget);
  });

  testWidgets('PLAN-003 ate PLAN-005 preservam a hierarquia do plano', (
    tester,
  ) async {
    final plan = _plan();
    await tester.pumpWidget(_app(TreinoDetalhesPage(treino: plan)));

    expect(find.text('Plano Upper Lower'), findsOneWidget);
    expect(find.text('Treinos do plano'), findsOneWidget);
    expect(find.text('Iniciar Dia A'), findsOneWidget);

    await tester.tap(find.text('Treinos do plano'));
    await tester.pumpAndSettle();
    expect(find.text('Treinos'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    expect(find.text('Costas e Biceps'), findsOneWidget);

    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();
    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Músculos trabalhados'), findsOneWidget);
    expect(find.text('Distribuição'), findsOneWidget);
  });

  testWidgets('sessao e finalizacao exibem os controles oficiais', (
    tester,
  ) async {
    final plan = _plan().somenteDia(_plan().planoDias.first);
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: plan)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PROGRESSO DO TREINO'), findsOneWidget);
    expect(find.text('EXERCICIO ATUAL'), findsOneWidget);
    expect(find.text('REGISTRAR SERIE'), findsOneWidget);
    expect(find.byTooltip('Registrar serie'), findsOneWidget);
    expect(find.text('Descanso'), findsOneWidget);
    await _scrollToQuickAction(tester, 'Mais opções');
    expect(find.text('Coach IA'), findsAtLeastNWidgets(1));
    expect(find.text('Histórico'), findsOneWidget);
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

  testWidgets('detalhe do exercicio volta para a rota anterior', (
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

  testWidgets('sessao preserva a serie atual configurada no exercicio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(TreinoEmAndamentoPage(treino: _plan(sets: 4))),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pump();
    final completeSet = find.byTooltip('Registrar serie');
    await tester.tap(completeSet);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 de 4'), findsOneWidget);

    await tester.ensureVisible(completeSet);
    await tester.tap(completeSet);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2 de 4'), findsOneWidget);
  });

  testWidgets('sessao pede confirmacao antes de encerrar', (tester) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();

    await tester.tap(find.byTooltip('Encerrar treino'));
    await tester.pumpAndSettle();

    expect(find.text('Sair do treino?'), findsOneWidget);
    expect(find.text('Sair sem salvar'), findsOneWidget);
  });

  testWidgets('sessao abre o Coach pelo atalho compacto', (tester) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();
    await _scrollToQuickAction(tester, 'Coach IA');

    await tester.tap(find.text('Coach IA').last);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Coach FitIA'), findsOneWidget);
  });

  testWidgets('sessao abre o histórico pelo atalho compacto', (tester) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();
    await _scrollToQuickAction(tester, 'Histórico');

    await tester.tap(find.text('Histórico'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Histórico do exercício'), findsOneWidget);
  });

  testWidgets('sessao abre o GIF pela midia principal', (tester) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byTooltip('Toque para ampliar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Toque para ampliar'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Execução de Remada curvada'), findsOneWidget);
  });

  testWidgets('sessao abre substituição sem alterar a série atual', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(TreinoEmAndamentoPage(treino: _plan(sets: 4))),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pump();
    await tester.tap(find.byTooltip('Registrar serie'));
    await tester.pump();
    expect(find.text('1 de 4'), findsOneWidget);

    await _scrollToQuickAction(tester, 'Mais opções');
    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trocar exercício').last);
    await tester.pumpAndSettle();

    expect(find.byType(BibliotecaExerciciosPage), findsOneWidget);
  });

  testWidgets('sessao concentra ações secundárias em Mais opções', (
    tester,
  ) async {
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump();
    await _scrollToQuickAction(tester, 'Mais opções');

    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();

    expect(find.text('Progressão'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Músculos'), findsOneWidget);
    expect(find.text('Trocar exercício'), findsOneWidget);
    expect(find.text('Ver GIF'), findsOneWidget);
    expect(find.text('Encerrar treino'), findsOneWidget);

    await tester.tap(find.text('Encerrar treino'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Sair do treino?'), findsOneWidget);
  });

  testWidgets('sessao nao apresenta overflow em Android pequeno', (
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

    await _scrollToQuickAction(tester, 'Mais opções');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sessao salva historico uma unica vez ao concluir', (
    tester,
  ) async {
    final plan = _plan(sets: 1);
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: plan)));
    await tester.pump();

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pump();
    final completeSet = find.byTooltip('Registrar serie');
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

  testWidgets('finalizacao abre resumo e retorna pelo comando explicito', (
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

  testWidgets('compartilhamento mantém estado honesto sem integração nativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const TreinoFinalizadoPage(
          nomeTreino: 'Upper A',
          tempo: '41:20',
          volume: '4.200 kg',
          xp: 35,
          exerciciosConcluidos: 6,
        ),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Compartilhar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Compartilhar'));
    await tester.pumpAndSettle();

    expect(find.text('Prévia sem dados pessoais'), findsOneWidget);
    expect(find.text('Compartilhamento indisponível'), findsOneWidget);
  });
}

Widget _app(Widget home) {
  return MaterialApp(theme: AppTheme.dark, home: home);
}

Future<void> _scrollToQuickAction(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
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
