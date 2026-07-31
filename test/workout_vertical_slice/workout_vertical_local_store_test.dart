import 'dart:convert';

import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'journal recupera a revisao atual quando o slot ativo corrompe',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesWorkoutVerticalLocalStore(
        preferences,
        userScope: 'user-a',
      );
      final repository = _repository(store);
      final session = await repository.startOrRecoverExample();
      await repository.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: 0,
        weight: 55,
        reps: 10,
      );

      final activeSlot = preferences.getString(
        SharedPreferencesWorkoutVerticalLocalStore.journalActiveKeyFor(
          'user-a',
        ),
      )!;
      final activeDataKey = activeSlot == 'a'
          ? SharedPreferencesWorkoutVerticalLocalStore.journalSlotAKeyFor(
              'user-a',
            )
          : SharedPreferencesWorkoutVerticalLocalStore.journalSlotBKeyFor(
              'user-a',
            );
      await preferences.setString(activeDataKey, '{corrompido');

      final recovered = await store.read();
      expect(recovered.sets, hasLength(1));
      expect(recovered.sets.single.weight, 55);
    },
  );

  test(
    'journal escolhe snapshot valido quando o ponteiro ativo e invalido',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesWorkoutVerticalLocalStore(preferences);
      final repository = _repository(store);
      await repository.startOrRecoverExample();
      await preferences.setString(
        SharedPreferencesWorkoutVerticalLocalStore.journalActiveKeyFor(
          SharedPreferencesWorkoutVerticalLocalStore.anonymousScope,
        ),
        'invalido',
      );

      expect((await store.read()).sessions, hasLength(1));
    },
  );

  test(
    'migra snapshot V1 sem apagar a origem antes de concluir o journal',
    () async {
      final initialPreferences = await SharedPreferences.getInstance();
      final sourceStore = SharedPreferencesWorkoutVerticalLocalStore(
        initialPreferences,
      );
      final sourceRepository = _repository(sourceStore);
      final session = await sourceRepository.startOrRecoverExample();
      await sourceRepository.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: 0,
        weight: 60,
        reps: 8,
      );
      final legacyValue = jsonEncode((await sourceRepository.load()).toJson());

      SharedPreferences.setMockInitialValues({
        SharedPreferencesWorkoutVerticalLocalStore.storageKey: legacyValue,
      });
      final migratedPreferences = await SharedPreferences.getInstance();
      final migratedStore = SharedPreferencesWorkoutVerticalLocalStore(
        migratedPreferences,
      );

      final migrated = await migratedStore.read();
      expect(migrated.sets.single.weight, 60);
      expect(
        migratedPreferences.getString(
          SharedPreferencesWorkoutVerticalLocalStore.journalSlotAKeyFor(
            SharedPreferencesWorkoutVerticalLocalStore.anonymousScope,
          ),
        ),
        isNotEmpty,
      );
    },
  );

  test(
    'preserva dados ilegiveis para recuperacao sem limpar chaves originais',
    () async {
      const scope = 'user-a';
      SharedPreferences.setMockInitialValues({
        SharedPreferencesWorkoutVerticalLocalStore.journalActiveKeyFor(scope):
            'a',
        SharedPreferencesWorkoutVerticalLocalStore.journalSlotAKeyFor(scope):
            '{a',
        SharedPreferencesWorkoutVerticalLocalStore.journalSlotBKeyFor(scope):
            '{b',
      });
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesWorkoutVerticalLocalStore(
        preferences,
        userScope: scope,
      );

      await expectLater(store.read(), throwsStateError);
      expect(
        preferences.getString(
          SharedPreferencesWorkoutVerticalLocalStore.recoveryKeyFor(scope),
        ),
        contains('slotA'),
      );
      expect(
        preferences.getString(
          SharedPreferencesWorkoutVerticalLocalStore.journalSlotAKeyFor(scope),
        ),
        '{a',
      );
    },
  );
}

WorkoutVerticalRepository _repository(WorkoutVerticalLocalStore store) =>
    WorkoutVerticalRepository(
      localStore: store,
      transport: DebugWorkoutSyncTransport(),
    );
