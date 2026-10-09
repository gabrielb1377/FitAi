import 'dart:convert';

import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/plans/data/remote_plan_mapper.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The resolved plugin interface injects disk failure without a new dependency.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Disk extends InMemorySharedPreferencesStore {
  _Disk() : super.empty();
  String? failKey;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == failKey) return false;
    return super.setValue(valueType, key, value);
  }
}

Map<String, dynamic> _plan(String name, {String id = 'plan'}) => {
  'id': id,
  'nome': name,
  'exercicios': <Object>[],
  '_remoteUpdatedAt': '2026-10-08T12:00:00.000Z',
};

Future<bool> _apply({
  Map<String, String> baseline = const {},
  Set<String> pending = const {},
  String cursor = '',
  String next = '',
  List<Map<String, dynamic>>? plans,
  int? revision,
}) => StorageService.applyRemotePlans(
  userId: 'owner',
  accountRevision: revision ?? AccountSessionLifecycle.revision.value,
  expectedCursor: cursor,
  nextCursor: next,
  baseline: baseline,
  pendingIds: pending,
  plans: plans ?? [_plan('Remote')],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser('owner');
  });
  tearDown(() => AccountSessionLifecycle.setActiveUser(null));

  test('S21-H: failed plan write cannot advance durable cursor', () async {
    final disk = _Disk()..failKey = 'flutter.treinos';
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = disk;
    await expectLater(_apply(next: 'page2'), throwsStateError);
    SharedPreferences.resetStatic();
    expect(await StorageService.planPullCursor('owner'), isEmpty);
    expect(await StorageService.carregarTreinos(), isEmpty);
    disk.failKey = null;
    expect(await _apply(next: 'page2'), isTrue);
    SharedPreferences.resetStatic();
    expect(await StorageService.planPullCursor('owner'), 'page2');
    expect((await StorageService.carregarTreinos()).single.nome, 'Remote');
  });

  test(
    'S21-H: failed cursor write replays durable plans without duplication',
    () async {
      final key =
          'flutter.fitia.planPull.v1.user.${LocalAccountDataBoundary.scopeForUser('owner')}';
      final disk = _Disk()..failKey = key;
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = disk;
      await expectLater(_apply(next: 'page2'), throwsStateError);
      SharedPreferences.resetStatic();
      expect(await StorageService.planPullCursor('owner'), isEmpty);
      expect(await StorageService.carregarTreinos(), hasLength(1));
      disk.failKey = null;
      expect(
        await _apply(
          baseline: await StorageService.planPullBaseline(),
          next: 'page2',
        ),
        isTrue,
      );
      SharedPreferences.resetStatic();
      expect(await StorageService.carregarTreinos(), hasLength(1));
    },
  );

  test(
    'S21-I: pending edits and edits during GET retain local values',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('treinos', [jsonEncode(_plan('Original'))]);
      final baseline = await StorageService.planPullBaseline();
      await prefs.setStringList('treinos', [jsonEncode(_plan('Local edit'))]);
      expect(await _apply(baseline: baseline), isTrue);
      expect(
        (await StorageService.carregarTreinos()).single.nome,
        'Local edit',
      );
      expect(
        await _apply(
          baseline: await StorageService.planPullBaseline(),
          pending: {'plan'},
        ),
        isTrue,
      );
      expect(
        (await StorageService.carregarTreinos()).single.nome,
        'Local edit',
      );
    },
  );

  test(
    'S21-I: merge retains unrelated plans, receipts and local-only fields',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('treinos', [
        jsonEncode({
          ..._plan('Local'),
          'local': 'Academia',
          '_aiActionReceipts': [
            {'id': 'receipt', 'owner': 'owner'},
          ],
        }),
        jsonEncode(_plan('Unrelated', id: 'other')),
      ]);
      expect(
        await _apply(baseline: await StorageService.planPullBaseline()),
        isTrue,
      );
      final values = prefs
          .getStringList('treinos')!
          .map((raw) => jsonDecode(raw) as Map)
          .toList();
      expect(values.map((v) => v['id']), ['plan', 'other']);
      expect(values.first['nome'], 'Remote');
      expect(values.first['local'], 'Academia');
      expect(values.first['_aiActionReceipts'], hasLength(1));
      expect(
        prefs.getKeys().any((k) => k.contains('SyncQueue') || k == 'xp'),
        isFalse,
      );
    },
  );

  test(
    'S21-D/F: owner change and tombstones prevent import/resurrection',
    () async {
      final revision = AccountSessionLifecycle.revision.value;
      AccountSessionLifecycle.setActiveUser('different');
      expect(await _apply(revision: revision), isFalse);
      AccountSessionLifecycle.setActiveUser('owner');
      await StorageService.applyPlanDeletions('owner', {
        'revision': '1',
        'deletions': [
          {'id': 'plan'},
        ],
      });
      expect(await _apply(), isTrue);
      expect(await StorageService.carregarTreinos(), isEmpty);
    },
  );

  test(
    'S21-H/I: stale cursor and older remote version cannot overwrite',
    () async {
      expect(await _apply(cursor: 'stale', next: 'bad'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('treinos', [
        jsonEncode({
          ..._plan('Newer'),
          '_remoteUpdatedAt': '2026-10-09T12:00:00Z',
        }),
      ]);
      expect(
        await _apply(baseline: await StorageService.planPullBaseline()),
        isTrue,
      );
      expect((await StorageService.carregarTreinos()).single.nome, 'Newer');
    },
  );

  test(
    'S21 mapper: canonical identity, stable occurrence and prescription',
    () {
      final mapped = RemotePlanMapper.map({
        'id': 'plan',
        'userId': 'owner',
        'name': 'Plan',
        'source': 'manual',
        'days': [
          {
            'name': 'A',
            'muscleGroup': 'Ombros',
            'order': 2,
            'exercises': [
              {
                'exercise': {'id': 'ombros_003', 'name': 'Elevacao lateral'},
                'sets': 4,
                'repsText': '8-10',
                'restSeconds': 75,
              },
            ],
          },
        ],
      }, 'owner');
      final exercise = (mapped['exercicios'] as List).single as Map;
      expect(exercise['id'], 'ombros_003');
      expect(exercise['canonicalExerciseId'], 'ombros_003');
      expect(exercise['series'], 4);
      expect(exercise['repeticoes'], '8-10');
      expect(exercise['descansoSegundos'], 75);
      expect((mapped['planoDias'] as List).single['ordem'], 2);
      expect(
        () => RemotePlanMapper.map({'id': 'x', 'userId': 'other'}, 'owner'),
        throwsStateError,
      );
    },
  );
}
