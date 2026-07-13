import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Dialog FitIA para confirmacoes curtas e decisoes criticas.
class FitDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final List<Widget> actions;

  const FitDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.actions = const [],
  }) : assert(message == null || content == null);

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    List<Widget> actions = const [],
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => FitDialog(
        title: title,
        message: message,
        content: content,
        icon: icon,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: FitRadius.largeBorder,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: colors.primary),
                const SizedBox(height: FitSpacing.s12),
              ],
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (message != null || content != null) ...[
                const SizedBox(height: FitSpacing.s12),
                content ??
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: FitSpacing.s20),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: FitSpacing.s8,
                  runSpacing: FitSpacing.s8,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
