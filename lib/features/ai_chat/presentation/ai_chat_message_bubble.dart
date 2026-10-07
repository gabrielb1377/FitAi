import 'package:flutter/material.dart';
import '../../../design_system/fit_design_system.dart';

/// Existing Coach message styling, separated from action consent controls.
class AiChatMessageBubble extends StatelessWidget {
  const AiChatMessageBubble({
    super.key,
    required this.content,
    required this.user,
    required this.pending,
    required this.loading,
  });
  final String content;
  final bool user, pending, loading;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: FitSpacing.s12),
    child: Semantics(
      label: user ? 'Voce' : 'Coach FitIA',
      liveRegion: !user,
      child: FitCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user ? 'Voce' : 'Coach FitIA',
              style: context.textTheme.labelLarge,
            ),
            const SizedBox(height: FitSpacing.s8),
            SelectableText(content, style: context.textTheme.bodyLarge),
            if (pending)
              Text(
                loading ? 'Aguardando resposta' : 'Mensagem pendente',
                style: context.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    ),
  );
}
