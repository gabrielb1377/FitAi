import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/ai_chat_models.dart';
import 'ai_chat_gateway.dart';

/// Bounded active transcript/draft cache; the backend owns completed conversations.
class AiChatRepository {
  AiChatRepository({
    required this.gateway,
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;
  final AiChatGateway gateway;
  final Future<SharedPreferences> Function() _preferences;
  String _key(String owner) =>
      'fitia.aiChat.v1.user.${Uri.encodeComponent(owner)}';
  Future<Map<String, dynamic>> load(String owner) async {
    final raw = (await _preferences()).getString(_key(owner));
    if (raw == null) return {};
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic> && parsed['owner'] == owner) {
        return parsed;
      }
    } on FormatException {
      /* Preserve corrupt cache instead of exposing it. */
    }
    return {};
  }

  Future<void> save(
    String owner, {
    String? conversationId,
    required List<AiChatMessage> messages,
    Map<String, dynamic>? pending,
  }) async {
    final stored = await (await _preferences()).setString(
      _key(owner),
      jsonEncode({
        'owner': owner,
        'conversationId': conversationId,
        'messages': messages
            .skip(messages.length > 40 ? messages.length - 40 : 0)
            .map((m) => m.toJson())
            .toList(),
        'pending': pending,
      }),
    );
    if (!stored) {
      throw const AiChatFailure(
        'local_storage',
        'Nao foi possivel preservar a mensagem neste dispositivo.',
        retryable: true,
      );
    }
  }
}
