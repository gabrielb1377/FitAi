import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Item de lista temático para configurações, seleções e ações simples.
class FitListTile extends StatelessWidget {
  const FitListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.semanticLabel,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: FitSpacing.s12,
      vertical: FitSpacing.s4,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;
  final String? semanticLabel;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      selected: selected,
      label: semanticLabel ?? title,
      child: ListTile(
        enabled: enabled,
        selected: selected,
        onTap: enabled ? onTap : null,
        leading: leading,
        trailing: trailing,
        contentPadding: contentPadding,
        minTileHeight: FitLayout.listTileMinHeight,
        shape: const RoundedRectangleBorder(
          borderRadius: FitRadius.mediumBorder,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
