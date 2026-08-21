import 'package:fitai/features/plans/workout_execution/pages/workout_preview_page.dart';
import 'package:fitai/core/navigation/app_routes.dart';
import 'package:fitai/features/plans/workout_execution/widgets/workout_preparation_content.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_day_data.dart';
import 'package:fitai/screens/treinos/exercicio_detalhe_page.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/screens/treinos/workout_day_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/core_journey_test_harness.dart';

void main() {
  testWidgets('pre-treino mostra somente dados confiaveis do plano', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_content()));

    expect(find.text('PREPARAR TREINO'), findsOneWidget);
    expect(find.text('Upper A'), findsOneWidget);
    expect(find.text('Supino reto'), findsAtLeastNWidgets(1));
    await tester.scrollUntilVisible(
      find.text('Resumo do treino'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Resumo do treino'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.textContaining('50'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('01:15'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('01:15'), findsOneWidget);
    expect(find.text('420 kcal'), findsNothing);
    expect(find.text('Readiness'), findsNothing);
  });

  testWidgets('pre-treino mostra fallback de midia sem bloquear o conteudo', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_content()));

    expect(
      find.bySemanticsLabel('Midia do exercicio Supino reto'),
      findsOneWidget,
    );
    expect(find.text('Ver execucao'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Remada curvada'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Remada curvada'), findsOneWidget);
  });

  testWidgets('pre-treino representa loading, offline, falha e vazio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_content(status: WorkoutPreparationStatus.loading)),
    );
    expect(find.bySemanticsLabel('Carregando conteudo'), findsWidgets);

    await tester.pumpWidget(
      _app(_content(status: WorkoutPreparationStatus.offline)),
    );
    expect(find.text('Sem conexao'), findsOneWidget);
    expect(find.text('Supino reto'), findsAtLeastNWidgets(1));

    await tester.pumpWidget(
      _app(
        _content(
          status: WorkoutPreparationStatus.error,
          errorMessage: 'Falha local controlada.',
        ),
      ),
    );
    expect(find.text('Nao foi possivel preparar o treino'), findsOneWidget);
    expect(find.text('Falha local controlada.'), findsOneWidget);

    await tester.pumpWidget(_app(_content(exercises: const [])));
    expect(find.text('Treino sem exercicios'), findsOneWidget);
  });

  testWidgets('pre-treino abre a execucao uma vez em toque repetido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final observer = _RouteObserver();
    final plan = _plan();
    final coreJourney = await createCoreJourneyTestController([plan]);
    addTearDown(coreJourney.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        navigatorObservers: [observer],
        home: coreJourneyTestScope(
          coreJourney,
          child: WorkoutPreviewPage(plan: plan, day: buildPlanDays(plan).first),
        ),
      ),
    );
    await tester.pump();
    observer.pushCount = 0;

    final start = find.text('Iniciar treino');
    await tester.tap(start);
    await tester.tap(start, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(TreinoEmAndamentoPage), findsOneWidget);
    expect(observer.pushCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pre-treino abre os destinos reais de exercicio e lista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final plan = _plan();
    final day = buildPlanDays(plan).first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: WorkoutPreviewPage(plan: plan, day: day),
      ),
    );

    await tester.tap(find.text('Ver execucao'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ExercicioDetalhePage), findsOneWidget);

    Navigator.of(tester.element(find.byType(ExercicioDetalhePage))).pop();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.text('Ver lista'),
      300,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey<String>('workout-preparation-list'),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Ver lista'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WorkoutDayPage), findsOneWidget);
  });

  testWidgets('pre-treino suporta 200% de texto e largura pequena', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(_content(), textScaler: const TextScaler.linear(2)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home, {TextScaler? textScaler}) => MaterialApp(
  theme: AppTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: textScaler ?? TextScaler.noScaling),
    child: child ?? const SizedBox.shrink(),
  ),
  home: Scaffold(body: home),
);

WorkoutPreparationContent _content({
  WorkoutPreparationStatus status = WorkoutPreparationStatus.ready,
  String? errorMessage,
  List<ExercicioModel>? exercises,
}) => WorkoutPreparationContent(
  workoutName: 'Upper A',
  planLabel: 'Hipertrofia · Dia A',
  exercises: exercises ?? _plan().exercicios,
  estimatedMinutes: 50,
  defaultRestSeconds: 75,
  status: status,
  errorMessage: errorMessage,
  onBack: () {},
  onOpenExercise: (_) {},
  onOpenExerciseList: () {},
);

TreinoModel _plan() => TreinoModel(
  id: 'workout-preparation-test',
  nome: 'Upper / Lower',
  descricao: 'Plano de teste do pre-treino.',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  divisao: 'Upper / Lower',
  tempoEstimado: 50,
  diasPorSemana: 1,
  planoDias: const [
    TreinoDiaModel(
      codigo: 'Dia A',
      nome: 'Upper A',
      ordem: 1,
      exercicioIds: ['supino-reto', 'remada-curvada', 'triceps-corda'],
    ),
  ],
  criadoPorIA: false,
  exercicios: [
    _exercise('supino-reto', 'Supino reto', 'Peito', 4, '8-10'),
    _exercise('remada-curvada', 'Remada curvada', 'Costas', 3, '10-12'),
    _exercise('triceps-corda', 'Triceps na corda', 'Triceps', 3, '10-12'),
  ],
  dataCriacao: '2026-08-13T10:00:00.000',
);

ExercicioModel _exercise(
  String id,
  String name,
  String category,
  int sets,
  String repetitions,
) => ExercicioModel(
  id: id,
  nome: name,
  categoria: category,
  descricao: 'Exercicio de teste.',
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
  series: sets,
  repeticoes: repetitions,
  descansoSegundos: 90,
);

class _RouteObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == AppRoutes.coreWorkout) pushCount += 1;
    super.didPush(route, previousRoute);
  }
}
