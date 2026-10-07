import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_config.dart';
import '../../auth/data/auth_service.dart';
import '../domain/ai_chat_models.dart';

abstract interface class AiChatGateway {
  Future<AiChatReply> send({
    required String userId,
    required Map<String, dynamic> input,
  });
}

/// JWT-only API transport, with the existing refresh boundary and owner checks.
class HttpAiChatGateway implements AiChatGateway {
  HttpAiChatGateway({http.Client? client, AuthService? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthService();
  final http.Client _client;
  final AuthService _auth;

  @override
  Future<AiChatReply> send({
    required String userId,
    required Map<String, dynamic> input,
  }) async {
    try {
      var session = await _auth.restoreSession();
      if (session == null || session.userId != userId) throw _unauthorized;
      Future<http.Response> post() => _client
          .post(
            ApiConfig.endpoint('/ai/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session!.token}',
            },
            body: jsonEncode(input),
          )
          .timeout(const Duration(seconds: 30));
      var response = await post();
      if (response.statusCode == 401) {
        session = await _auth.refreshSession(session: session);
        if (session == null || session.userId != userId) throw _unauthorized;
        response = await post();
      }
      final current = await _auth.restoreSession();
      if (current?.userId != userId) throw _unauthorized;
      if (response.statusCode != 200) throw _failure(response);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      if (decoded['clientRequestId'] != input['clientRequestId']) {
        throw const FormatException();
      }
      return AiChatReply.fromJson(decoded);
    } on AiChatFailure {
      rethrow;
    } on ApiConfigurationException {
      throw const AiChatFailure(
        'ai_not_configured',
        'A conversa ainda nao esta disponivel neste ambiente.',
      );
    } on TimeoutException {
      throw const AiChatFailure(
        'timeout',
        'A resposta demorou. Tente novamente.',
        retryable: true,
      );
    } on FormatException {
      throw const AiChatFailure(
        'invalid_response',
        'Nao foi possivel ler a resposta do Coach.',
      );
    } on Object {
      throw const AiChatFailure(
        'offline',
        'Sem conexao com o Coach. Suas mensagens continuam aqui.',
        retryable: true,
      );
    }
  }

  static const _unauthorized = AiChatFailure(
    'unauthorized',
    'Entre na sua conta para conversar com o Coach.',
  );
  AiChatFailure _failure(http.Response response) {
    Map<String, dynamic> body = {};
    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) body = value;
    } on FormatException {
      /* Safe fallback below. */
    }
    final code = body['code'] ?? body['error'];
    if (response.statusCode == 401) return _unauthorized;
    if (code == 'ai_quota_exceeded') {
      return const AiChatFailure(
        'quota',
        'Seu limite diario de conversas foi atingido. Tente em outro dia.',
      );
    }
    if (code == 'conversation_not_found') {
      return const AiChatFailure(
        'conversation_not_found',
        'Esta conversa nao esta disponivel. Inicie uma nova conversa.',
      );
    }
    if (code == 'ai_not_configured' || code == 'ai_provider_auth_error') {
      return const AiChatFailure(
        'ai_not_configured',
        'A conversa ainda nao esta disponivel neste ambiente.',
      );
    }
    if (code == 'ai_request_in_progress') {
      return const AiChatFailure(
        'in_progress',
        'Sua mensagem ainda esta sendo processada. Tente novamente em instantes.',
        retryable: true,
      );
    }
    return AiChatFailure(
      'unavailable',
      'O Coach nao respondeu agora. Tente mais tarde.',
      retryable:
          response.statusCode == 503 ||
          response.statusCode == 504 ||
          response.statusCode == 429,
    );
  }

  void dispose() => _client.close();
}
