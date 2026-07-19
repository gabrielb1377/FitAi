import 'dart:convert';

import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/ready_plan_day_model.dart';
import 'package:fitai/models/ready_plan_exercise_model.dart';
import 'package:fitai/models/ready_plan_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/screens/treinos/official/official_add_workout_page.dart';
import 'package:fitai/screens/treinos/official/official_plan_editor_page.dart';
import 'package:fitai/screens/treinos/official/official_plan_options_page.dart';
import 'package:fitai/screens/treinos/official/official_plan_progress_page.dart';
import 'package:fitai/screens/treinos/ready_plans/ready_plan_preview_page.dart';
import 'package:fitai/screens/treinos/ready_plans/ready_plans_library_page.dart';
import 'package:fitai/screens/treinos/treino_detalhes_page.dart';
import 'package:fitai/screens/treinos/treinos_page.dart';
import 'package:fitai/services/ready_plans_service.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PLAN-001 preserva cabecalho, abas, busca e acao de criar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TreinosPage(
          useDeveloperFallback: false,
          checkBackend: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Planos'), findsOneWidget);
    expect(find.text('Meus planos'), findsWidgets);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Novo plano'), findsOneWidget);
  });

  testWidgets('telas oficiais nao apresentam overflow em mobile e tablet', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [Size(360, 640), Size(1024, 768)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(TreinoDetalhesPage(treino: _plan())));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
  });

  testWidgets('PLAN-006 exibe edicao e exclusao do plano', (tester) async {
    await tester.pumpWidget(_app(OfficialPlanEditorPage(initialPlan: _plan())));

    expect(find.text('Editar plano'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Excluir plano'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Excluir plano'), findsOneWidget);
    expect(find.byTooltip('Salvar plano'), findsOneWidget);
  });

  testWidgets('PLAN-007 exibe campos e ordem do novo treino', (tester) async {
    await tester.pumpWidget(
      _app(const OfficialAddWorkoutPage(initialOrder: 5)),
    );

    expect(find.text('Adicionar treino'), findsOneWidget);
    expect(find.text('Nome do treino'), findsOneWidget);
    expect(find.text('Grupos musculares principais'), findsOneWidget);
    expect(find.text('Ordem do treino no plano'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('PLAN-008 carrega a biblioteca oficial', (tester) async {
    final readyPlan = _readyPlan();
    await tester.pumpWidget(
      _app(ReadyPlansLibraryPage(service: _serviceFor(readyPlan))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Planos'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Em alta'), findsOneWidget);
    expect(find.text(readyPlan.name), findsOneWidget);
    expect(find.text('Por objetivo'), findsOneWidget);
  });

  testWidgets('PLAN-009 exibe detalhe completo do plano pronto', (
    tester,
  ) async {
    final readyPlan = _readyPlan();
    await tester.pumpWidget(
      _app(
        ReadyPlanPreviewPage(plan: readyPlan, service: _serviceFor(readyPlan)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(readyPlan.name), findsOneWidget);
    expect(find.text('O que está incluído'), findsOneWidget);
    expect(find.text('Treinos completos'), findsOneWidget);
    expect(find.text('Adicionar aos meus planos'), findsOneWidget);
    expect(find.byTooltip('Salvar favorito'), findsOneWidget);
  });

  testWidgets('PLAN-010 exibe progresso, estatisticas e continuidade', (
    tester,
  ) async {
    final plan = _plan();
    await tester.pumpWidget(
      _app(
        OfficialPlanProgressPage(
          plan: plan,
          progress: PlanProgressSnapshot.empty(plan),
        ),
      ),
    );

    expect(find.text('Progresso'), findsOneWidget);
    expect(find.text('Progresso geral'), findsOneWidget);
    expect(find.text('Estatísticas'), findsOneWidget);
    expect(find.text('Últimos treinos'), findsOneWidget);
    expect(find.text('Continuar Plano'), findsOneWidget);
  });

  testWidgets('PLAN-011 concentra todas as opcoes do plano', (tester) async {
    await tester.pumpWidget(_app(OfficialPlanOptionsPage(plan: _plan())));

    expect(find.text('Opções do plano'), findsOneWidget);
    expect(find.text('Editar plano'), findsOneWidget);
    expect(find.text('Adicionar treino'), findsOneWidget);
    expect(find.text('Duplicar plano'), findsOneWidget);
    expect(find.text('Compartilhar plano'), findsOneWidget);
    expect(find.text('Exportar plano (PDF)'), findsOneWidget);
    expect(find.text('Excluir plano'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.dark, home: home);

ReadyPlansService _serviceFor(ReadyPlanModel plan) {
  return ReadyPlansService(
    client: MockClient((request) async {
      final payload = request.url.path.endsWith('/ready-plans/${plan.id}')
          ? {'plan': plan.toJson()}
          : {
              'plans': [plan.toJson()],
            };
      return http.Response(
        jsonEncode(payload),
        200,
        headers: const {'content-type': 'application/json'},
      );
    }),
  );
}

TreinoModel _plan() {
  return TreinoModel(
    id: 'official-plan-test',
    nome: 'Upper / Lower',
    descricao: 'Plano equilibrado com progressão de carga.',
    objetivo: 'Hipertrofia',
    nivel: 'Intermediário',
    divisao: 'Upper / Lower',
    tempoEstimado: 50,
    diasPorSemana: 1,
    planoDias: const [
      TreinoDiaModel(
        codigo: 'Dia A',
        nome: 'Peito e Costas',
        ordem: 1,
        exercicioIds: ['supino-reto'],
      ),
    ],
    criadoPorIA: false,
    exercicios: [
      ExercicioModel(
        id: 'supino-reto',
        nome: 'Supino reto',
        categoria: 'Peito',
        descricao: 'Exercício composto para peitoral.',
        comoExecutar: 'Controle a barra durante todo o movimento.',
        cuidados: 'Mantenha as escápulas apoiadas.',
        musculos: ['Peito'],
        musculosSecundarios: ['Tríceps'],
        equipamentos: ['Barra'],
        locais: ['Academia'],
        dificuldade: 'Intermediário',
        objetivo: 'Hipertrofia',
        imagem: '',
        video: '',
        tags: ['Composto'],
        caloriasHora: 300,
        series: 4,
        repeticoes: '8-10',
        descansoSegundos: 90,
      ),
    ],
    dataCriacao: '2026-07-18T12:00:00.000Z',
  );
}

ReadyPlanModel _readyPlan() {
  return const ReadyPlanModel(
    id: 'ready-upper-lower',
    name: 'Upper / Lower Essencial',
    description: 'Plano completo para evolução consistente.',
    goal: 'Hipertrofia',
    level: 'Intermediário',
    split: 'Upper / Lower',
    daysPerWeek: 4,
    durationWeeks: 8,
    estimatedMinutes: 50,
    location: 'Academia',
    equipment: ['Barra'],
    tags: ['Hipertrofia'],
    featured: true,
    category: 'Academia',
    popularityCount: 248,
    days: [
      ReadyPlanDayModel(
        id: 'ready-day-a',
        name: 'Dia A',
        title: 'Upper A',
        weekday: 'Segunda',
        muscleGroup: 'Peito e Costas',
        order: 1,
        exercises: [
          ReadyPlanExerciseModel(
            id: 'ready-exercise-a',
            exerciseId: 'supino-reto',
            exerciseName: 'Supino reto',
            order: 1,
            sets: 4,
            reps: '8-10',
            restSeconds: 90,
            category: 'Peito',
            muscles: ['Peito'],
            equipment: ['Barra'],
          ),
        ],
      ),
    ],
  );
}
