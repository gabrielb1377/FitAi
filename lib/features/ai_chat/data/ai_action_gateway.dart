import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../../auth/data/auth_service.dart';
import '../domain/ai_action_models.dart';
import '../domain/ai_chat_models.dart';

abstract interface class AiActionGateway {
  Future<AiActionProposal> confirm(
    String owner,
    String actionId,
    String deviceId,
  );
  Future<AiActionProposal> cancel(String owner, String actionId);
  Future<AiActionProposal> complete(String owner, String actionId);
}

/// Uses JWT and persisted action identity; no payload is accepted at confirmation.
class HttpAiActionGateway implements AiActionGateway {
  HttpAiActionGateway({http.Client? client, AuthService? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthService();
  final http.Client _client;
  final AuthService _auth;
  @override
  Future<AiActionProposal> confirm(
    String owner,
    String actionId,
    String deviceId,
  ) => _post(owner, actionId, 'confirm', {
    'confirmed': true,
    'deviceId': deviceId,
  });
  @override
  Future<AiActionProposal> cancel(String owner, String actionId) =>
      _post(owner, actionId, 'cancel', {});
  @override
  Future<AiActionProposal> complete(String owner, String actionId) =>
      _post(owner, actionId, 'complete', {});

  Future<AiActionProposal> _post(
    String owner,
    String id,
    String operation,
    Map<String, dynamic> extra,
  ) async {
    try {
      if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(id)) {
        throw const FormatException();
      }
      var session = await _auth.restoreSession();
      if (session?.userId != owner) {
        throw const AiChatFailure(
          'unauthorized',
          'Entre na sua conta novamente.',
        );
      }
      Future<http.Response> send() => _client
          .post(
            ApiConfig.endpoint('/ai/actions/$id/$operation'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session!.token}',
            },
            body: jsonEncode({
              'contractVersion': AiActionProposal.version,
              ...extra,
            }),
          )
          .timeout(const Duration(seconds: 30));
      var response = await send();
      if (response.statusCode == 401) {
        session = await _auth.refreshSession(session: session);
        if (session?.userId != owner) {
          throw const AiChatFailure(
            'unauthorized',
            'Entre na sua conta novamente.',
          );
        }
        response = await send();
      }
      if ((await _auth.restoreSession())?.userId != owner) {
        throw const AiChatFailure(
          'unauthorized',
          'A conta mudou. Abra o Coach novamente.',
        );
      }
      if (response.statusCode != 200) {
        final decoded = jsonDecode(response.body);
        final code = decoded is Map
            ? decoded['code'] ?? decoded['error']
            : null;
        if (code == 'ai_action_device_conflict') {
          throw const AiChatFailure(
            'device_conflict',
            'Esta sugestao esta sendo executada em outro dispositivo.',
          );
        }
        if (response.statusCode == 409 || response.statusCode == 404) {
          throw const AiChatFailure(
            'stale_action',
            'A sugestao nao esta mais disponivel. Solicite outra ao Coach.',
          );
        }
        throw const AiChatFailure(
          'action_unavailable',
          'Nao foi possivel confirmar a sugestao agora.',
          retryable: true,
        );
      }
      final action = AiActionProposal.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
      if (action.id != id) throw const FormatException();
      return action;
    } on AiChatFailure {
      rethrow;
    } on FormatException {
      throw const AiChatFailure(
        'invalid_action',
        'Nao foi possivel validar esta sugestao.',
      );
    } on Object {
      throw const AiChatFailure(
        'offline',
        'Sem conexao para confirmar. A sugestao continua aqui.',
        retryable: true,
      );
    }
  }

  void dispose() => _client.close();
}
