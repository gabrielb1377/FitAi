import 'package:flutter/material.dart';

import '../tokens/fit_spacing.dart';

/// Cabecalho FitIA com voltar, avatar e acoes fornecidas pelo chamador.
///
/// Exemplo: `FitHeader(title: 'Planos', showBackButton: true, onBack: pop)`.
class FitHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String backTooltip;
  final Widget? avatar;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const FitHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    this.backTooltip = 'Voltar',
    this.avatar,
    this.leading,
    this.trailing,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(
      FitSpacing.s20,
      FitSpacing.s16,
      FitSpacing.s20,
      FitSpacing.s12,
    ),
  }) : assert(!showBackButton || onBack != null),
       assert(avatar == null || leading == null);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final prefix = leading ?? avatar;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBackButton)
            IconButton(
              tooltip: backTooltip,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          if (prefix != null) ...[
            prefix,
            const SizedBox(width: FitSpacing.s12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
          ...actions,
        ],
      ),
    );
  }
}
