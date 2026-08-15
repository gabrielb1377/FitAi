import 'package:flutter/material.dart';

import '../tokens/fit_layout.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Superficie de destaque para o proximo passo do usuario.
///
/// Usa contraste, escala e uma barra de assinatura em vez de sombra ou glow.
class FitEditorialHero extends StatelessWidget {
  const FitEditorialHero({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.action,
    this.onTap,
    this.semanticLabel,
    this.accentColor,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final Widget? action;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = accentColor ?? colors.primary;
    final content = Padding(
      padding: const EdgeInsets.all(FitSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: FitSpacing.s8),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: FitSpacing.s4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: FitSpacing.s12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          child,
          if (action != null) ...[
            const SizedBox(height: FitSpacing.s20),
            action!,
          ],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? title,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: FitRadius.largeBorder),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ColoredBox(
                  color: accent,
                  child: const SizedBox(width: FitSpacing.s4),
                ),
              ),
            ),
            InkWell(onTap: onTap, child: content),
          ],
        ),
      ),
    );
  }
}

/// Dado de uma metrica curta exibida em [FitMetricRail].
class FitMetricRailItem {
  const FitMetricRailItem({
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
}

/// Linha editorial de metricas sem criar um card para cada numero.
class FitMetricRail extends StatelessWidget {
  const FitMetricRail({super.key, required this.items});

  final List<FitMetricRailItem> items;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14);
        final compact =
            constraints.maxWidth < 280 || textScale > 18 || items.length > 4;
        if (compact) {
          return Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s8,
            children: [
              for (final item in items)
                SizedBox(
                  width: (constraints.maxWidth - FitSpacing.s8) / 2,
                  child: _RailItem(item: item),
                ),
            ],
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(child: _RailItem(item: items[index])),
                if (index < items.length - 1)
                  SizedBox(
                    height: FitSpacing.s32,
                    child: VerticalDivider(
                      width: FitLayout.borderThin,
                      thickness: FitLayout.borderThin,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.item});

  final FitMetricRailItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      button: item.onTap != null,
      label: '${item.label}: ${item.value}',
      child: InkWell(
        onTap: item.onTap,
        borderRadius: FitRadius.mediumBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FitLayout.minimumTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FitSpacing.s8,
              vertical: FitSpacing.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: FitLayout.iconSizeSmall, color: color),
                  const SizedBox(height: FitSpacing.s8),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha de acao para listas e configuracoes, com alvo de toque acessivel.
class FitActionRow extends StatelessWidget {
  const FitActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = destructive ? colors.error : colors.onSurface;
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FitLayout.listTileMinHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? foreground),
                const SizedBox(width: FitSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: foreground),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: FitSpacing.s2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: FitSpacing.s12),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
