import 'dart:async';
import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/services/network_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.configure(baseUrl: 'https://sync.fitia.test');
  });

  tearDown(ApiConfig.reset);

  test('Sync envia o JWT da sessao e mantem clientId como metadado', () async {
    final store = InMemoryAuthSessionStore();
    final token = _validToken();
    await store.write(
      jsonEncode(
        AuthSession(
          userId: 'user-a',
          name: 'Conta A',
          email: 'a@fitia.test',
          token: token,
        ).toJson(),
      ),
    );
    final client = _CapturingClient();
    final service = SyncService.forTesting(
      networkService: NetworkService(client: client),
      authService: AuthService(sessionStore: store),
    );

    await service.syncGoals([
      {'id': 'goal-a', 'title': 'Meta A', 'userId': 'user-b'},
    ]);

    expect(client.requests, hasLength(1));
    expect(
      _header(client.requests.single.headers, 'authorization'),
      'Bearer $token',
    );
    expect(
      _header(client.requests.single.headers, 'x-fitia-client-id'),
      isNotEmpty,
    );
    final payload =
        jsonDecode(client.requests.single.body) as Map<String, dynamic>;
    expect(payload['clientId'], isNotEmpty);
  });

  test(
    'fila legada de A permanece pendente quando B entra na mesma instalacao',
    () async {
      final storeA = InMemoryAuthSessionStore();
      await storeA.write(
        jsonEncode(
          AuthSession(
            userId: 'user-a',
            name: 'Conta A',
            email: 'a@fitia.test',
            token: _validToken(),
          ).toJson(),
        ),
      );
      final offline = SyncService.forTesting(
        networkService: NetworkService(client: _OfflineClient()),
        authService: AuthService(bypassLogin: false, sessionStore: storeA),
      );
      await offline.syncGoals([
        {'id': 'goal-a', 'title': 'Meta da conta A'},
      ]);
      expect(await offline.pendingCount(), 1);

      final storeB = InMemoryAuthSessionStore();
      await storeB.write(
        jsonEncode(
          AuthSession(
            userId: 'user-b',
            name: 'Conta B',
            email: 'b@fitia.test',
            token: _validToken(),
          ).toJson(),
        ),
      );
      final onlineClient = _HealthAndCaptureClient();
      final accountB = SyncService.forTesting(
        networkService: NetworkService(client: onlineClient),
        authService: AuthService(bypassLogin: false, sessionStore: storeB),
      );

      await accountB.flushPending();

      expect(await accountB.pendingCount(), 1);
      expect(onlineClient.postRequests, isEmpty);
    },
  );

  test('fila antiga de corrida/passos nao regrava o estado v2', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fitaiSyncQueue', [
      jsonEncode({
        'id': 'user-a_running_old',
        'type': 'running',
        'path': '/sync/running',
        'ownerUserId': 'user-a',
        'payload': {
          'clientId': 'device-a',
          'items': [
            {'id': 'run-acked'},
            {'id': 'run-unknown'},
          ],
        },
      }),
      jsonEncode({
        'id': 'user-a_steps_old',
        'type': 'steps',
        'path': '/steps/sync',
        'ownerUserId': 'user-a',
        'payload': {
          'clientId': 'device-a',
          'items': [
            {'date': '2026-10-05', 'steps': 6200},
          ],
        },
      }),
    ]);
    final store = InMemoryAuthSessionStore();
    await store.write(
      jsonEncode(
        AuthSession(
          userId: 'user-a',
          name: 'Conta A',
          email: 'a@fitia.test',
          token: _validToken(),
        ).toJson(),
      ),
    );
    final client = _HealthAndCaptureClient();
    final service = SyncService.forTesting(
      networkService: NetworkService(client: client),
      authService: AuthService(sessionStore: store),
    );

    await service.flushPending();
    expect(client.postRequests, isEmpty);
    expect(await service.pendingCount(), 2);

    final pruned = await service.acknowledgeLegacyActivityQueue(
      userId: 'user-a',
      runningIds: {'run-acked'},
      stepDayKeys: {'2026-10-05'},
    );
    expect(pruned, 2);
    final remaining = prefs.getStringList('fitaiSyncQueue') ?? const [];
    expect(remaining, hasLength(1));
    final remainingPayload =
        jsonDecode(remaining.single) as Map<String, dynamic>;
    expect(
      ((remainingPayload['payload'] as Map)['items'] as List).single['id'],
      'run-unknown',
    );
  });
}

String _validToken() {
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
  return 'header.$payload.signature';
}

String? _header(Map<String, String> headers, String name) {
  final normalizedName = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == normalizedName) return entry.value;
  }
  return null;
}

class _CapturedRequest {
  const _CapturedRequest(this.headers, this.body);

  final Map<String, String> headers;
  final String body;
}

class _CapturingClient extends http.BaseClient {
  final List<_CapturedRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    requests.add(
      _CapturedRequest(Map<String, String>.from(request.headers), body),
    );
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('offline');
  }
}

class _HealthAndCaptureClient extends http.BaseClient {
  final List<http.Request> postRequests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'POST' && request is http.Request) {
      postRequests.add(request);
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
