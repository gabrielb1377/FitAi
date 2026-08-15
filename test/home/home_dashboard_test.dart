import 'package:fitai/features/home/presentation/states/home_state.dart';
import 'package:fitai/features/home/presentation/widgets/home_dashboard_content.dart';
import 'package:fitai/features/home/presentation/widgets/home_loading_state.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/treino_do_dia_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra skeleton enquanto a Home carrega', (tester) async {
    await tester.pumpWidget(_host(_content(_state(HomeLoadStatus.loading))));

    expect(find.byType(HomeLoadingState), findsOneWidget);
  });

  testWidgets('mostra estado vazio honesto sem treino, Coach ou meta', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_content(_state(HomeLoadStatus.ready))));

    expect(find.text('Nenhum treino criado ainda'), findsOneWidget);
    expect(find.text('Criar plano'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Abrir Coach FitIA.*Ainda sem insights')),
      findsOneWidget,
    );
    expect(find.text('Suas conquistas'), findsOneWidget);
  });

  testWidgets('mantem conteudo local e informa modo offline', (tester) async {
    await tester.pumpWidget(
      _host(
        _content(
          _state(
            HomeLoadStatus.ready,
            isOffline: true,
            lastUpdatedAt: DateTime(2026, 7, 16, 10, 30),
          ),
        ),
      ),
    );

    expect(find.text('Voce esta offline'), findsOneWidget);
    expect(find.text('Nenhum treino criado ainda'), findsOneWidget);
  });

  testWidgets('mantem treino e destaca corrida ativa', (tester) async {
    await tester.pumpWidget(
      _host(
        _content(
          _state(HomeLoadStatus.ready, workout: _workout()),
          runningActive: true,
        ),
      ),
    );

    expect(find.text('Ativa'), findsOneWidget);
    expect(find.text('Upper A'), findsOneWidget);
  });

  testWidgets('mostra treino real quando nao existe corrida ativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_content(_state(HomeLoadStatus.ready, workout: _workout()))),
    );

    expect(find.text('Upper A'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsOneWidget);
    expect(find.text('1.2k'), findsOneWidget);
  });

  testWidgets('mantem as acoes reais conectadas na composicao canônica', (
    tester,
  ) async {
    var openedCoach = false;
    var openedWorkout = false;
    var openedHistory = false;
    var openedSteps = false;

    await tester.pumpWidget(
      _host(
        _content(
          _state(HomeLoadStatus.ready, workout: _workout()),
          onOpenCoach: () => openedCoach = true,
          onOpenWorkout: () => openedWorkout = true,
          onOpenHistory: () => openedHistory = true,
          onOpenSteps: () => openedSteps = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Iniciar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar treino'));
    expect(openedWorkout, isTrue);

    await tester.ensureVisible(find.text('Passos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passos'));
    expect(openedSteps, isTrue);

    final timeline = find.byKey(const ValueKey('home-week-timeline-card'));
    await tester.ensureVisible(timeline);
    await tester.pumpAndSettle();
    await tester.tap(timeline);
    expect(openedHistory, isTrue);

    final coach = find.byKey(const ValueKey('home-coach-card'));
    await tester.ensureVisible(coach);
    await tester.pumpAndSettle();
    await tester.tap(coach);
    expect(openedCoach, isTrue);
  });

  testWidgets('mantem a criacao de plano no estado sem treino', (tester) async {
    var createdPlan = false;

    await tester.pumpWidget(
      _host(
        _content(
          _state(HomeLoadStatus.ready),
          onCreatePlan: () => createdPlan = true,
        ),
      ),
    );

    await tester.tap(find.text('Criar plano'));

    expect(createdPlan, isTrue);
  });

  testWidgets('expoe semantica para progresso, Coach e historico', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_content(_state(HomeLoadStatus.ready, workout: _workout()))),
    );

    expect(
      find.bySemanticsLabel(RegExp(r'Progresso .* dias seguidos')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'Abrir Coach FitIA')), findsOneWidget);
    final timeline = find.byKey(const ValueKey('home-week-timeline-card'));
    expect(
      tester.getSemantics(timeline).label,
      contains('Abrir historico dos ultimos sete dias'),
    );
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: child),
);

Widget _content(
  HomeState state, {
  bool runningActive = false,
  VoidCallback? onOpenCoach,
  VoidCallback? onOpenWorkout,
  VoidCallback? onCreatePlan,
  VoidCallback? onOpenHistory,
  VoidCallback? onOpenSteps,
}) => HomeDashboardContent(
  state: state,
  name: 'Atleta',
  level: 2,
  xp: 120,
  steps: 1234,
  distance: 1.25,
  runningActive: runningActive,
  runningSeconds: 125,
  onRefresh: () async {},
  onOpenWorkout: onOpenWorkout ?? () {},
  onCreatePlan: onCreatePlan ?? () {},
  onOpenLibrary: () {},
  onOpenRunning: () {},
  onOpenSteps: onOpenSteps ?? () {},
  onOpenCoach: onOpenCoach ?? () {},
  onOpenGoals: () {},
  onOpenAchievements: () {},
  onOpenNotifications: () {},
  onCustomize: () {},
  onOpenOverview: () {},
  onOpenTodayWorkout: () {},
  onOpenRecentActivity: onOpenHistory ?? () {},
  onOpenProgress: () {},
);

HomeState _state(
  HomeLoadStatus status, {
  TreinoModel? workout,
  bool isOffline = false,
  DateTime? lastUpdatedAt,
}) => HomeState(
  status: status,
  selection: TreinoDoDiaSelecao(
    treino: workout,
    diaDeDescanso: false,
    treinoConcluidoHoje: false,
    todosTreinosConcluidosHoje: false,
    titulo: workout?.nome ?? 'Nenhum treino',
    descricao: '',
    motivo: '',
  ),
  isOffline: isOffline,
  lastUpdatedAt: lastUpdatedAt,
);

TreinoModel _workout() => TreinoModel(
  id: 'workout-1',
  nome: 'Upper A',
  descricao: 'Treino superior',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  divisao: 'Upper/Lower',
  tempoEstimado: 45,
  diasPorSemana: 4,
  criadoPorIA: false,
  exercicios: const [],
  dataCriacao: DateTime(2026).toIso8601String(),
);
