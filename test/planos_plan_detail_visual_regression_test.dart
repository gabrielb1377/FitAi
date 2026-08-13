import 'package:fitai/features/plans/presentation/pages/planos_official_plan_pages.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewports = <Size>[
    Size(320, 800),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(600, 900),
    Size(768, 1024),
    Size(1024, 768),
    Size(1440, 900),
  ];

  for (final viewport in viewports) {
    testWidgets('golden PLAN-DETAIL after ${viewport.width.toInt()}dp', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final plan = _plan();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: PlanosPlanDetailPage(plan: plan, progress: _progress(plan)),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PlanosPlanDetailPage),
        matchesGoldenFile(
          'goldens/ui_m1_4/after/PLAN_DETAIL_AFTER_${viewport.width.toInt()}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

PlanProgressSnapshot _progress(TreinoModel plan) => PlanProgressSnapshot(
  completedWorkouts: 6,
  weeklyCompletedWorkouts: 2,
  weeklyTargetWorkouts: 4,
  nextDayIndex: 2,
  weeks: [
    PlanWeekSnapshot(
      number: 6,
      startsAt: DateTime(2026, 8, 10),
      completedWorkouts: 2,
      targetWorkouts: 4,
      isCurrent: true,
      isFuture: false,
    ),
  ],
);

TreinoModel _plan() => TreinoModel(
  id: 'plan-detail-visual',
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
      exercicioIds: ['agachamento-livre'],
    ),
    TreinoDiaModel(
      codigo: 'C',
      nome: 'Upper B',
      ordem: 3,
      exercicioIds: ['remada-curvada'],
    ),
    TreinoDiaModel(
      codigo: 'D',
      nome: 'Lower B',
      ordem: 4,
      exercicioIds: ['levantamento-terra'],
    ),
  ],
  criadoPorIA: true,
  exercicios: [
    _exercise('supino-reto', 'Supino reto', 'Peito'),
    _exercise('agachamento-livre', 'Agachamento livre', 'Pernas'),
    _exercise('remada-curvada', 'Remada curvada', 'Costas'),
    _exercise('levantamento-terra', 'Levantamento terra', 'Pernas'),
  ],
  dataCriacao: '2026-07-01T08:00:00.000',
);

ExercicioModel _exercise(String id, String name, String category) =>
    ExercicioModel(
      id: id,
      nome: name,
      categoria: category,
      descricao: 'Exercicio de teste visual.',
      comoExecutar: 'Executar com controle.',
      cuidados: 'Manter tecnica.',
      musculos: [category],
      musculosSecundarios: const [],
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
