import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/data/auth_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = String.fromEnvironment('R1_5_BASE_URL');
const _runId = String.fromEnvironment('R1_5_RUN_ID');

void main() {
  test(
    'R1.5: Flutter recupera sessao com refresh e isola nova conta',
    () async {
      expect(_baseUrl, isNotEmpty);
      expect(_runId, isNotEmpty);
      SharedPreferences.setMockInitialValues({});
      ApiConfig.configure(baseUrl: _baseUrl);

      final storeA = InMemoryAuthSessionStore();
      final authA = AuthService(bypassLogin: false, sessionStore: storeA);
      final sessionA = await authA.register(
        name: 'R1.5 User A',
        email: 'r15-flutter-a-$_runId@fitia.test',
        password: 'r1-5-flutter-password',
      );
      expect(sessionA.refreshToken, isNotEmpty);
      await storeA.write(
        jsonEncode(
          AuthSession(
            userId: sessionA.userId,
            name: sessionA.name,
            email: sessionA.email,
            token: _expiredToken(),
            refreshToken: sessionA.refreshToken,
          ).toJson(),
        ),
      );
      final restored = await authA.restoreSession();
      expect(restored, isNotNull);
      expect(restored!.token, isNot(_expiredToken()));
      expect(restored.refreshToken, isNot(sessionA.refreshToken));

      final me = await http.get(
        ApiConfig.endpoint('/auth/me'),
        headers: {'Authorization': 'Bearer ${restored.token}'},
      );
      expect(me.statusCode, 200);
      await authA.logout();
      expect(await storeA.read(), isNull);
      final revoked = await http.post(
        ApiConfig.endpoint('/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': restored.refreshToken}),
      );
      expect(revoked.statusCode, 401);

      final storeB = InMemoryAuthSessionStore();
      final authB = AuthService(bypassLogin: false, sessionStore: storeB);
      final sessionB = await authB.register(
        name: 'R1.5 User B',
        email: 'r15-flutter-b-$_runId@fitia.test',
        password: 'r1-5-flutter-password',
      );
      expect((await authB.restoreSession())?.userId, sessionB.userId);
      expect(sessionB.userId, isNot(sessionA.userId));
    },
    skip: _baseUrl.isEmpty || _runId.isEmpty
        ? 'Executado pelo runner R1.5 contra API e PostgreSQL efemeros.'
        : false,
  );
}

String _expiredToken() {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'none'})}.${encode({'exp': 1})}.signature';
}
