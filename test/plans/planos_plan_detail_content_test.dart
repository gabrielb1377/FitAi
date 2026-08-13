import 'package:fitai/features/plans/presentation/pages/planos_official_plan_pages.dart';
import 'package:fitai/features/plans/presentation/widgets/planos_plan_detail_content.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PLAN-DETAIL mostra apenas metricas do contrato real', (
    tester,
  ) async {
    String? openedWorkout;

    await tester.pumpWidget(
      _app(
        PlanosPlanDetailContent(
          planName: 'Upper / Lower',
          description: 'Plano de teste visual.',
          objective: 'Hipertrofia',
          mediaAssetPath: null,
          daysPerWeek: 4,
          estimatedMinutes: 60,
          exerciseCount: 8,
          weeklyCompleted: 2,
          weeklyTarget: 4,
          currentWeekLabel: 'Semana 6',
          workouts: const [
            PlanosDetailWorkout(
              id: 'upper-a',
              name: 'Upper A',
              weekday: 'Seg',
              exerciseCount: 4,
              isCurrent: false,
            ),
            PlanosDetailWorkout(
              id: 'lower-a',
              name: 'Lower A',
              weekday: 'Ter',
              exerciseCount: 4,
              isCurrent: true,
            ),
          ],
          onBack: () {},
          onMore: () {},
          onOpenWeek: () {},
          onOpenCalendar: () {},
          onOpenProgress: () {},
          onOpenWorkout: (workout) => openedWorkout = workout.id,
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Semana 6'), findsNWidgets(2));
    expect(find.text('2 de 4 treinos'), findsOneWidget);
    expect(find.text('8 semanas'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Lower A'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lower A'));
    expect(openedWorkout, 'lower-a');
  });

  testWidgets(
    'PLAN-DETAIL comunica offline e falha parcial sem ocultar plano',
    (tester) async {
      await tester.pumpWidget(
        _app(_content(isOffline: true, hasPartialFailure: true)),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(
        find.text('Exibindo o plano salvo neste dispositivo.'),
        findsOneWidget,
      );
      expect(find.text('Alguns dados estao indisponiveis'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Upper A'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Upper A'), findsOneWidget);
    },
  );

  testWidgets('PLAN-DETAIL mantem menu real e confirmacao de exclusao', (
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

    await tester.tap(find.byTooltip('Opcoes do plano'));
    await tester.pumpAndSettle();

    expect(find.text('Editar plano'), findsOneWidget);
    expect(find.text('Estatisticas'), findsOneWidget);
    expect(find.text('Calendario'), findsAtLeastNWidgets(1));
    expect(find.text('Excluir plano'), findsOneWidget);

    await tester.tap(find.text('Excluir plano'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Excluir plano?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('PLAN-DETAIL preserva os destinos de treino existentes', (
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

    await tester.scrollUntilVisible(
      find.text('Upper A'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Upper A'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanosWorkoutDetailPage), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanosWeekPage), findsOneWidget);
  });

  testWidgets('PLAN-DETAIL nao inventa descricao quando ela esta ausente', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PlanosPlanDetailContent(
          planName: 'Plano sem descricao',
          description: '',
          objective: 'Saude',
          mediaAssetPath: null,
          daysPerWeek: 1,
          estimatedMinutes: 0,
          exerciseCount: 0,
          weeklyCompleted: 0,
          weeklyTarget: 1,
          currentWeekLabel: 'Semana atual',
          workouts: const [],
          onBack: _noop,
          onMore: _noop,
          onOpenWeek: _noop,
          onOpenCalendar: _noop,
          onOpenProgress: _noop,
          onOpenWorkout: _ignoreWorkout,
        ),
      ),
    );

    expect(
      find.text('Plano focado em evolucao consistente e desempenho muscular.'),
      findsNothing,
    );
    expect(find.text('Nenhum treino neste plano'), findsOneWidget);
  });

  testWidgets('PLAN-DETAIL nao gera overflow em 360dp com texto a 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(_content(), textScaler: const TextScaler.linear(2)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  const responsiveViewports = <Size>[
    Size(320, 800),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(600, 900),
    Size(768, 360),
    Size(768, 1024),
    Size(1024, 768),
    Size(1440, 900),
  ];

  for (final viewport in responsiveViewports) {
    testWidgets(
      'PLAN-DETAIL nao gera overflow em ${viewport.width}x${viewport.height}',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_app(_content()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _app(Widget home, {TextScaler? textScaler}) => MaterialApp(
  theme: AppTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
    child: Scaffold(body: home),
  ),
);

PlanosPlanDetailContent _content({
  bool isOffline = false,
  bool hasPartialFailure = false,
}) => PlanosPlanDetailContent(
  planName: 'Upper / Lower',
  description: 'Plano de teste visual.',
  objective: 'Hipertrofia',
  mediaAssetPath: null,
  daysPerWeek: 4,
  estimatedMinutes: 60,
  exerciseCount: 8,
  weeklyCompleted: 2,
  weeklyTarget: 4,
  currentWeekLabel: 'Semana 6',
  workouts: const [
    PlanosDetailWorkout(
      id: 'upper-a',
      name: 'Upper A',
      weekday: 'Seg',
      exerciseCount: 4,
      isCurrent: false,
    ),
  ],
  onBack: _noop,
  onMore: _noop,
  onOpenWeek: _noop,
  onOpenCalendar: _noop,
  onOpenProgress: _noop,
  onOpenWorkout: _ignoreWorkout,
  isOffline: isOffline,
  hasPartialFailure: hasPartialFailure,
);

void _noop() {}

void _ignoreWorkout(PlanosDetailWorkout _) {}

TreinoModel _plan() => TreinoModel(
  id: 'plan-detail-menu',
  nome: 'Upper / Lower',
  descricao: 'Plano de teste para o menu.',
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
  ],
  criadoPorIA: false,
  exercicios: [_exercise()],
  dataCriacao: '2026-08-01T08:00:00.000',
);

ExercicioModel _exercise() => ExercicioModel(
  id: 'supino-reto',
  nome: 'Supino reto',
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
