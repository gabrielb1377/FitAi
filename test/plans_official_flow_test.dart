import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/create_plan_page.dart';
import 'package:fitai/screens/treinos/exercicio_detalhe_page.dart';
import 'package:fitai/screens/treinos/treino_detalhes_page.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/screens/treinos/treino_finalizado_page.dart';
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

    expect(find.text('Tempo total'), findsOneWidget);
    expect(find.text('Concluir serie'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Descanso'), findsOneWidget);

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
}

Widget _app(Widget home) {
  return MaterialApp(theme: AppTheme.dark, home: home);
}

TreinoModel _plan() {
  final exercise = ExercicioModel(
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
    series: 3,
    repeticoes: '8-12',
    descansoSegundos: 90,
  );
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
