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
