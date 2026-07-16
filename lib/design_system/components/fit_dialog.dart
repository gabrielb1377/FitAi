import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

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

/// Confirmacao curta para acoes importantes ou destrutivas.
class FitConfirmDialog extends StatelessWidget {
  const FitConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => FitConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FitDialog(
      title: title,
      message: message,
      icon: isDestructive
          ? Icons.warning_amber_rounded
          : Icons.help_outline_rounded,
      actions: [
        FitButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
          variant: FitButtonVariant.ghost,
          size: FitButtonSize.compact,
        ),
        FitButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          variant: isDestructive
              ? FitButtonVariant.danger
              : FitButtonVariant.primary,
          size: FitButtonSize.compact,
        ),
      ],
    );
  }
}
