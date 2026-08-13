import 'package:fitai/design_system/fit_design_system.dart';
import 'package:fitai/features/plans/presentation/widgets/planos_list_content.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewports = <Size>[
    Size(320, 900),
    Size(360, 900),
    Size(390, 900),
    Size(412, 900),
    Size(768, 1024),
    Size(1024, 1024),
    Size(1440, 1024),
  ];

  for (final viewport in viewports) {
    testWidgets('golden PLAN-001 lista ${viewport.width.toInt()}dp', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/ui_m1_3/after/PLANS_001_AFTER_${viewport.width.toInt()}.png',
        ),
      );
    });
  }
}

Widget _app() => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth > FitLayout.domainPlansMaxContentWidth
            ? FitLayout.domainPlansMaxContentWidth
            : constraints.maxWidth;
        return Center(
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: PlanosListContent(
              plans: _plans(),
              progressFor: _progressFor,
              isOffline: false,
              isRefreshing: false,
              hasPartialError: false,
              onRefresh: () async {},
              onOpenPlan: (_) {},
              onShowCreateOptions: () {},
              onOpenLibrary: () {},
              onOpenHistory: () {},
              onShowMoreOptions: () {},
            ),
          ),
        );
      },
    ),
  ),
);

PlanProgressSnapshot _progressFor(TreinoModel plan) {
  final completed = plan.id == 'active' ? 12 : 3;
  return PlanProgressSnapshot(
    completedWorkouts: completed,
    weeklyCompletedWorkouts: plan.id == 'active' ? 2 : 1,
    weeklyTargetWorkouts: 4,
    nextDayIndex: 1,
    weeks: [
      PlanWeekSnapshot(
        number: 3,
        startsAt: DateTime(2026, 8, 10),
        completedWorkouts: 2,
        targetWorkouts: 4,
        isCurrent: true,
        isFuture: false,
      ),
    ],
  );
}

List<TreinoModel> _plans() => [
  _plan(
    id: 'active',
    name: 'Hipertrofia Upper Lower',
    objective: 'Hipertrofia',
    division: 'Upper / Lower',
    createdByAi: true,
  ),
  _plan(
    id: 'strength',
    name: 'Forca Base',
    objective: 'Forca',
    division: 'Full Body',
  ),
  _plan(
    id: 'mobility',
    name: 'Mobilidade',
    objective: 'Saude',
    division: 'Mobilidade',
  ),
];

TreinoModel _plan({
  required String id,
  required String name,
  required String objective,
  required String division,
  bool createdByAi = false,
}) {
  return TreinoModel(
    id: id,
    nome: name,
    descricao: 'Plano de teste visual.',
    objetivo: objective,
    nivel: 'Intermediario',
    divisao: division,
    tempoEstimado: 50,
    diasPorSemana: 4,
    planoDias: const [
      TreinoDiaModel(codigo: 'A', nome: 'Upper', ordem: 1, exercicioIds: []),
      TreinoDiaModel(codigo: 'B', nome: 'Lower', ordem: 2, exercicioIds: []),
    ],
    criadoPorIA: createdByAi,
    exercicios: const [],
    dataCriacao: '2026-08-01T08:00:00.000',
  );
}
