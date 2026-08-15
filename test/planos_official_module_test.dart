import 'package:fitai/features/plans/presentation/pages/planos_official_plan_pages.dart';
import 'package:fitai/design_system/fit_design_system.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_root_page.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_wizards.dart';
import 'package:fitai/features/plans/presentation/widgets/planos_official_primitives.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('PLAN-001 preserva estado vazio e atalhos de criacao', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PlanosOfficialRootPage(
          useDeveloperFallback: false,
          checkBackend: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Planos'), findsOneWidget);
    expect(find.text('Seu proximo plano comeca aqui'), findsOneWidget);
    expect(find.text('Criar com IA'), findsOneWidget);
    expect(find.text('Explorar biblioteca'), findsOneWidget);
  });

  testWidgets('PLAN-002 e PLAN-003 mantem o wizard de IA', (tester) async {
    await tester.pumpWidget(_app(const PlanosAiGoalPage()));

    expect(find.text('Qual o seu objetivo principal?'), findsOneWidget);
    expect(find.byType(PlanosChoiceTile), findsNWidgets(5));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Personalize seu plano'), findsOneWidget);
    expect(find.text('Gerar meu plano'), findsOneWidget);
  });

  testWidgets('PLAN-001 abre detalhe e preserva a criacao em sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(PlanosOfficialRootPage(checkBackend: () async => false)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar plano'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanosPlanDetailPage), findsOneWidget);

    Navigator.of(tester.element(find.byType(PlanosPlanDetailPage))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Criar plano'));
    await tester.pumpAndSettle();
    expect(find.text('Como voce quer criar?'), findsOneWidget);

    await tester.tap(find.text('Criar com IA'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanosAiGoalPage), findsOneWidget);

    Navigator.of(tester.element(find.byType(PlanosAiGoalPage))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mais opcoes de planos'));
    await tester.pumpAndSettle();
    expect(find.text('Calendario e lembretes'), findsOneWidget);
    expect(find.text('Comparar planos'), findsOneWidget);
    expect(find.text('Historico de planos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PLAN-006 a PLAN-010 exibem fluxo manual sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const PlanosManualGoalPage()));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Estrutura do plano'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Seus treinos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PLAN-013 a PLAN-017 abrem detalhe, semana e estatisticas', (
    tester,
  ) async {
    final plan = _plan();
    await tester.pumpWidget(
      _app(
        PlanosPlanDetailPage(
          plan: plan,
          progress: PlanProgressSnapshot.empty(plan),
        ),
      ),
    );

    expect(find.byType(PlanosPlanDetailPage), findsOneWidget);
    expect(find.byType(FitMetricRail), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ver semana'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ver semana'));
    await tester.pumpAndSettle();
    expect(find.text('Esta semana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PLAN-020 e PLAN-025 deixam indisponibilidades explicitas', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const PlanosImportSharePage()));
    expect(find.text('Importar plano'), findsOneWidget);
    expect(find.text('Plataformas suportadas'), findsOneWidget);

    await tester.pumpWidget(_app(const PlanosArchivePage()));
    expect(find.text('Arquivos de planos'), findsOneWidget);
    expect(find.text('Arquivamento pendente'), findsOneWidget);
  });
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.dark, home: home);

TreinoModel _plan() {
  return TreinoModel(
    id: 'planos-official-test',
    nome: 'Plano Upper Lower',
    descricao: 'Plano de teste para validar a interface oficial.',
    objetivo: 'Hipertrofia',
    nivel: 'Intermediario',
    divisao: 'Upper / Lower',
    tempoEstimado: 60,
    diasPorSemana: 2,
    planoDias: const [
      TreinoDiaModel(
        codigo: 'A',
        nome: 'Upper A',
        ordem: 1,
        exercicioIds: ['supino-reto'],
      ),
      TreinoDiaModel(
        codigo: 'B',
        nome: 'Lower A',
        ordem: 2,
        exercicioIds: ['agachamento'],
      ),
    ],
    criadoPorIA: false,
    exercicios: [_exercise('supino-reto', 'Supino reto')],
    dataCriacao: DateTime(2026).toIso8601String(),
  );
}

ExercicioModel _exercise(String id, String name) => ExercicioModel(
  id: id,
  nome: name,
  categoria: 'Peito',
  descricao: 'Exercicio de teste.',
  comoExecutar: 'Executar com controle.',
  cuidados: 'Manter tecnica.',
  musculos: const ['Peito'],
  musculosSecundarios: const ['Triceps'],
  equipamentos: const ['Barra'],
  locais: const ['Academia'],
  dificuldade: 'Intermediario',
  objetivo: 'Hipertrofia',
  imagem: '',
  video: '',
  tags: const ['Composto'],
  caloriasHora: 300,
  series: 4,
  repeticoes: '8-10',
  descansoSegundos: 90,
);
