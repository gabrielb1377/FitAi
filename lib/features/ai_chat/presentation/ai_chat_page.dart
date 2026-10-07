import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../application/ai_chat_controller.dart';
import '../data/ai_chat_gateway.dart';
import '../data/ai_chat_repository.dart';
import '../application/ai_action_controller.dart';
import '../application/ai_action_executor.dart';
import '../data/ai_action_gateway.dart';
import 'ai_action_card.dart';
import 'ai_chat_message_bubble.dart';

/// Minimal authenticated Coach surface with separate, explicitly confirmed actions.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, this.controller, this.actionController});
  final AiChatController? controller;
  final AiActionController? actionController;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late final AiChatController _controller;
  HttpAiChatGateway? _gateway;
  HttpAiActionGateway? _actionGateway;
  late final AiActionController _actions;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        AiChatController(
          repository: AiChatRepository(gateway: _gateway = HttpAiChatGateway()),
        );
    _controller.addListener(_changed);
    _actions =
        widget.actionController ??
        AiActionController(
          gateway: _actionGateway = HttpAiActionGateway(),
          executor: CanonicalAiActionExecutor(),
          onChanged: _controller.updateAction,
        );
    _actions.addListener(_changed);
    unawaited(_controller.initialize());
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    if (!_controller.ready ||
        _controller.loading ||
        _controller.pending != null ||
        _input.text.trim().isEmpty) {
      return;
    }
    final text = _input.text;
    _input.clear();
    unawaited(_controller.send(text));
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _actions.removeListener(_changed);
    if (widget.actionController == null) _actions.dispose();
    _actionGateway?.dispose();
    if (widget.controller == null) _controller.dispose();
    _gateway?.dispose();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _controller.messages;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach FitIA'),
        actions: [
          FitIconButton(
            icon: Icons.add_comment_outlined,
            tooltip: 'Nova conversa',
            onPressed:
                _controller.ready && !_controller.loading && !_actions.busy
                ? () => unawaited(_controller.newConversation())
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FitLayout.domainPlansMaxContentWidth,
            ),
            child: Column(
              children: [
                Expanded(
                  child: messages.isEmpty && _controller.pending == null
                      ? const SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(FitSpacing.s24),
                            child: FitEmptyState(
                              icon: Icons.chat_bubble_outline,
                              title: 'Converse sobre seu treino',
                              description:
                                  'O Coach usa seus dados sincronizados. Sugestoes para a ficha exigem sua confirmacao.',
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(FitSpacing.s16),
                          itemCount:
                              messages.length +
                              (_controller.pending == null ? 0 : 1),
                          itemBuilder: (context, index) {
                            final pending = index == messages.length;
                            final content = pending
                                ? _controller.pending!['message'] as String
                                : messages[index].content;
                            final user =
                                pending || messages[index].role == 'user';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AiChatMessageBubble(
                                  content: content,
                                  user: user,
                                  pending: pending,
                                  loading: _controller.loading,
                                ),
                                if (!pending)
                                  for (final action in messages[index].actions)
                                    AiActionCard(
                                      proposal: action,
                                      controller: _actions,
                                    ),
                              ],
                            );
                          },
                        ),
                ),
                if (_controller.loading)
                  Semantics(
                    liveRegion: true,
                    label: 'Coach preparando resposta',
                    child: const LinearProgressIndicator(),
                  ),
                if (_controller.error != null)
                  Padding(
                    padding: const EdgeInsets.all(FitSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _controller.error!.message,
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                        if (_controller.error!.retryable)
                          FitSecondaryButton(
                            label: 'Tentar novamente',
                            onPressed: _controller.loading
                                ? null
                                : () => unawaited(_controller.retry()),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(FitSpacing.s16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FitTextField(
                          controller: _input,
                          focusNode: _focus,
                          label: 'Mensagem para o Coach',
                          enabled:
                              _controller.ready &&
                              !_controller.loading &&
                              _controller.pending == null,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: FitSpacing.s8),
                      FitIconButton(
                        icon: Icons.send_outlined,
                        tooltip: 'Enviar mensagem',
                        onPressed:
                            _controller.ready &&
                                !_controller.loading &&
                                _controller.pending == null
                            ? _send
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
