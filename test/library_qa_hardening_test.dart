import 'dart:convert';
import 'dart:io';

import 'package:fitai/core/exercises/exercise_identity.dart';
import 'package:fitai/core/exercises/exercise_library_intelligence.dart';
import 'package:fitai/data/exercicios/exercicios.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/screens/exercicios/biblioteca_exercicios_page.dart';
import 'package:fitai/widgets/exercicio_gif_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'catalog canonical data has unique identities and required core metadata',
    () {
      final catalog = List<ExercicioModel>.from(bancoExercicios);
      final duplicateIds = _duplicates(catalog.map((item) => item.id.trim()));
      final duplicateNames = _duplicates(
        catalog.map((item) => ExerciseIdentity.normalizeName(item.nome)),
      );
      final missingCoreMetadata = catalog
          .where(_isMissingCoreMetadata)
          .toList();
      final withoutMedia = catalog.where(_hasNoMedia).toList();
      final mediaAudit = _mediaAudit(catalog);

      // This line is intentionally machine-readable for VS7.4 audit evidence.
      // ignore: avoid_print
      print(
        'LIBRARY_CATALOG_AUDIT '
        'total=${catalog.length} '
        'duplicateIds=${duplicateIds.length} '
        'duplicateNames=${duplicateNames.length} '
        'missingCore=${missingCoreMetadata.length} '
        'withoutMedia=${withoutMedia.length} '
        'directMedia=${mediaAudit.direct.length} '
        'manifestMedia=${mediaAudit.manifest.length} '
        'unresolvedMedia=${mediaAudit.unresolved.length}',
      );
      // ignore: avoid_print
      print(
        'LIBRARY_CATALOG_DUPLICATE_NORMALIZED_NAMES '
        '${duplicateNames.toList()..sort()}',
      );

      expect(catalog, isNotEmpty);
      expect(
        duplicateIds,
        isEmpty,
        reason: 'The canonical catalog cannot repeat IDs.',
      );
      expect(
        missingCoreMetadata,
        isEmpty,
        reason:
            'Every catalog exercise needs name, category, muscle, equipment and difficulty.',
      );
    },
  );

  test(
    'search accepts canonical aliases, normalized text and token order',
    () async {
      final controller = await _controller();
      addTearDown(controller.dispose);

      const expectations = <String, String>{
        'supino': 'supino',
        'bench press': 'supino',
        'supino barra': 'supino',
        'barra supino': 'supino',
        'levantamento terra': 'terra',
        'deadlift': 'terra',
        'costas': 'costas',
        'halteres': 'halter',
        'cabo': 'cabo',
        'gluteos': 'glute',
      };

      for (final entry in expectations.entries) {
        controller.updateQuery(entry.key);
        expect(
          controller.visibleExercises,
          isNotEmpty,
          reason: 'Expected local results for "${entry.key}".',
        );
        expect(
          controller.visibleExercises
              .map((item) => _searchText(item))
              .any((value) => value.contains(entry.value)),
          isTrue,
          reason: 'Expected a relevant result for "${entry.key}".',
        );
      }

      controller.clearQuery();
      expect(controller.query, isEmpty);
      expect(controller.visibleExercises, isNotEmpty);
    },
  );

  test(
    'combined filters stay synchronized with result count and query',
    () async {
      final controller = await _controller();
      addTearDown(controller.dispose);

      const selection = LibraryFilterSelection(
        muscleGroup: 'Peito',
        equipment: 'Livre',
        level: 'Intermediário',
        category: 'Força',
        movement: 'Empurrar',
        objective: 'Hipertrofia',
      );
      controller.applyFilters(selection);
      final filtered = controller.visibleExercises;

      expect(filtered, isNotEmpty);
      expect(controller.countForFilters(selection), filtered.length);
      expect(
        filtered.every((item) => _searchText(item).contains('peito')),
        isTrue,
      );

      controller.updateQuery('bench press');
      expect(controller.visibleExercises, isNotEmpty);
      expect(
        controller.countForFilters(selection),
        controller.visibleExercises.length,
      );

      controller.clearFilters();
      expect(controller.filters.isActive, isFalse);
      expect(controller.visibleExercises, isNotEmpty);
    },
  );

  test(
    'favorites and recents survive controller recreation without duplicates',
    () async {
      final first = await _controller();
      final exercise = first.exercises.first;
      await first.toggleFavorite(exercise);
      await first.registerViewed(exercise);
      await first.registerViewed(exercise);
      first.dispose();

      final restored = await _controller();
      addTearDown(restored.dispose);

      expect(restored.isFavorite(exercise), isTrue);
      expect(restored.recentIds, [exercise.id]);
      expect(restored.recentExercises.map((item) => item.id), [exercise.id]);
    },
  );

  test(
    'usage ranking persists and filters restart without stale selections',
    () async {
      final first = await _controller();
      final exercise = first.exercises.first;
      await first.registerUse(exercise, ExerciseUsageEvent.addedToPlan);
      first.applyFilters(const LibraryFilterSelection(muscleGroup: 'Peito'));
      expect(first.filters.isActive, isTrue);
      first.dispose();

      final restored = await _controller();
      addTearDown(restored.dispose);

      expect(restored.filters.isActive, isFalse);
      expect(restored.mostUsedExercises.first.id, exercise.id);
    },
  );

  test(
    'related exercises and substitutions are deterministic for core movements',
    () async {
      final controller = await _controller();
      addTearDown(controller.dispose);

      const samples = <List<String>>[
        ['supino'],
        ['agachamento'],
        ['terra'],
        ['remada'],
        ['rosca', 'direta'],
        ['triceps', 'pulley'],
        ['elevacao', 'lateral'],
        ['prancha'],
        ['leg', 'press'],
        ['flexao'],
      ];

      for (final terms in samples) {
        final source = controller.exercises.firstWhere(
          (item) => terms.every(_searchText(item).contains),
          orElse: () =>
              throw StateError('Missing audit sample: ${terms.join(' ')}'),
        );
        final related = controller.relatedRecommendations(source);
        final substitutions = controller.substitutionsFor(source);

        expect(related, isNotEmpty, reason: source.nome);
        expect(
          related.every((item) => item.exercise.id != source.id),
          isTrue,
          reason: source.nome,
        );
        expect(
          related.map((item) => item.exercise.id).toSet().length,
          related.length,
          reason: source.nome,
        );
        expect(related.every((item) => item.reasons.isNotEmpty), isTrue);
        expect(
          substitutions.every((item) => item.exercise.id != source.id),
          isTrue,
          reason: source.nome,
        );
        expect(
          substitutions.map((item) => item.exercise.id).toSet().length,
          substitutions.length,
          reason: source.nome,
        );
      }
    },
  );

  test(
    'current local catalog search p50 and p95 meet the interactive budget',
    () async {
      final controller = await _controller();
      addTearDown(controller.dispose);
      const queries = <String>[
        'supino',
        'bench press',
        'levantamento terra',
        'deadlift',
        'costas',
        'halteres',
        'cabo',
        'gluteos',
      ];
      final samples = <int>[];

      for (var index = 0; index < 40; index++) {
        final watch = Stopwatch()..start();
        controller.updateQuery(queries[index % queries.length]);
        controller.visibleExercises;
        watch.stop();
        samples.add(watch.elapsedMicroseconds);
      }
      samples.sort();
      final p50 = samples[samples.length ~/ 2] / 1000;
      final p95 = samples[(samples.length * .95).floor() - 1] / 1000;

      // ignore: avoid_print
      print(
        'LIBRARY_CURRENT_CATALOG_BENCHMARK p50=${p50.toStringAsFixed(2)}ms p95=${p95.toStringAsFixed(2)}ms catalog=${controller.exercises.length}',
      );
      expect(p50, lessThan(50));
      expect(p95, lessThan(100));
    },
  );

  test(
    'local search and filter p95 remain below 100ms at five thousand items',
    () async {
      final source = List<ExercicioModel>.from(bancoExercicios);
      final catalog = List<ExercicioModel>.generate(
        5000,
        (index) => source[index % source.length],
        growable: false,
      );
      final controller = LibraryCatalogController(
        catalogLoader: () async => catalog,
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      final samples = <int>[];
      for (var index = 0; index < 25; index++) {
        final watch = Stopwatch()..start();
        controller.updateQuery(
          index.isEven ? 'bench press' : 'levantamento terra',
        );
        controller.visibleExercises;
        controller.applyFilters(
          const LibraryFilterSelection(category: 'Força', movement: 'Empurrar'),
        );
        controller.visibleExercises;
        watch.stop();
        samples.add(watch.elapsedMicroseconds);
        controller.clearFilters();
      }
      samples.sort();
      final p50 = samples[samples.length ~/ 2] / 1000;
      final p95 = samples[(samples.length * .95).floor() - 1] / 1000;

      // ignore: avoid_print
      print(
        'LIBRARY_PERFORMANCE_BENCHMARK p50=${p50.toStringAsFixed(2)}ms p95=${p95.toStringAsFixed(2)}ms catalog=5000',
      );
      expect(p95, lessThan(100));
    },
  );

  testWidgets(
    'legacy category media path falls back to the bundled root asset',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: ExercicioGifImage(
                imagem: 'assets/gifs/legacy/sit_up.gif',
                titulo: 'Legacy media fallback',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, 'assets/gifs/sit_up.gif');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('library keeps filter semantics and survives 200 percent text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const BibliotecaExerciciosPage(offline: true),
      ),
    );
    await tester.pumpAndSettle();

    final filter = find.byTooltip('Filtros');
    expect(filter, findsOneWidget);
    expect(
      tester.getSemantics(filter),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<LibraryCatalogController> _controller() async {
  final controller = LibraryCatalogController(
    catalogLoader: () async => List<ExercicioModel>.from(bancoExercicios),
  );
  await controller.initialize();
  return controller;
}

Set<String> _duplicates(Iterable<String> values) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    if (!seen.add(value)) duplicates.add(value);
  }
  return duplicates;
}

bool _isMissingCoreMetadata(ExercicioModel item) =>
    item.id.trim().isEmpty ||
    item.nome.trim().isEmpty ||
    item.categoria.trim().isEmpty ||
    item.musculos.isEmpty ||
    item.equipamentos.isEmpty ||
    item.dificuldade.trim().isEmpty;

bool _hasNoMedia(ExercicioModel item) =>
    item.imagem.trim().isEmpty &&
    item.gifPath.trim().isEmpty &&
    item.video.trim().isEmpty;

bool _hasLocalMedia(ExercicioModel item) {
  final path = item.gifPath.trim().isNotEmpty ? item.gifPath : item.imagem;
  if (path.trim().isEmpty || path.startsWith('http')) return true;
  if (File(path).existsSync()) return true;
  final separator = path.replaceAll('\\', '/').lastIndexOf('/');
  final basename = separator < 0 ? path : path.substring(separator + 1);
  return File('assets/gifs/$basename').existsSync();
}

_MediaAudit _mediaAudit(Iterable<ExercicioModel> catalog) {
  final decoded =
      jsonDecode(File('assets/gifs/gif_manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final direct = <ExercicioModel>[];
  final manifest = <ExercicioModel>[];
  final unresolved = <ExercicioModel>[];

  for (final exercise in catalog) {
    if (_hasLocalMedia(exercise)) {
      direct.add(exercise);
      continue;
    }
    final path = decoded[_gifManifestKey(exercise.nome)]?.toString();
    if (path != null && File('assets/gifs/$path').existsSync()) {
      manifest.add(exercise);
    } else {
      unresolved.add(exercise);
    }
  }

  return _MediaAudit(
    direct: direct,
    manifest: manifest,
    unresolved: unresolved,
  );
}

String _gifManifestKey(String name) {
  final normalized = ExerciseIdentity.normalizeName(name);
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class _MediaAudit {
  const _MediaAudit({
    required this.direct,
    required this.manifest,
    required this.unresolved,
  });

  final List<ExercicioModel> direct;
  final List<ExercicioModel> manifest;
  final List<ExercicioModel> unresolved;
}

String _searchText(ExercicioModel item) => ExerciseIdentity.normalizeName(
  [
    item.nome,
    item.categoria,
    ...item.musculos,
    ...item.equipamentos,
    ...item.tags,
  ].join(' '),
);
