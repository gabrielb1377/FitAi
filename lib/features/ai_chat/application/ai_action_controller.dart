import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/local_account_data_boundary.dart';
import '../data/ai_action_gateway.dart';
import '../domain/ai_action_models.dart';
import '../domain/ai_chat_models.dart';
import 'ai_action_executor.dart';

/// Coordinates explicit confirmation, canonical execution and remote verification.
class AiActionController extends ChangeNotifier {
  AiActionController({
    required this.gateway,
    required this.executor,
    this.onChanged,
  }) {
    AccountSessionLifecycle.revision.addListener(_accountChanged);
  }
  final AiActionGateway gateway;
  final AiActionExecutor executor;
  final Future<void> Function(AiActionProposal)? onChanged;
  final Set<String> _busy = {}, _saved = {};
  final Map<String, AiActionProposal> _current = {};
  final Map<String, String> _errors = {};
  bool _disposed = false;
  int _epoch = 0;
  bool get busy => _busy.isNotEmpty;
  bool isBusy(String id) => _busy.contains(id);
  bool saved(String id) => _saved.contains(id);
  String? error(String id) => _errors[id];
  AiActionProposal current(AiActionProposal original) =>
      _current[original.id] ?? original;

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'fitia.aiChat.v1.device';
    final current = prefs.getString(key);
    if (current != null) return current;
    final id =
        'chat-device-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    if (!await prefs.setString(key, id)) {
      throw const AiChatFailure(
        'storage',
        'Nao foi possivel preservar a confirmacao.',
      );
    }
    return id;
  }

  Future<void> confirm(AiActionProposal original) =>
      _run(original, cancel: false);
  Future<void> cancel(AiActionProposal original) =>
      _run(original, cancel: true);

  Future<void> _run(AiActionProposal original, {required bool cancel}) async {
    final id = original.id, owner = AccountSessionLifecycle.activeUserId;
    if (owner == null || _disposed || _busy.contains(id)) return;
    final initial = current(original);
    if (cancel
        ? initial.status != 'VALIDATED'
        : !['VALIDATED', 'CONFIRMED'].contains(initial.status)) {
      return;
    }
    final epoch = _epoch;
    bool valid() =>
        !_disposed &&
        _epoch == epoch &&
        AccountSessionLifecycle.activeUserId == owner;
    _busy.add(id);
    _errors.remove(id);
    notifyListeners();
    try {
      final device = await _deviceId();
      if (!valid()) return;
      var action = cancel
          ? await gateway.cancel(owner, id)
          : await gateway.confirm(owner, id, device);
      if (!valid()) return;
      _current[id] = action;
      await onChanged?.call(action);
      if (!valid()) return;
      if (!cancel && action.status == 'CONFIRMED') {
        await executor.execute(owner, action);
        if (!valid()) return;
        _saved.add(id);
        // A missing ACK never erases a successful local command/receipt.
        try {
          action = await gateway.complete(owner, id);
          if (!valid()) return;
          _current[id] = action;
          await onChanged?.call(action);
        } on AiChatFailure {
          /* Local result remains visible; verification can be retried. */
        }
      }
      if (!cancel && ['REJECTED', 'EXPIRED'].contains(action.status)) {
        _errors[id] =
            'A sugestao expirou ou a ficha mudou. Solicite outra ao Coach.';
      }
    } on AiChatFailure catch (e) {
      if (valid()) _errors[id] = e.message;
    } on Object {
      if (valid()) {
        _errors[id] =
            'Nao foi possivel verificar esta sugestao. Tente novamente.';
      }
    } finally {
      if (valid()) {
        _busy.remove(id);
        notifyListeners();
      }
    }
  }

  void _accountChanged() {
    _epoch++;
    _busy.clear();
    _saved.clear();
    _current.clear();
    _errors.clear();
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
