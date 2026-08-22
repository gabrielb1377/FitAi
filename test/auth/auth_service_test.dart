import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/core/config/dev_config.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.configure(baseUrl: 'https://api.fitia.test');
  });

  test('primeira abertura sem sessao inicia o onboarding', () async {
    final service = AuthService(
      client: MockClient((_) async => _ok()),
      bypassLogin: false,
      sessionStore: InMemoryAuthSessionStore(),
    );

    expect(
      await service.resolveLaunchDestination(),
      AuthLaunchDestination.onboarding,
    );

    await service.completeOnboarding();
    expect(
      await service.resolveLaunchDestination(),
      AuthLaunchDestination.login,
    );
  });

  test('login usa contrato do backend e restaura sessao local', () async {
    late http.Request captured;
    final sessionStore = InMemoryAuthSessionStore();
    final service = AuthService(
      client: MockClient((request) async {
        captured = request;
        return _ok();
      }),
      bypassLogin: false,
      sessionStore: sessionStore,
    );

    final session = await service.login(
      email: 'gabriel@fitia.app',
      password: '123456',
    );

    expect(captured.url.path, '/auth/login');
    expect(jsonDecode(captured.body), {
      'email': 'gabriel@fitia.app',
      'password': '123456',
    });
    expect(session.name, 'Gabriel');
    expect((await service.restoreSession())?.email, 'gabriel@fitia.app');
    expect(await sessionStore.read(), isNotEmpty);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        'fitai.auth.session.v1',
      ),
      isFalse,
    );
    expect(
      await service.resolveLaunchDestination(),
      AuthLaunchDestination.appShell,
    );
  });

  test(
    'troca de conta nao expoe os dados locais legados da sessao anterior',
    () async {
      final first = AuthService(
        client: MockClient((_) async => _ok(userId: 'user-a', name: 'Ana')),
        bypassLogin: false,
        sessionStore: InMemoryAuthSessionStore(),
      );
      final second = AuthService(
        client: MockClient((_) async => _ok(userId: 'user-b', name: 'Bruno')),
        bypassLogin: false,
        sessionStore: InMemoryAuthSessionStore(),
      );

      await first.login(email: 'ana@fitia.app', password: '123456');
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList('historicoTreinos', ['treino-da-ana']);
      await first.clearSession();

      await second.login(email: 'bruno@fitia.app', password: '123456');
      expect(preferences.getStringList('historicoTreinos'), isNull);

      await second.clearSession();
      await first.login(email: 'ana@fitia.app', password: '123456');
      expect(preferences.getStringList('historicoTreinos'), ['treino-da-ana']);
    },
  );

  test(
    'falha ao salvar nova sessao restaura os dados da conta anterior',
    () async {
      final first = AuthService(
        client: MockClient((_) async => _ok(userId: 'user-a', name: 'Ana')),
        bypassLogin: false,
        sessionStore: InMemoryAuthSessionStore(),
      );
      final failing = AuthService(
        client: MockClient((_) async => _ok(userId: 'user-b', name: 'Bruno')),
        bypassLogin: false,
        sessionStore: _FailingAuthSessionStore(),
      );

      await first.login(email: 'ana@fitia.app', password: '123456');
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList('historicoTreinos', ['treino-da-ana']);
      await first.clearSession();

      await expectLater(
        failing.login(email: 'bruno@fitia.app', password: '123456'),
        throwsA(isA<AuthException>()),
      );

      expect(preferences.getStringList('historicoTreinos'), ['treino-da-ana']);
    },
  );

  test('cadastro envia somente o contrato aceito pelo backend', () async {
    late http.Request captured;
    final service = AuthService(
      client: MockClient((request) async {
        captured = request;
        return _ok(statusCode: 201);
      }),
      sessionStore: InMemoryAuthSessionStore(),
    );

    await service.register(
      name: 'Gabriel',
      email: 'gabriel@fitia.app',
      password: '123456',
    );

    expect(captured.url.path, '/auth/register');
    expect(jsonDecode(captured.body), {
      'name': 'Gabriel',
      'email': 'gabriel@fitia.app',
      'password': '123456',
    });
  });

  test('credenciais invalidas recebem mensagem segura', () async {
    final service = AuthService(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'invalid_credentials'}), 401),
      ),
      sessionStore: InMemoryAuthSessionStore(),
    );

    await expectLater(
      service.login(email: 'gabriel@fitia.app', password: 'invalida'),
      throwsA(
        isA<AuthException>()
            .having(
              (error) => error.kind,
              'kind',
              AuthFailureKind.invalidCredentials,
            )
            .having(
              (error) => error.message,
              'message',
              'E-mail ou senha incorretos.',
            ),
      ),
    );
  });

  test('sessao expirada e descartada antes de abrir o aplicativo', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fitai.auth.session.v1',
      jsonEncode({
        'userId': 'user-1',
        'name': 'Gabriel',
        'email': 'gabriel@fitia.app',
        'token': _token(expiry: DateTime(2020)),
      }),
    );
    final service = AuthService(
      client: MockClient((_) async => _ok()),
      bypassLogin: false,
      sessionStore: InMemoryAuthSessionStore(),
    );

    expect(await service.restoreSession(), isNull);
    expect(
      await service.resolveLaunchDestination(),
      AuthLaunchDestination.onboarding,
    );
  });

  test(
    'refresh renova sessao expirada uma unica vez para chamadas concorrentes',
    () async {
      final store = InMemoryAuthSessionStore();
      var refreshCalls = 0;
      await store.write(
        jsonEncode(
          AuthSession(
            userId: 'user-1',
            name: 'Gabriel',
            email: 'gabriel@fitia.app',
            token: _token(expiry: DateTime(2020)),
            refreshToken: 'refresh-1',
          ).toJson(),
        ),
      );
      final service = AuthService(
        client: MockClient((request) async {
          if (request.url.path == '/auth/refresh') {
            refreshCalls += 1;
            return _ok(refreshToken: 'refresh-2');
          }
          return _ok();
        }),
        bypassLogin: false,
        sessionStore: store,
      );

      final sessions = await Future.wait([
        service.restoreSession(),
        service.restoreSession(),
      ]);

      expect(refreshCalls, 1);
      expect(
        sessions.every((session) => session?.refreshToken == 'refresh-2'),
        isTrue,
      );
    },
  );

  test('refresh revogado encerra somente a sessao local', () async {
    final store = InMemoryAuthSessionStore();
    await store.write(
      jsonEncode(
        AuthSession(
          userId: 'user-1',
          name: 'Gabriel',
          email: 'gabriel@fitia.app',
          token: _token(expiry: DateTime(2020)),
          refreshToken: 'revogado',
        ).toJson(),
      ),
    );
    final service = AuthService(
      client: MockClient((_) async => http.Response('{}', 401)),
      bypassLogin: false,
      sessionStore: store,
    );

    expect(await service.restoreSession(), isNull);
    expect(await store.read(), isNull);
  });

  test('logout remoto limpa a sessao mesmo quando a rede falha', () async {
    final store = InMemoryAuthSessionStore();
    await store.write(
      jsonEncode(
        AuthSession(
          userId: 'user-1',
          name: 'Gabriel',
          email: 'gabriel@fitia.app',
          token: _token(),
          refreshToken: 'refresh-1',
        ).toJson(),
      ),
    );
    final service = AuthService(
      client: MockClient((request) async {
        expect(request.url.path, '/auth/logout');
        return http.Response('', 204);
      }),
      bypassLogin: false,
      sessionStore: store,
    );

    await service.logout();
    expect(await store.read(), isNull);
  });

  test('debug pode pular login sem persistir sessao falsa', () async {
    final service = AuthService(
      client: MockClient((_) async => _ok()),
      sessionStore: InMemoryAuthSessionStore(),
    );

    expect(DevConfig.enabled, isTrue);
    expect(
      await service.resolveLaunchDestination(),
      AuthLaunchDestination.appShell,
    );
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        'fitai.auth.session.v1',
      ),
      isFalse,
    );
  });
}

http.Response _ok({
  int statusCode = 200,
  String userId = 'user-1',
  String name = 'Gabriel',
  String? refreshToken,
}) => http.Response(
  jsonEncode({
    'token': _token(),
    'refreshToken': ?refreshToken,
    'user': {'id': userId, 'name': name, 'email': 'gabriel@fitia.app'},
  }),
  statusCode,
);

String _token({DateTime? expiry}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiresAt = expiry ?? DateTime.now().add(const Duration(days: 7));
  return '${encode({'alg': 'none'})}.${encode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000})}.signature';
}

class _FailingAuthSessionStore implements AuthSessionStore {
  @override
  Future<void> delete() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) => Future<void>.error(StateError('disk'));
}
