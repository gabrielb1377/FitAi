import 'package:fitai/features/plans/presentation/widgets/planos_list_content.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PLAN-001 abre o detalhe pelos comandos reais da lista', (
    tester,
  ) async {
    final plans = _plans();
    TreinoModel? openedPlan;

    await tester.pumpWidget(
      _app(
        PlanosListContent(
          plans: plans,
          progressFor: _progressFor,
          isOffline: false,
          isRefreshing: false,
          hasPartialError: false,
          onRefresh: () async {},
          onOpenPlan: (plan) => openedPlan = plan,
          onShowCreateOptions: () {},
          onOpenLibrary: () {},
          onOpenHistory: () {},
          onShowMoreOptions: () {},
        ),
      ),
    );

    expect(find.text('Planos'), findsOneWidget);
    expect(find.text('Plano ativo'), findsNothing);
    expect(find.text('Continuar plano'), findsOneWidget);
    expect(find.text('Meus planos'), findsOneWidget);

    await tester.tap(find.text('Continuar plano'));
    expect(openedPlan, same(plans.first));

    await tester.scrollUntilVisible(
      find.text('Forca Base'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Forca Base'));
    expect(openedPlan, same(plans[1]));
  });

  testWidgets('PLAN-001 filtra planos secundarios por busca sob demanda', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PlanosListContent(
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

    await tester.tap(find.byTooltip('Buscar planos'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'mobilidade');
    await tester.pump();

    expect(find.text('Mobilidade'), findsOneWidget);
    expect(find.text('Forca Base'), findsNothing);
  });

  testWidgets('PLAN-001 comunica offline e falha parcial sem ocultar planos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PlanosListContent(
          plans: _plans(),
          progressFor: _progressFor,
          isOffline: true,
          isRefreshing: true,
          hasPartialError: true,
          onRefresh: () async {},
          onOpenPlan: (_) {},
          onShowCreateOptions: () {},
          onOpenLibrary: () {},
          onOpenHistory: () {},
          onShowMoreOptions: () {},
        ),
      ),
    );

    expect(find.text('Offline: mostrando seus planos salvos.'), findsOneWidget);
    expect(
      find.text('Alguns dados podem estar desatualizados.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Atualizando planos'), findsOneWidget);
    expect(find.text('Hipertrofia Upper Lower'), findsOneWidget);
  });

  testWidgets('PLAN-001 nao gera overflow em 320dp com texto a 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        PlanosListContent(
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
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PlanosListContent),
      matchesGoldenFile('goldens/planos_list_overflow_probe.png'),
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home, {TextScaler? textScaler}) => MaterialApp(
  theme: AppTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
    child: Scaffold(body: home),
  ),
);

PlanProgressSnapshot _progressFor(TreinoModel plan) {
  final completed = plan.id == 'active' ? 3 : 1;
  return PlanProgressSnapshot(
    completedWorkouts: completed,
    weeklyCompletedWorkouts: 2,
    weeklyTargetWorkouts: 4,
    nextDayIndex: 1,
    weeks: [
      PlanWeekSnapshot(
        number: 2,
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
    descricao: 'Plano de teste.',
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
