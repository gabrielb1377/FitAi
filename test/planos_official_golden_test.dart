import 'package:fitai/features/plans/presentation/pages/planos_official_plan_pages.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_root_page.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_wizards.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('golden PLAN-001 meus planos', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _app(PlanosOfficialRootPage(checkBackend: () async => false)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PlanosOfficialRootPage),
      matchesGoldenFile('goldens/planos_001_root.png'),
    );
  });

  testWidgets('golden PLAN-002 objetivo IA', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(_app(const PlanosAiGoalPage()));
    await expectLater(
      find.byType(PlanosAiGoalPage),
      matchesGoldenFile('goldens/planos_002_ai_goal.png'),
    );
  });

  testWidgets('golden PLAN-013 detalhes do plano', (tester) async {
    _setMobileViewport(tester);
    final plan = _plan();
    await tester.pumpWidget(
      _app(
        PlanosPlanDetailPage(
          plan: plan,
          progress: PlanProgressSnapshot.empty(plan),
        ),
      ),
    );
    await expectLater(
      find.byType(PlanosPlanDetailPage),
      matchesGoldenFile('goldens/planos_013_detail.png'),
    );
  });
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.dark, home: home);

TreinoModel _plan() => TreinoModel(
  id: 'golden-plan',
  nome: 'Upper / Lower',
  descricao: 'Plano focado em ganho de massa com divisao Upper/Lower.',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  divisao: 'Upper / Lower',
  tempoEstimado: 60,
  diasPorSemana: 4,
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
      exercicioIds: ['supino-reto'],
    ),
  ],
  criadoPorIA: true,
  exercicios: [
    ExercicioModel(
      id: 'supino-reto',
      nome: 'Supino reto',
      categoria: 'Peito',
      descricao: 'Exercicio composto para peitoral.',
      comoExecutar: 'Controle o movimento.',
      cuidados: 'Mantenha a tecnica.',
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
    ),
  ],
  dataCriacao: DateTime(2026).toIso8601String(),
);
