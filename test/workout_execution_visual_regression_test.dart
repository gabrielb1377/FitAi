import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_controller.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_page.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/screens/treinos/treino_em_andamento_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(768, 1024),
  ];

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final viewport in viewports) {
    testWidgets('golden WORKOUT-RUN ${viewport.width.toInt()}dp', (
      tester,
    ) async {
      _setViewport(tester, viewport);
      await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(TreinoEmAndamentoPage),
        matchesGoldenFile(
          'goldens/ui_m1_6/after/WORKOUT_RUN_NEW_${viewport.width.toInt()}.png',
        ),
      );
    });
  }

  testWidgets('golden WORKOUT-REST 390dp', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(_app(TreinoEmAndamentoPage(treino: _plan())));
    await tester.pump(const Duration(milliseconds: 100));

    await _tapCompleteSet(tester);
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(TreinoEmAndamentoPage),
      matchesGoldenFile('goldens/ui_m1_6/after/WORKOUT_REST_390.png'),
    );
  });

  testWidgets('golden offline state remains on the isolated vertical slice', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    final controller = await _sliceController();
    addTearDown(controller.dispose);
    controller.setOffline(true);
    await controller.startExampleWorkout();
    await tester.pumpWidget(
      _app(WorkoutVerticalSlicePage(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await expectLater(
      find.byType(WorkoutVerticalSlicePage),
      matchesGoldenFile('goldens/ui_m1_6/after/WORKOUT_OFFLINE_SLICE_390.png'),
    );
  });

  testWidgets(
    'golden sync pending state remains on the isolated vertical slice',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      final controller = await _sliceController();
      addTearDown(controller.dispose);
      controller.setOffline(true);
      await controller.startExampleWorkout();
      await controller.registerSet(weight: 55, reps: 10);
      controller.setOffline(false);
      await tester.pumpWidget(
        _app(WorkoutVerticalSlicePage(controller: controller)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await expectLater(
        find.byType(WorkoutVerticalSlicePage),
        matchesGoldenFile(
          'goldens/ui_m1_6/after/WORKOUT_SYNC_PENDING_SLICE_390.png',
        ),
      );
    },
  );
}

void _setViewport(WidgetTester tester, Size viewport) {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<WorkoutVerticalSliceController> _sliceController() async {
  final preferences = await SharedPreferences.getInstance();
  final transport = DebugWorkoutSyncTransport();
  final controller = WorkoutVerticalSliceController(
    repository: WorkoutVerticalRepository(
      localStore: SharedPreferencesWorkoutVerticalLocalStore(preferences),
      transport: AdaptiveWorkoutSyncTransport(debugTransport: transport),
    ),
    debugTransport: transport,
  );
  await controller.initialize();
  return controller;
}

Future<void> _tapCompleteSet(WidgetTester tester) async {
  final button = find.byTooltip('Registrar serie');
  await tester.ensureVisible(button);
  await tester.tap(button);
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.dark, home: home);

TreinoModel _plan() => TreinoModel(
  id: 'ui-m1-6-workout-plan',
  nome: 'Upper A',
  descricao: 'Treino de referencia para a captura visual.',
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
  divisao: 'Upper / Lower',
  tempoEstimado: 48,
  diasPorSemana: 1,
  planoDias: const [
    TreinoDiaModel(
      codigo: 'Dia A',
      nome: 'Upper A',
      ordem: 1,
      exercicioIds: ['supino-reto', 'remada-curvada'],
    ),
  ],
  criadoPorIA: false,
  exercicios: [
    _exercise('supino-reto', 'Supino reto', 3),
    _exercise('remada-curvada', 'Remada curvada', 3),
  ],
  dataCriacao: '2026-08-13T10:00:00.000',
);

ExercicioModel _exercise(String id, String name, int sets) => ExercicioModel(
  id: id,
  nome: name,
  categoria: 'Peito',
  descricao: 'Exercicio de referencia visual.',
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
  series: sets,
  repeticoes: '8-12',
  descansoSegundos: 60,
);
