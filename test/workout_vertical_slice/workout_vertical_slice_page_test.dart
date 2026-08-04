import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_controller.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_page.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutVerticalSlicePage', () {
    testWidgets('registra uma serie e inicia descanso', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(_app(harness.controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar treino local'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir serie'));
      await tester.pumpAndSettle();

      expect(harness.controller.activeSets, hasLength(1));
      expect(harness.controller.restRemaining, greaterThan(Duration.zero));
      expect(find.textContaining('Descanso:'), findsOneWidget);
    });

    testWidgets('falha de persistencia preserva campos digitados', (
      tester,
    ) async {
      final harness = _Harness();
      await tester.pumpWidget(_app(harness.controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar treino local'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '72.5');
      await tester.enterText(find.byType(TextField).at(1), '9');
      harness.controller.failNextPersistence = true;

      await tester.tap(find.text('Concluir serie'));
      await tester.pumpAndSettle();

      expect(harness.controller.activeSets, isEmpty);
      expect(find.text('72.5'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(
        find.textContaining('Falha de persistencia simulada'),
        findsWidgets,
      );
    });

    testWidgets('offline mantem outbox pendente e retry a confirma', (
      tester,
    ) async {
      final harness = _Harness();
      await tester.pumpWidget(_app(harness.controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar treino local'));
      await tester.pumpAndSettle();
      harness.controller.setOffline(true);
      await tester.tap(find.text('Concluir serie'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline:'), findsOneWidget);
      expect(harness.controller.hasPendingOutbox, isTrue);

      harness.controller.setOffline(false);
      await tester.dragUntilVisible(
        find.text('Tentar sincronizar novamente'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(find.text('Tentar sincronizar novamente'));
      await tester.pumpAndSettle();
      expect(harness.controller.hasPendingOutbox, isFalse);
    });

    testWidgets(
      'recupera sessao existente e permite descartar com confirmacao',
      (tester) async {
        final harness = _Harness();
        await harness.repository.startOrRecoverExample();
        await tester.pumpWidget(_app(harness.controller));
        await tester.pumpAndSettle();

        expect(find.text('Treino em andamento'), findsOneWidget);
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        expect(find.text('Iniciar treino local'), findsOneWidget);
      },
    );

    testWidgets('finaliza o treino e suporta texto ampliado sem overflow', (
      tester,
    ) async {
      final harness = _Harness();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: _app(harness.controller),
        ),
      );
      // A tela atualiza o relogio por Timer.periodic; espera delimitada evita
      // que pumpAndSettle aguarde indefinidamente por esse relogio em fake time.
      await _pumpUntil(tester, () => !harness.controller.isLoading);
      await tester.tap(find.text('Iniciar treino local'));
      await _pumpUntil(
        tester,
        () =>
            !harness.controller.isSaving &&
            harness.controller.activeSession != null,
      );
      for (var index = 0; index < 3; index++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      await tester.tap(find.text('Finalizar treino'));
      await _pumpUntil(
        tester,
        () =>
            !harness.controller.isSaving &&
            harness.controller.activeSession == null,
      );

      expect(harness.controller.activeSession, isNull);
      expect(find.text('Iniciar treino local'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app(WorkoutVerticalSliceController controller) => MaterialApp(
  theme: ThemeData.dark(),
  home: WorkoutVerticalSlicePage(controller: controller),
);

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (condition()) {
      await tester.pump();
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('A tela nao atingiu o estado esperado no intervalo delimitado.');
}

class _Harness {
  _Harness() {
    store = _WidgetMemoryStore();
    transport = DebugWorkoutSyncTransport();
    progressionEngine = ProgressionEngine(
      store: InMemoryProgressionStore(),
      legacyReader: () async =>
          const LegacyProgression(level: 1, xpIntoLevel: 0),
      legacyWriter: (_) async {},
    );
    repository = WorkoutVerticalRepository(
      localStore: store,
      transport: transport,
    );
    controller = WorkoutVerticalSliceController(
      repository: WorkoutVerticalRepository(
        localStore: store,
        transport: transport,
      ),
      debugTransport: transport,
      progressionEngine: progressionEngine,
    );
  }

  late final _WidgetMemoryStore store;
  late final DebugWorkoutSyncTransport transport;
  late final WorkoutVerticalRepository repository;
  late final WorkoutVerticalSliceController controller;
  late final ProgressionEngine progressionEngine;
}

class _WidgetMemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    snapshot = WorkoutSliceSnapshot.fromJson(value.toJson());
  }
}
