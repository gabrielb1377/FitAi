import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Label curto com ícone opcional para metadados e legendas.
class FitLabel extends StatelessWidget {
  const FitLabel({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.semanticLabel,
  });

  final String text;
  final IconData? icon;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: semanticLabel ?? text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: FitLayout.iconSizeSmall, color: resolvedColor),
            const SizedBox(width: FitSpacing.s4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: resolvedColor),
            ),
          ),
        ],
      ),
    );
  }
}
