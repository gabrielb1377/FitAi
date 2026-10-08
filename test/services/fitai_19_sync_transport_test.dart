import 'dart:async';
import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/features/activities/data/activity_sync_gateway.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/services/network_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.configure(baseUrl: 'https://sync.fitia.test');
  });
  tearDown(ApiConfig.reset);

  test(
    'SYNC-19-05: mutation is durable before network dispatch/lost ACK',
    () async {
      final prefs = await SharedPreferences.getInstance();
      int? durableCount;
      final service = await _service((request) async {
        if (request.method == 'GET') return http.Response('{}', 503);
        durableCount = prefs.getStringList('fitaiSyncQueue')?.length;
        throw http.ClientException('ACK lost');
      });
      await service.syncGoals([
        {'id': 'goal-a'},
      ]);
      expect(durableCount, 1);
      expect(await service.pendingCount(), 1);
      final restarted = await _service((_) async => http.Response('{}', 200));
      await restarted.flushPending();
      expect(await restarted.pendingCount(), 0);
    },
  );

  test(
    'SYNC-19-06: flush preserves a mutation enqueued while awaiting ACK',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('fitaiSyncQueue', [
        jsonEncode({
          'id': 'user-a_old',
          'ownerUserId': 'user-a',
          'path': '/sync/goals',
          'payload': {
            'items': [
              {'id': 'old'},
            ],
          },
        }),
      ]);
      final started = Completer<void>();
      final release = Completer<void>();
      final service = await _service((request) async {
        if (request.method == 'GET') return http.Response('{}', 200);
        if ((jsonDecode(request.body)['items'] as List).single['id'] == 'old') {
          started.complete();
          await release.future;
          return http.Response('{}', 200);
        }
        throw http.ClientException('offline');
      });
      final flushing = service.flushPending();
      await started.future;
      await service.syncGoals([
        {'id': 'new'},
      ]);
      release.complete();
      await flushing;
      expect(await service.pendingCount(), 1);
      final saved = jsonDecode(prefs.getStringList('fitaiSyncQueue')!.single);
      expect(saved['payload']['items'].single['id'], 'new');
    },
  );

  test(
    'SYNC-19-07: auth refresh retries same payload once using existing lifecycle',
    () async {
      var calls = 0;
      final service = await _service(
        (request) async {
          calls++;
          return http.Response('{}', calls == 1 ? 401 : 200);
        },
        refreshClient: MockClient((request) async {
          expect(request.url.path, '/auth/refresh');
          return http.Response(
            jsonEncode({
              'token': _token('new'),
              'refreshToken': 'test-refresh-new',
              'user': {'id': 'user-a', 'name': 'A', 'email': 'a@fitia.test'},
            }),
            200,
          );
        }),
      );
      expect(
        await service.postAuthenticatedJsonForUser(
          userId: 'user-a',
          path: '/activities/sync',
          payload: {'id': 'stable'},
        ),
        {},
      );
      expect(calls, 2);
    },
  );

  test(
    'SYNC-19-08: steps mutation identity is stable and distinct across devices',
    () async {
      final ids = <String>[];
      final service = await _service((request) async {
        final id =
            jsonDecode(request.body)['steps'].single['mutationId'] as String;
        ids.add(id);
        return http.Response(
          jsonEncode({
            'ack': {
              'accepted': [
                {'mutationId': id},
              ],
            },
          }),
          200,
        );
      });
      final gateway = HttpActivitySyncGateway(syncService: service);
      for (final device in ['device-a', 'device-a', 'device-b']) {
        final result = await gateway.push(
          userId: 'user-a',
          deviceId: device,
          afterRevision: '0',
          runs: [],
          steps: [
            {'mutationId': 'steps:2026-10-07:v1'},
          ],
        );
        expect(
          result!['ack']['accepted'].single['mutationId'],
          'steps:2026-10-07:v1',
        );
      }
      expect(ids[0], ids[1]);
      expect(ids[0], isNot(ids[2]));
    },
  );

  test(
    'SYNC-19-09: old ACK cannot clear a newer tombstone with the same queue key',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final service = await _service((request) async {
        if (request.method == 'GET') return http.Response('{}', 503);
        if (request.url.path == '/sync/workouts') {
          started.complete();
          await release.future;
          return http.Response('{}', 200);
        }
        throw http.ClientException('offline');
      });
      final create = service.syncWorkouts([
        {'id': 'plan-a'},
      ]);
      await started.future;
      await service.deleteWorkout('plan-a');
      release.complete();
      await create;
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      final pending = jsonDecode(prefs.getStringList('fitaiSyncQueue')!.single);
      expect(pending['path'], '/sync/workouts/delete');
      expect(pending['payload']['id'], 'plan-a');
    },
  );

  test(
    'SYNC-19-10: account change during request rejects stale response/refresh',
    () async {
      final store = InMemoryAuthSessionStore();
      await store.write(jsonEncode(_session('user-a').toJson()));
      final auth = AuthService(bypassLogin: false, sessionStore: store);
      var sends = 0;
      final service = SyncService.forTesting(
        authService: auth,
        networkService: NetworkService(
          client: MockClient((request) async {
            sends++;
            await store.write(jsonEncode(_session('user-b').toJson()));
            await auth.restoreSession();
            return http.Response('{}', 401);
          }),
        ),
      );
      final result = await service.getAuthenticatedJsonForUser(
        userId: 'user-a',
        path: '/activities/sync',
      );
      expect(result, isNull);
      expect(sends, 1);
      expect((await auth.restoreSession())!.userId, 'user-b');
    },
  );

  test(
    'SYNC-19-11: simultaneous flush triggers dispatch a queued item once',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('fitaiSyncQueue', [
        jsonEncode({
          'id': 'user-a_pending',
          'ownerUserId': 'user-a',
          'path': '/sync/goals',
          'payload': {
            'items': [
              {'id': 'pending'},
            ],
          },
        }),
      ]);
      var posts = 0;
      final service = await _service((request) async {
        if (request.method == 'POST') posts++;
        await Future<void>.delayed(Duration.zero);
        return http.Response('{}', 200);
      });
      await Future.wait([service.flushPending(), service.flushPending()]);
      expect(posts, 1);
      expect(await service.pendingCount(), 0);
    },
  );

  test(
    'SYNC-19-14: a refresh finishing after account switch cannot restore the old owner',
    () async {
      final store = InMemoryAuthSessionStore();
      await store.write(jsonEncode(_session('user-a').toJson()));
      late AuthService auth;
      auth = AuthService(
        bypassLogin: false,
        sessionStore: store,
        client: MockClient((request) async {
          await store.write(jsonEncode(_session('user-b').toJson()));
          await auth.restoreSession();
          return http.Response(
            jsonEncode({
              'token': _token('refreshed-a'),
              'refreshToken': 'test-refresh-a',
              'user': {'id': 'user-a', 'name': 'A', 'email': 'a@fitia.test'},
            }),
            200,
          );
        }),
      );
      final service = SyncService.forTesting(
        authService: auth,
        networkService: NetworkService(
          client: MockClient((_) async => http.Response('{}', 401)),
        ),
      );
      expect(
        await service.getAuthenticatedJsonForUser(
          userId: 'user-a',
          path: '/activities/sync',
        ),
        isNull,
      );
      expect((await auth.restoreSession())!.userId, 'user-b');
    },
  );
}

AuthSession _session(String userId) => AuthSession(
  userId: userId,
  name: userId,
  email: '$userId@fitia.test',
  token: _token('valid'),
  refreshToken: 'test-refresh',
);

Future<SyncService> _service(
  Future<http.Response> Function(http.Request) handler, {
  http.Client? refreshClient,
}) async {
  final store = InMemoryAuthSessionStore();
  await store.write(
    jsonEncode(
      AuthSession(
        userId: 'user-a',
        name: 'A',
        email: 'a@fitia.test',
        token: _token('old'),
        refreshToken: 'test-refresh',
      ).toJson(),
    ),
  );
  return SyncService.forTesting(
    networkService: NetworkService(client: MockClient(handler)),
    authService: AuthService(
      bypassLogin: false,
      sessionStore: store,
      client: refreshClient,
    ),
  );
}

String _token(String marker) {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          }),
        ),
      )
      .replaceAll('=', '');
  return '$marker.$payload.signature';
}
