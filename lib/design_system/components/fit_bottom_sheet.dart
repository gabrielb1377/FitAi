import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_layout.dart';
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
                    width: FitLayout.bottomSheetHandleWidth,
                    height: FitLayout.bottomSheetHandleHeight,
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

/// Opcao simples para [FitActionSheet]. O chamador decide a navegacao ou a
/// logica de dominio por meio de [onTap].
class FitActionSheetItem {
  const FitActionSheetItem({
    required this.label,
    required this.icon,
    this.description,
    this.onTap,
    this.isDestructive = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final String? description;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool enabled;
}

/// Bottom sheet para uma lista curta de acoes contextuais.
class FitActionSheet extends StatelessWidget {
  const FitActionSheet({
    super.key,
    required this.items,
    this.title,
    this.subtitle,
  });

  final List<FitActionSheetItem> items;
  final String? title;
  final String? subtitle;

  static Future<T?> show<T>({
    required BuildContext context,
    required List<FitActionSheetItem> items,
    String? title,
    String? subtitle,
    bool isScrollControlled = false,
  }) {
    return FitBottomSheet.show<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      isScrollControlled: isScrollControlled,
      child: FitActionSheet(items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final color = item.isDestructive ? colors.error : colors.onSurface;
        return Semantics(
          button: true,
          enabled: item.enabled && item.onTap != null,
          label: item.label,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: item.enabled && item.onTap != null,
            leading: Icon(item.icon, color: color),
            title: Text(item.label),
            subtitle: item.description == null ? null : Text(item.description!),
            onTap: item.enabled ? item.onTap : null,
          ),
        );
      },
    );
  }
}
