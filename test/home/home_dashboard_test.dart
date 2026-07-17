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

    expect(find.text('Crie seu primeiro plano'), findsOneWidget);
    expect(find.text('Ainda sem insights'), findsOneWidget);
    expect(find.text('Nenhuma meta disponivel'), findsOneWidget);
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
    expect(find.text('Crie seu primeiro plano'), findsOneWidget);
  });

  testWidgets('prioriza corrida ativa sobre o treino do dia', (tester) async {
    await tester.pumpWidget(
      _host(
        _content(
          _state(HomeLoadStatus.ready, workout: _workout()),
          runningActive: true,
        ),
      ),
    );

    expect(find.text('Corrida em andamento'), findsOneWidget);
    expect(find.text('Upper A'), findsNothing);
  });

  testWidgets('mostra treino real quando nao existe corrida ativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_content(_state(HomeLoadStatus.ready, workout: _workout()))),
    );

    expect(find.text('Upper A'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: child),
);

Widget _content(HomeState state, {bool runningActive = false}) =>
    HomeDashboardContent(
      state: state,
      name: 'Atleta',
      level: 2,
      xp: 120,
      steps: 1234,
      distance: 1.25,
      runningActive: runningActive,
      runningSeconds: 125,
      onRefresh: () async {},
      onOpenWorkout: () {},
      onCreatePlan: () {},
      onOpenLibrary: () {},
      onOpenRunning: () {},
      onOpenSteps: () {},
      onOpenCoach: () {},
      onOpenGoals: () {},
      onOpenAchievements: () {},
      onOpenNotifications: () {},
      onOpenProfile: () {},
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
