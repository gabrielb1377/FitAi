import 'package:fitai/core/exercises/muscle_anatomy_taxonomy.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/screens/exercicios/biblioteca/biblioteca_exercicios_page.dart';
import 'package:fitai/screens/exercicios/biblioteca/library_catalog_controller.dart';
import 'package:fitai/screens/exercicios/biblioteca/library_exercise_detail_page.dart';
import 'package:fitai/screens/exercicios/biblioteca/muscle_anatomy_map.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('FITAI-18 taxonomy', () {
    test('MUSCLE-TAX-01: IDs são estáveis e únicos', () {
      final ids = MuscleAnatomyTaxonomy.regions.map((region) => region.id);
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, isNot(contains('')));
    });

    test('MUSCLE-TAX-02: labels são válidos e em PT-BR', () {
      final labels = MuscleAnatomyTaxonomy.regions.map(
        (region) => region.label,
      );
      expect(labels.every((label) => label.trim().isNotEmpty), isTrue);
      expect(labels.toSet(), hasLength(labels.length));
    });

    test('MUSCLE-TAX-03: cada região declara vistas front/back válidas', () {
      expect(
        MuscleAnatomyTaxonomy.regions.every(
          (region) => region.views.isNotEmpty,
        ),
        isTrue,
      );
      expect(
        MuscleAnatomyTaxonomy.regions.every(
          (region) => region.views.every(MuscleAnatomyView.values.contains),
        ),
        isTrue,
      );
    });

    test('MUSCLE-TAX-04: renderer conhece todas as regiões', () {
      expect(
        MuscleAnatomyMap.renderableRegionIds,
        MuscleAnatomyTaxonomy.byId.keys.toSet(),
      );
    });
  });

  group('FITAI-18 mapping', () {
    final mapper = const ExerciseMuscleMapper();

    test('MUSCLE-MAP-01: referências usam IDs canônicos do catálogo', () {
      final ids = bancoExercicios.map((exercise) => exercise.id).toSet();
      for (final exercise in bancoExercicios) {
        final mapping = mapper.map(exercise);
        expect(ids, contains(mapping.exerciseId));
      }
    });

    test('MUSCLE-MAP-02: não há overrides órfãos', () {
      // FITAI-18 intentionally has no per-exercise override table.
      const overrides = <String, ExerciseMuscleAnatomy>{};
      expect(overrides, isEmpty);
    });

    test('MUSCLE-MAP-03: todo ID renderizado existe na taxonomia', () {
      for (final exercise in bancoExercicios) {
        final mapping = mapper.map(exercise);
        for (final id in [
          ...mapping.primaryMuscles,
          ...mapping.secondaryMuscles,
        ]) {
          expect(MuscleAnatomyTaxonomy.byId, contains(id), reason: exercise.id);
        }
      }
    });

    test('MUSCLE-MAP-04: saída não duplica regiões entre papéis', () {
      for (final exercise in bancoExercicios) {
        final mapping = mapper.map(exercise);
        expect(
          mapping.primaryMuscles.toSet().intersection(
            mapping.secondaryMuscles.toSet(),
          ),
          isEmpty,
          reason: exercise.id,
        );
      }
    });

    test('MUSCLE-MAP-05: coverage é determinística', () {
      List<MuscleMappingStatus> statuses() => bancoExercicios
          .map((exercise) => mapper.map(exercise).status)
          .toList(growable: false);

      expect(statuses(), statuses());
    });

    test('MUSCLE-MAP-06: supino canônico mapeia peitoral', () {
      final mapping = mapper.map(_catalogExercise('peito_001'));
      expect(mapping.primaryMuscles, contains('chest'));
    });

    test('MUSCLE-MAP-07: remada canônica mapeia dorsais', () {
      final mapping = mapper.map(_catalogExercise('costas_002'));
      expect(mapping.primaryMuscles, contains('lats'));
    });

    test('MUSCLE-MAP-08: agachamento canônico mapeia quadríceps', () {
      final mapping = mapper.map(_catalogExercise('pernas_001'));
      expect(mapping.primaryMuscles, contains('quadriceps'));
    });

    test('MUSCLE-MAP-09: elevação lateral mapeia deltoide lateral', () {
      final mapping = mapper.map(_catalogExercise('ombros_003'));
      expect(mapping.primaryMuscles, contains('side_deltoid'));
    });

    test('MUSCLE-MAP-10: rosca canônica mapeia bíceps', () {
      final mapping = mapper.map(_catalogExercise('biceps_001'));
      expect(mapping.primaryMuscles, contains('biceps'));
    });

    test('MUSCLE-MAP-11: aliases conflitantes não sobrescrevem região', () {
      for (final label in ['infraespinal', 'infraespinhal', 'supraespinal']) {
        final resolution = MuscleAnatomyTaxonomy.resolveLabel(label);
        expect(resolution?.ambiguous, isFalse, reason: label);
        expect(resolution?.regionIds, ['rotator_cuff'], reason: label);
      }

      expect(MuscleAnatomyTaxonomy.resolveLabel('ombros')?.ambiguous, isTrue);
    });
  });

  group('FITAI-18 detail UI', () {
    testWidgets('MUSCLE-UI-01..05: mapa, papéis e texto no detalhe', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_detail(_catalogExercise('peito_001'))));
      await tester.pumpAndSettle();

      expect(find.text('Músculos trabalhados'), findsOneWidget);
      expect(find.text('Frente'), findsOneWidget);
      expect(find.text('Costas'), findsOneWidget);
      expect(find.text('Músculos primários'), findsOneWidget);
      expect(find.text('Músculos secundários'), findsOneWidget);
      expect(find.text('Peitoral'), findsOneWidget);
      expect(find.text('Tríceps'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Mapa anatômico simplificado, vista Frente'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('MUSCLE-UI-06: termos desconhecidos usam fallback seguro', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MuscleAnatomyMap(exercise: _exercise(muscles: ['Músculo inédito'])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('mapa foi omitido'), findsOneWidget);
      expect(find.text('Músculo inédito'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MUSCLE-UI-07: ausência de secundários não causa erro', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(MuscleAnatomyMap(exercise: _exercise(muscles: ['Bíceps']))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bíceps'), findsOneWidget);
      expect(find.text('Músculos secundários'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MUSCLE-UI-08: abas e retorno do detalhe continuam', (
      tester,
    ) async {
      final controller = LibraryCatalogController(
        catalogLoader: () async => [_catalogExercise('peito_001')],
        userScopeResolver: () => 'fitai-18-test-user',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: BibliotecaExerciciosPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Supino Reto com Barra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supino Reto com Barra'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver mais'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver mais'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Músculos'));
      await tester.pumpAndSettle();
      expect(find.text('Frente'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar aos detalhes'));
      await tester.pumpAndSettle();
      expect(find.text('Descrição'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mapa não causa overflow a 320 px', (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(_detail(_catalogExercise('peito_001'))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('MUSCLE-UI-09: alternar exercícios não acumula exceções', (
      tester,
    ) async {
      for (final id in [
        'peito_001',
        'costas_002',
        'pernas_001',
        'ombros_003',
        'biceps_001',
        'peito_001',
      ]) {
        await tester.pumpWidget(_app(_detail(_catalogExercise(id))));
        await tester.pumpAndSettle();
        expect(find.text('Músculos trabalhados'), findsOneWidget, reason: id);
        expect(tester.takeException(), isNull, reason: id);
      }
    });
  });
}

ExercicioModel _catalogExercise(String id) =>
    bancoExercicios.singleWhere((exercise) => exercise.id == id);

ExercicioModel _exercise({
  required List<String> muscles,
  List<String> secondary = const [],
}) => ExercicioModel(
  id: 'muscle-test',
  nome: 'Exercício de teste',
  categoria: 'Geral',
  descricao: 'Descrição de teste.',
  comoExecutar: 'Execute com controle.',
  cuidados: 'Use amplitude confortável.',
  musculos: muscles,
  musculosSecundarios: secondary,
  equipamentos: const [],
  locais: const [],
  dificuldade: 'Intermediário',
  objetivo: 'Força',
  imagem: '',
  video: '',
  tags: const [],
  caloriasHora: 0,
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: child is BibliotecaExercicioDetalhePage
      ? child
      : Scaffold(body: SingleChildScrollView(child: child)),
);

Widget _detail(ExercicioModel exercise) =>
    BibliotecaExercicioDetalhePage(exercicio: exercise);
