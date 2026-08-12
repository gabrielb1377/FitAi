import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_config.dart';
import '../../../core/auth/local_account_data_boundary.dart';
import '../../../core/config/dev_config.dart';
import 'auth_session_store.dart';

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

/// Respostas essenciais do onboarding curto. Dados clinicos, integracoes e
/// preferencias que nao afetam o primeiro treino ficam fora deste contrato.
class OnboardingDraft {
  const OnboardingDraft({
    this.objective,
    this.experience,
    this.frequency,
    this.location,
    this.equipment = const [],
  });

  final String? objective;
  final String? experience;
  final int? frequency;
  final String? location;
  final List<String> equipment;

  OnboardingDraft copyWith({
    String? objective,
    String? experience,
    int? frequency,
    String? location,
    List<String>? equipment,
  }) => OnboardingDraft(
    objective: objective ?? this.objective,
    experience: experience ?? this.experience,
    frequency: frequency ?? this.frequency,
    location: location ?? this.location,
    equipment: equipment ?? this.equipment,
  );

  Map<String, Object?> toJson() => {
    'objective': objective,
    'experience': experience,
    'frequency': frequency,
    'location': location,
    'equipment': equipment,
  };

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) =>
      OnboardingDraft(
        objective: json['objective'] as String?,
        experience: json['experience'] as String?,
        frequency: json['frequency'] as int?,
        location: json['location'] as String?,
        equipment: (json['equipment'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
      );
}

/// Cliente de autenticacao que preserva sessao local e usa os contratos atuais
/// do backend. Senhas e tokens nunca sao registrados em logs.
class AuthService {
  AuthService({
    http.Client? client,
    bool? bypassLogin,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _bypassLogin =
           DevConfig.enabled && (bypassLogin ?? DevConfig.bypassLogin),
       _sessionStore = sessionStore ?? SecureAuthSessionStore();

  static const _sessionKey = 'fitai.auth.session.v1';
  static const _onboardingKey = 'fitai.auth.onboarding.completed.v1';
  static const _onboardingDraftKey = 'fitai.auth.onboarding.draft.v2';

  final http.Client _client;
  final bool _bypassLogin;
  final AuthSessionStore _sessionStore;

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

  Future<OnboardingDraft> loadOnboardingDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_onboardingDraftKey);
    if (raw == null || raw.isEmpty) return const OnboardingDraft();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return OnboardingDraft.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      _debugLog('Rascunho de onboarding invalido; sera recriado.');
    }
    return const OnboardingDraft();
  }

  Future<void> saveOnboardingDraft(OnboardingDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardingDraftKey, jsonEncode(draft.toJson()));
  }

  Future<void> completeOnboarding([OnboardingDraft? draft]) async {
    final prefs = await SharedPreferences.getInstance();
    if (draft != null) {
      await prefs.setString(_onboardingDraftKey, jsonEncode(draft.toJson()));
    }
    await prefs.setBool(_onboardingKey, true);
  }

  Future<AuthSession?> restoreSession() async {
    try {
      final raw = await _readPersistedSession();
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

      await LocalAccountDataBoundary().activate(
        session.userId,
        claimUnownedData: true,
      );
      AccountSessionLifecycle.setActiveUser(session.userId);

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
    await Future.wait([_sessionStore.delete(), prefs.remove(_sessionKey)]);
    AccountSessionLifecycle.setActiveUser(null);
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
    final boundary = LocalAccountDataBoundary();
    try {
      final prefs = await SharedPreferences.getInstance();
      final previousOwner = await boundary.activeOwner();
      await boundary.activate(session.userId);
      try {
        await _sessionStore.write(jsonEncode(session.toJson()));
      } on Object {
        if (previousOwner != null && previousOwner != session.userId) {
          await boundary.activate(previousOwner);
        }
        rethrow;
      }

      // Estas projeções legadas são reparáveis e não podem invalidar uma
      // sessão segura que já foi gravada junto ao limite de dados correto.
      try {
        await prefs.remove(_sessionKey);
        // Mantém o nome exibido nas telas existentes sem modificar o perfil local.
        await prefs.setString('perfilNome', session.name);
      } on Object catch (error) {
        _debugLog('Falha na projeção local da sessão: $error');
      }

      AccountSessionLifecycle.setActiveUser(session.userId);
    } on Object catch (error) {
      _debugLog('Falha ao salvar sessao: $error');
      throw const AuthException(
        'Nao foi possivel salvar sua sessao neste dispositivo.',
        AuthFailureKind.local,
      );
    }
  }

  Future<String?> _readPersistedSession() async {
    final secureValue = await _sessionStore.read();
    if (secureValue != null && secureValue.isNotEmpty) return secureValue;

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(_sessionKey);
    if (legacyValue == null || legacyValue.isEmpty) return null;

    await _sessionStore.write(legacyValue);
    await prefs.remove(_sessionKey);
    _debugLog('Sessao legada migrada para armazenamento seguro.');
    return legacyValue;
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
