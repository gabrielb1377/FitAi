import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/auth/local_account_data_boundary.dart';
import '../../auth/data/auth_service.dart';
import '../data/ai_chat_repository.dart';
import '../domain/ai_chat_models.dart';

/// Owns one active conversation; retries reuse the same persisted logical request.
class AiChatController extends ChangeNotifier {
  AiChatController({
    required this.repository,
    Future<AuthSession?> Function()? session,
  }) : _session = session ?? AuthService().restoreSession {
    AccountSessionLifecycle.revision.addListener(_accountChanged);
  }
  final AiChatRepository repository;
  final Future<AuthSession?> Function() _session;
  final List<AiChatMessage> _messages = [];
  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  String? _owner, _conversationId;
  Map<String, dynamic>? _pending;
  Map<String, dynamic>? get pending =>
      _pending == null ? null : Map.unmodifiable(_pending!);
  AiChatFailure? error;
  bool loading = false, ready = false, _disposed = false;
  int _epoch = 0;

  Future<void> initialize() async {
    var epoch = _epoch;
    try {
      final session = await _session();
      if (_disposed) return;
      epoch = _epoch;
      if (session == null) {
        throw const AiChatFailure(
          'unauthorized',
          'Entre na sua conta para conversar com o Coach.',
        );
      }
      if (AccountSessionLifecycle.activeUserId != session.userId) {
        throw const AiChatFailure(
          'unauthorized',
          'A conta mudou. Abra o Coach novamente.',
        );
      }
      _owner = session.userId;
      final cache = await repository.load(_owner!);
      if (!_valid(epoch)) return;
      _conversationId = cache['conversationId'] as String?;
      _messages.clear();
      for (final m in (cache['messages'] as List? ?? [])) {
        _messages.add(
          AiChatMessage.fromJson(Map<String, dynamic>.from(m as Map)),
        );
      }
      _pending = cache['pending'] == null
          ? null
          : Map<String, dynamic>.from(cache['pending'] as Map);
      error = null;
      if (_pending != null) {
        error = const AiChatFailure(
          'pending',
          'Sua ultima mensagem pode ser reenviada.',
          retryable: true,
        );
      }
      ready = true;
    } on AiChatFailure catch (failure) {
      if (_valid(epoch)) error = failure;
    } on Object {
      if (_valid(epoch)) {
        error = const AiChatFailure(
          'cache',
          'Nao foi possivel abrir a conversa salva.',
        );
      }
    }
    _notify();
  }

  Future<void> send(String message) async {
    final text = message.trim();
    if (!ready ||
        loading ||
        _pending != null ||
        text.isEmpty ||
        text.length > 2000) {
      return;
    }
    _pending = {
      'contractVersion': AiChatContract.version,
      'message': text,
      'clientRequestId':
          'chat-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
      if (_conversationId != null) 'conversationId': _conversationId,
    };
    await retry();
  }

  Future<void> retry() async {
    if (!ready || loading || _pending == null || _owner == null) return;
    final epoch = _epoch,
        owner = _owner!,
        request = Map<String, dynamic>.from(_pending!);
    loading = true;
    error = null;
    _notify();
    try {
      await repository.save(
        owner,
        conversationId: _conversationId,
        messages: _messages,
        pending: request,
      );
      if (!_valid(epoch)) return;
      final reply = await repository.gateway.send(
        userId: owner,
        input: request,
      );
      if (!_valid(epoch)) return;
      _conversationId = reply.conversationId;
      if (!_messages.any((m) => m.id == reply.messageId)) {
        _messages.addAll([
          AiChatMessage(
            id: reply.userMessageId,
            role: 'user',
            content: request['message'] as String,
          ),
          AiChatMessage(
            id: reply.messageId,
            role: 'assistant',
            content: reply.content,
          ),
        ]);
        if (_messages.length > 40) {
          _messages.removeRange(0, _messages.length - 40);
        }
      }
      await repository.save(
        owner,
        conversationId: _conversationId,
        messages: _messages,
      );
      if (_valid(epoch)) _pending = null;
    } on AiChatFailure catch (failure) {
      if (_valid(epoch)) error = failure;
    } on Object {
      if (_valid(epoch)) {
        error = const AiChatFailure(
          'unavailable',
          'Nao foi possivel preservar a resposta. Tente novamente.',
          retryable: true,
        );
      }
    } finally {
      if (_valid(epoch)) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> newConversation() async {
    if (loading || _owner == null) return;
    final epoch = _epoch, owner = _owner!;
    try {
      await repository.save(owner, messages: const []);
      if (!_valid(epoch)) return;
      _epoch++;
      _messages.clear();
      _pending = null;
      _conversationId = null;
      error = null;
      _notify();
    } on AiChatFailure catch (failure) {
      if (_valid(epoch)) {
        error = failure;
        _notify();
      }
    }
  }

  void _accountChanged() {
    if (_owner == null || AccountSessionLifecycle.activeUserId != _owner) {
      _epoch++;
      _owner = null;
      _messages.clear();
      _pending = null;
      _conversationId = null;
      loading = false;
      ready = false;
      error = const AiChatFailure(
        'unauthorized',
        'A conta mudou. Abra o Coach novamente.',
      );
      _notify();
    }
  }

  bool _valid(int epoch) => !_disposed && epoch == _epoch;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    AccountSessionLifecycle.revision.removeListener(_accountChanged);
    super.dispose();
  }
}
