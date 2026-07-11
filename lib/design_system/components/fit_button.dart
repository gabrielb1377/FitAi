import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Botao base FitIA com variacoes semanticas e estilo guiado pelo tema atual.
class FitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FitButtonVariant variant;
  final FitButtonSize size;
  final bool expand;

  const FitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = FitButtonVariant.primary,
    this.size = FitButtonSize.regular,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = size == FitButtonSize.compact ? 40.0 : 48.0;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: FitSpacing.s16),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: FitRadius.mediumBorder),
      ),
    );
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: FitSpacing.s8),
              Text(label),
            ],
          );

    final button = switch (variant) {
      FitButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      FitButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      FitButtonVariant.ghost => TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum FitButtonVariant { primary, secondary, ghost }

enum FitButtonSize { compact, regular }
