import 'package:fitai/features/plans/workout_execution/pages/workout_preview_page.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/controllers/plan_day_data.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(768, 1024),
    Size(1024, 768),
    Size(1440, 900),
  ];

  for (final viewport in viewports) {
    testWidgets('golden WORKOUT-PREP after ${viewport.width.toInt()}dp', (
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
          home: WorkoutPreviewPage(plan: plan, day: buildPlanDays(plan).first),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WorkoutPreviewPage),
        matchesGoldenFile(
          'goldens/ui_m1_5/after/WORKOUT_PREP_AFTER_${viewport.width.toInt()}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

TreinoModel _plan() => TreinoModel(
  id: 'workout-prep-visual',
  nome: 'Upper / Lower',
  descricao: 'Plano de referencia para o pre-treino.',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  divisao: 'Upper / Lower',
  tempoEstimado: 50,
  diasPorSemana: 1,
  planoDias: const [
    TreinoDiaModel(
      codigo: 'A',
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
  descricao: 'Exercicio de referencia visual.',
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
