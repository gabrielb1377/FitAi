import 'dart:async';

import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/home/data/home_workout_history_reader.dart';
import 'package:fitai/features/progression/data/progression_local_store.dart';
import 'package:fitai/features/progression/domain/progression_models.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/historico_treino_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser('owner-a');
  });
  tearDown(() => AccountSessionLifecycle.setActiveUser(null));

  test(
    'Home reads canonical completion and ledger XP without writing',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await _store(preferences, 'owner-a').write(_snapshot());
      final progression = InMemoryProgressionStore();
      await progression.save(
        const ProgressionSnapshot.empty(
          userId: 'owner-a',
        ).copyWith(events: [_xp('owner-a'), _xp('owner-a'), _xp('owner-b')]),
      );
      final before = _values(preferences);
      final reader = HomeWorkoutHistoryReader(progressionStore: progression);
      final result = await reader.load();
      expect(result.single.id, 'session-a');
      expect(result.single.nomeTreino, 'Upper A');
      expect(result.single.volumeTotal, 120);
      expect(result.single.seriesConcluidas, 1);
      expect(result.single.tempoFormatado, '30:00');
      expect(result.single.xpGanho, 15);
      expect(_values(preferences), before);
      expect((await reader.load()).length, 1);
      expect((await progression.load('owner-a'))!.events.length, 3);
    },
  );

  test('canonical session overrides duplicate legacy metrics', () async {
    final preferences = await SharedPreferences.getInstance();
    await _store(preferences, 'owner-a').write(_snapshot());
    final reader = HomeWorkoutHistoryReader(
      legacyLoader: () async => [_legacy('session-a'), _legacy('legacy-only')],
    );
    final result = await reader.load();
    expect(result, hasLength(2));
    expect(
      result.singleWhere((item) => item.id == 'session-a').volumeTotal,
      120,
    );
    expect(result.singleWhere((item) => item.id == 'session-a').xpGanho, 0);
    expect(result.singleWhere((item) => item.id == 'legacy-only').xpGanho, 7);
  });

  test('legacy-only history retains its display fields', () async {
    final legacy = _legacy('old');
    final result = await HomeWorkoutHistoryReader(
      legacyLoader: () async => [legacy],
    ).load();
    expect(result.single, same(legacy));
  });

  test('fresh reader after restart reads the existing journal', () async {
    final preferences = await SharedPreferences.getInstance();
    await _store(preferences, 'owner-a').write(_snapshot());
    expect((await HomeWorkoutHistoryReader().load()).single.id, 'session-a');
    expect((await HomeWorkoutHistoryReader().load()).single.id, 'session-a');
  });

  test('another account cannot read the previous account journal', () async {
    final preferences = await SharedPreferences.getInstance();
    await _store(preferences, 'owner-a').write(_snapshot());
    AccountSessionLifecycle.setActiveUser('owner-b');
    expect(await HomeWorkoutHistoryReader().load(), isEmpty);
    expect((await _store(preferences, 'owner-a').read()).sets, hasLength(1));
  });

  test('account switch during load discards stale results', () async {
    final pending = Completer<List<HistoricoTreinoModel>>();
    final loading = HomeWorkoutHistoryReader(
      legacyLoader: () => pending.future,
    ).load();
    AccountSessionLifecycle.setActiveUser('owner-b');
    pending.complete([_legacy('private-a')]);
    expect(await loading, isEmpty);
  });

  test(
    'incomplete remote history does not appear as a completed workout',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final source = _snapshot();
      await _store(preferences, 'owner-a').write(
        source.copyWith(
          sessions: [
            source.sessions.single.copyWith(remoteHistoryComplete: false),
          ],
        ),
      );
      expect(await HomeWorkoutHistoryReader().load(), isEmpty);
    },
  );
}

SharedPreferencesWorkoutVerticalLocalStore _store(
  SharedPreferences preferences,
  String owner,
) => SharedPreferencesWorkoutVerticalLocalStore(preferences, userScope: owner);

Map<String, Object?> _values(SharedPreferences preferences) => {
  for (final key in preferences.getKeys()) key: preferences.get(key),
};

final _end = DateTime.utc(2026, 10, 9, 12);

WorkoutSliceSnapshot _snapshot() => WorkoutSliceSnapshot(
  schemaVersion: 1,
  sessions: [
    WorkoutSessionLocal(
      id: 'session-a',
      planId: 'plan-a',
      workoutId: 'upper-a',
      workoutName: 'Upper A',
      startedAt: _end.subtract(const Duration(minutes: 30)),
      finishedAt: _end,
      status: WorkoutSessionStatus.completed,
      currentExerciseIndex: 0,
      currentSetIndex: 1,
      updatedAt: _end,
      syncStatus: WorkoutSyncStatus.synced,
      version: 1,
    ),
  ],
  sets: [
    WorkoutSetLocal(
      id: 'set-a',
      sessionId: 'session-a',
      exerciseId: 'ombros_003',
      exerciseName: 'Elevacao lateral',
      setIndex: 0,
      weight: 12,
      reps: 10,
      completedAt: _end,
      updatedAt: _end,
      syncStatus: WorkoutSyncStatus.synced,
      version: 1,
    ),
  ],
  outbox: const [],
);

XpEvent _xp(String owner) => XpEvent(
  id: '$owner-xp',
  userId: owner,
  sourceType: XpSourceType.workout,
  sourceId: 'session-a',
  amount: 15,
  reason: 'Workout completed',
  createdAt: _end,
  idempotencyKey: '$owner:workout:session-a',
  syncStatus: ProgressionSyncStatus.synced,
  version: 1,
);

HistoricoTreinoModel _legacy(String id) => HistoricoTreinoModel(
  id: id,
  nomeTreino: 'Legacy',
  dataHora: _end,
  tempoSegundos: 60,
  tempoFormatado: '01:00',
  exerciciosTotais: 1,
  exerciciosConcluidos: 1,
  xpGanho: 7,
  caloriasEstimadas: 0,
  objetivo: 'Legado',
  nivel: 'Legado',
  volumeTotal: 999,
);
