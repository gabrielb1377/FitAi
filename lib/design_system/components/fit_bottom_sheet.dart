import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Estrutura visual para acoes contextuais e selecoes curtas.
class FitBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  const FitBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.showHandle = true,
    this.padding = const EdgeInsets.fromLTRB(
      FitSpacing.s20,
      FitSpacing.s8,
      FitSpacing.s20,
      FitSpacing.s24,
    ),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    Widget? action,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FitBottomSheet(
        title: title,
        subtitle: subtitle,
        action: action,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FitRadius.large),
        ),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHandle)
                Align(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: FitRadius.pillBorder,
                    ),
                  ),
                ),
              if (title != null) ...[
                const SizedBox(height: FitSpacing.s16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: FitSpacing.s8),
                      action!,
                    ],
                  ],
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: FitSpacing.s4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              if (title != null || subtitle != null)
                const SizedBox(height: FitSpacing.s16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
