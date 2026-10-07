import 'ai_action_models.dart';

/// Versioned chat; structured actions require a separate confirmation boundary.
abstract final class AiChatContract {
  static const version = 'AiChatContract/v1';
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.actions = const [],
  });
  final String id;
  final String role;
  final String content;
  final List<AiActionProposal> actions;
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    if (actions.isNotEmpty) 'actions': actions.map((a) => a.json).toList(),
  };
  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        !['user', 'assistant'].contains(json['role']) ||
        json['content'] is! String) {
      throw const FormatException('Invalid chat message.');
    }
    return AiChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      actions: _actions(json['actions']),
    );
  }
}

class AiChatFailure implements Exception {
  const AiChatFailure(this.code, this.message, {this.retryable = false});
  final String code;
  final String message;
  final bool retryable;
}

class AiChatReply {
  const AiChatReply({
    required this.conversationId,
    required this.userMessageId,
    required this.messageId,
    required this.content,
    this.actions = const [],
  });
  final String conversationId;
  final String userMessageId;
  final String messageId;
  final String content;
  final List<AiActionProposal> actions;
  factory AiChatReply.fromJson(Map<String, dynamic> json) {
    if (json['contractVersion'] != AiChatContract.version ||
        json['capabilities'] is! List ||
        (json['capabilities'] as List).isNotEmpty ||
        [
          'conversationId',
          'userMessageId',
          'messageId',
          'content',
        ].any((k) => json[k] is! String || (json[k] as String).isEmpty)) {
      throw const FormatException('Invalid read-only chat response.');
    }
    return AiChatReply(
      conversationId: json['conversationId'] as String,
      userMessageId: json['userMessageId'] as String,
      messageId: json['messageId'] as String,
      content: json['content'] as String,
      actions: _actions(json['actions']),
    );
  }
}

List<AiActionProposal> _actions(Object? value) {
  if (value == null) return const [];
  if (value is! List || value.length > 2) {
    throw const FormatException('Invalid actions.');
  }
  return value
      .map(
        (a) => AiActionProposal.fromJson(Map<String, dynamic>.from(a as Map)),
      )
      .toList();
}
