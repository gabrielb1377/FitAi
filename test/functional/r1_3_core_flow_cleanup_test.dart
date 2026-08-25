import 'package:fitai/design_system/fit_design_system.dart';
import 'package:fitai/features/plans/presentation/pages/planos_official_plan_pages.dart';
import 'package:fitai/features/plans/workout_execution/pages/workout_preview_page.dart';
import 'package:fitai/features/profile/presentation/routes/profile_routes.dart';
import 'package:fitai/features/settings/presentation/pages/personal_data_settings_page.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_progress_snapshot.dart';
import 'package:fitai/screens/treinos/exercicio_detalhe_page.dart';
import 'package:fitai/screens/treinos/official/official_plan_options_page.dart';
import 'package:fitai/screens/treinos/official/official_plan_progress_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Perfil abre a edicao local, sem placeholder de rota', (
    tester,
  ) async {
    final router = ProfileRoutes.createRouter(
      rootBuilder: (_) => const SizedBox.shrink(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        initialRoute: ProfileRoutes.edit,
        onGenerateRoute: router.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PersonalDataSettingsPage), findsOneWidget);
    expect(find.text('Em desenvolvimento'), findsNothing);
  });

  testWidgets('exercicio do dia do plano abre o detalhe existente', (
    tester,
  ) async {
    final plan = _plan();
    await tester.pumpWidget(
      _app(
        PlanosWorkoutDetailPage(
          plan: plan,
          day: const PlanosPlanDayView(
            code: 'upper-a',
            name: 'Upper A',
            weekday: 'Seg',
            exerciseIds: ['supino-reto'],
            order: 1,
            isToday: true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Supino reto'));
    // A tela de exercicio pode manter carregamentos indeterminados visiveis;
    // aguardar a transicao e verificar o destino e mais deterministico.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ExercicioDetalhePage), findsOneWidget);
  });

  testWidgets('calendario inicia a previa do proximo treino apenas com plano', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const PlanosCalendarPage()));

    final disabledButton = tester.widget<FitOutlinedButton>(
      find.byType(FitOutlinedButton),
    );
    expect(disabledButton.onPressed, isNull);

    await tester.pumpWidget(_app(PlanosCalendarPage(plan: _plan())));
    final enabledButton = tester.widget<FitOutlinedButton>(
      find.byType(FitOutlinedButton),
    );
    expect(enabledButton.onPressed, isNotNull);
    enabledButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutPreviewPage), findsOneWidget);
  });

  testWidgets('progresso do plano abre opcoes reais no menu', (tester) async {
    final plan = _plan();
    await tester.pumpWidget(
      _app(
        OfficialPlanProgressPage(
          plan: plan,
          progress: PlanProgressSnapshot.empty(plan),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficialPlanOptionsPage), findsOneWidget);
  });
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.dark, home: home);

TreinoModel _plan() => TreinoModel(
  id: 'r1-3-plan',
  nome: 'Plano Upper Lower',
  descricao: 'Plano para validar jornadas funcionais.',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  divisao: 'Upper / Lower',
  tempoEstimado: 50,
  diasPorSemana: 1,
  planoDias: const [
    TreinoDiaModel(
      codigo: 'upper-a',
      nome: 'Upper A',
      ordem: 1,
      exercicioIds: ['supino-reto'],
    ),
  ],
  criadoPorIA: false,
  exercicios: [_exercise()],
  dataCriacao: DateTime(2026, 8, 20).toIso8601String(),
);

ExercicioModel _exercise() => ExercicioModel(
  id: 'supino-reto',
  nome: 'Supino reto',
  categoria: 'Peito',
  descricao: 'Exercicio composto.',
  comoExecutar: 'Execute com controle.',
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
);
