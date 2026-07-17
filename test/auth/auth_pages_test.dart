import 'dart:convert';

import 'package:fitai/features/auth/data/auth_service.dart';
import 'package:fitai/features/auth/presentation/pages/auth_splash_page.dart';
import 'package:fitai/features/auth/presentation/pages/initial_permissions_page.dart';
import 'package:fitai/features/auth/presentation/pages/login_page.dart';
import 'package:fitai/features/auth/presentation/pages/onboarding_page.dart';
import 'package:fitai/features/auth/presentation/pages/password_recovery_page.dart';
import 'package:fitai/features/auth/presentation/pages/register_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('splash encaminha para login conforme o estado resolvido', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AuthSplashPage(
          resolveDestination: () async => AuthLaunchDestination.login,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('onboarding persiste conclusao e segue para login', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const OnboardingPage()));

    expect(find.text('Seu treino, do seu jeito.'), findsOneWidget);
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'fitai.auth.onboarding.completed.v1',
      ),
      isTrue,
    );
  });

  testWidgets('login valida campos antes de chamar a API', (tester) async {
    await tester.pumpWidget(_host(const LoginPage()));

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail valido.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('login bem-sucedido abre a etapa de permissoes', (tester) async {
    final service = AuthService(
      client: MockClient((_) async => _authResponse()),
    );
    await tester.pumpWidget(_host(LoginPage(authService: service)));

    await tester.enterText(find.byType(TextField).at(0), 'gabriel@fitia.app');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(InitialPermissionsPage), findsOneWidget);
  });

  testWidgets('cadastro bloqueia senhas divergentes localmente', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const RegisterPage()));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Gabriel');
    await tester.enterText(fields.at(1), 'gabriel@fitia.app');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '654321');
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta'));
    await tester.pump();

    expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
  });

  testWidgets('recuperacao informa indisponibilidade sem simular envio', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const PasswordRecoveryPage()));

    await tester.enterText(find.byType(TextField), 'gabriel@fitia.app');
    await tester.tap(find.text('Enviar link'));
    await tester.pump();

    expect(
      find.text(
        'A recuperacao de senha ainda nao esta disponivel neste ambiente.',
      ),
      findsOneWidget,
    );
  });
}

Widget _host(Widget page) => MaterialApp(theme: AppTheme.dark, home: page);

http.Response _authResponse() => http.Response(
  jsonEncode({
    'token': _token(),
    'user': {'id': 'user-1', 'name': 'Gabriel', 'email': 'gabriel@fitia.app'},
  }),
  200,
);

String _token() {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry = DateTime.now().add(const Duration(days: 7));
  return '${encode({'alg': 'none'})}.${encode({'exp': expiry.millisecondsSinceEpoch ~/ 1000})}.signature';
}
