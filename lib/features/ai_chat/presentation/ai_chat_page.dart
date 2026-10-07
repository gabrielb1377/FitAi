import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../application/ai_chat_controller.dart';
import '../data/ai_chat_gateway.dart';
import '../data/ai_chat_repository.dart';

/// Minimal authenticated Coach surface. Fitness actions remain read-only.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, this.controller});
  final AiChatController? controller;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late final AiChatController _controller;
  HttpAiChatGateway? _gateway;
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
            onPressed: _controller.ready && !_controller.loading
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
                                  'O Coach usa seus dados sincronizados. As orientacoes nao alteram planos ou metas.',
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
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: FitSpacing.s12,
                              ),
                              child: Semantics(
                                label: user ? 'Voce' : 'Coach FitIA',
                                liveRegion: !user,
                                child: FitCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user ? 'Voce' : 'Coach FitIA',
                                        style: context.textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: FitSpacing.s8),
                                      SelectableText(
                                        content,
                                        style: context.textTheme.bodyLarge,
                                      ),
                                      if (pending)
                                        Text(
                                          _controller.loading
                                              ? 'Aguardando resposta'
                                              : 'Mensagem pendente',
                                          style: context.textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
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
