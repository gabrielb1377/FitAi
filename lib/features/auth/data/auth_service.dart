import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_config.dart';
import '../../../core/config/dev_config.dart';

enum AuthLaunchDestination { onboarding, login, appShell }

enum AuthFailureKind {
  offline,
  invalidCredentials,
  emailAlreadyRegistered,
  invalidRequest,
  server,
  local,
}

class AuthException implements Exception {
  const AuthException(this.message, this.kind);

  final String message;
  final AuthFailureKind kind;

  @override
  String toString() => 'AuthException: $message';
}

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.token,
  });

  final String userId;
  final String name;
  final String email;
  final String token;

  Map<String, String> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'token': token,
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = _text(json['token']);
    final userId = _text(json['userId']);
    final name = _text(json['name']);
    final email = _text(json['email']);

    if (token.isEmpty || userId.isEmpty || name.isEmpty || email.isEmpty) {
      throw const AuthException(
        'Sessao local invalida.',
        AuthFailureKind.local,
      );
    }

    return AuthSession(userId: userId, name: name, email: email, token: token);
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}

/// Cliente de autenticacao que preserva sessao local e usa os contratos atuais
/// do backend. Senhas e tokens nunca sao registrados em logs.
class AuthService {
  AuthService({http.Client? client, bool? bypassLogin})
    : _client = client ?? http.Client(),
      _bypassLogin =
          DevConfig.enabled && (bypassLogin ?? DevConfig.bypassLogin);

  static const _sessionKey = 'fitai.auth.session.v1';
  static const _onboardingKey = 'fitai.auth.onboarding.completed.v1';

  final http.Client _client;
  final bool _bypassLogin;

  Future<AuthLaunchDestination> resolveLaunchDestination() async {
    if (_bypassLogin) return AuthLaunchDestination.appShell;

    final session = await restoreSession();
    if (session != null) return AuthLaunchDestination.appShell;

    return await hasCompletedOnboarding()
        ? AuthLaunchDestination.login
        : AuthLaunchDestination.onboarding;
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<AuthSession?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await clearSession();
        return null;
      }

      final session = AuthSession.fromJson(Map<String, dynamic>.from(decoded));
      if (_isTokenExpired(session.token)) {
        await clearSession();
        return null;
      }

      return session;
    } on AuthException {
      return null;
    } on Object catch (error) {
      _debugLog('Nao foi possivel restaurar a sessao local: $error');
      return null;
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _authenticate('/auth/login', {
    'email': email.trim(),
    'password': password,
  });

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('/auth/register', {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
  });

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<AuthSession> _authenticate(
    String path,
    Map<String, String> payload,
  ) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint(path),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.timeout);

      final body = _decodeObject(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapResponseError(response.statusCode, body);
      }

      final session = _sessionFromResponse(body);
      await _persistSession(session);
      return session;
    } on TimeoutException {
      throw const AuthException(
        'O servidor demorou para responder. Tente novamente.',
        AuthFailureKind.offline,
      );
    } on AuthException {
      rethrow;
    } on http.ClientException {
      throw const AuthException(
        'Sem conexao com o servidor FitIA.',
        AuthFailureKind.offline,
      );
    } on Object catch (error) {
      _debugLog('Falha de autenticacao: $error');
      throw const AuthException(
        'Nao foi possivel concluir esta acao agora.',
        AuthFailureKind.server,
      );
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(session.toJson()));

      // Mantem o nome exibido nas telas existentes sem modificar o perfil local.
      await prefs.setString('perfilNome', session.name);
    } on Object catch (error) {
      _debugLog('Falha ao salvar sessao: $error');
      throw const AuthException(
        'Nao foi possivel salvar sua sessao neste dispositivo.',
        AuthFailureKind.local,
      );
    }
  }

  AuthSession _sessionFromResponse(Map<String, dynamic> response) {
    final user = response['user'];
    final token = _text(response['token']);
    if (user is! Map || token.isEmpty) {
      throw const AuthException(
        'Resposta de autenticacao invalida.',
        AuthFailureKind.server,
      );
    }

    return AuthSession.fromJson({
      'userId': user['id'],
      'name': user['name'],
      'email': user['email'],
      'token': token,
    });
  }

  AuthException _mapResponseError(int statusCode, Map<String, dynamic> body) {
    final code = _text(body['error']);
    final message = _text(body['message']);

    if (statusCode == 401 || code == 'invalid_credentials') {
      return const AuthException(
        'E-mail ou senha incorretos.',
        AuthFailureKind.invalidCredentials,
      );
    }
    if (statusCode == 409 || code == 'email_already_registered') {
      return const AuthException(
        'Este e-mail ja esta cadastrado.',
        AuthFailureKind.emailAlreadyRegistered,
      );
    }
    if (statusCode == 400) {
      return AuthException(
        message.isEmpty ? 'Revise os dados informados.' : message,
        AuthFailureKind.invalidRequest,
      );
    }
    if (statusCode >= 500) {
      return const AuthException(
        'O servidor esta indisponivel no momento. Tente novamente.',
        AuthFailureKind.server,
      );
    }

    return AuthException(
      message.isEmpty ? 'Nao foi possivel concluir esta acao.' : message,
      AuthFailureKind.server,
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) return const {};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // A mensagem padrao abaixo evita expor a resposta bruta do servidor.
    }

    return const {};
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map || decoded['exp'] is! num) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        (decoded['exp'] as num).toInt() * 1000,
      );
      return !expiry.isAfter(DateTime.now());
    } on Object {
      return true;
    }
  }

  String _text(Object? value) => value?.toString().trim() ?? '';

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[AuthService] $message');
  }
}
