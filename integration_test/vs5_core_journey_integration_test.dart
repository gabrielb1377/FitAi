import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_history_page.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_plans_page.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('VS5 plano, treino offline, resumo e historico funcionam', (
    tester,
  ) async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    final plan = DevFixtures.workouts.single;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CoreJourneyPlansPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(plan.nome).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Concluir serie'),
      300,
      scrollable: find.byType(Scrollable),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '55');
    await tester.enterText(fields.at(1), '10');
    await tester.tap(find.text('Concluir serie'));
    await tester.pumpAndSettle();

    final session = controller.activeSession;
    expect(session, isNotNull);
    expect(controller.setsFor(session!.id), hasLength(1));

    await tester.ensureVisible(find.text('Finalizar treino'));
    await tester.tap(find.text('Finalizar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();

    expect(find.text('Treino concluido'), findsOneWidget);
    await tester.tap(find.text('Ver historico'));
    await tester.pumpAndSettle();
    expect(find.byType(CoreJourneyHistoryPage), findsOneWidget);
    expect(controller.completedSessions, hasLength(1));
  });
}

Future<CoreJourneyController> _controller() async {
  final controller = CoreJourneyController(
    identityResolver: () async => const CoreJourneyIdentity(
      userId: 'vs5-integration-user',
      name: 'Teste VS5',
      isAuthenticated: true,
    ),
    planLoader: () async => DevFixtures.workouts,
    repositoryFactory: (_) async => WorkoutVerticalRepository(
      localStore: _MemoryStore(),
      transport: DebugWorkoutSyncTransport(),
    ),
  );
  await controller.initialize();
  return controller;
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot _snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => _snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
