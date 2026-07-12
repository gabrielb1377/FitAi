import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Botao semantico FitIA com estados normal, loading e disabled.
///
/// Exemplo: `FitButton(label: 'Salvar', onPressed: save, icon: Icons.save)`.
class FitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FitButtonVariant variant;
  final FitButtonSize size;
  final bool expand;
  final bool isLoading;
  final bool enabled;
  final String? semanticLabel;

  const FitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = FitButtonVariant.primary,
    this.size = FitButtonSize.regular,
    this.expand = false,
    this.isLoading = false,
    this.enabled = true,
    this.semanticLabel,
  });

  bool get _isEnabled => enabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height = size == FitButtonSize.compact ? 40.0 : 48.0;
    final foreground = switch (variant) {
      FitButtonVariant.danger => colors.onError,
      FitButtonVariant.success || FitButtonVariant.primary => colors.onPrimary,
      _ => null,
    };
    final background = switch (variant) {
      FitButtonVariant.danger => colors.error,
      FitButtonVariant.success || FitButtonVariant.primary => colors.primary,
      FitButtonVariant.secondary => colors.secondaryContainer,
      _ => null,
    };
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: FitSpacing.s16),
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: foreground == null
          ? null
          : WidgetStatePropertyAll(foreground),
      backgroundColor: background == null
          ? null
          : WidgetStatePropertyAll(background),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: FitRadius.mediumBorder),
      ),
    );
    final content = _content(foreground ?? colors.primary);
    final callback = _isEnabled ? onPressed : null;
    final button = switch (variant) {
      FitButtonVariant.primary ||
      FitButtonVariant.danger ||
      FitButtonVariant.success => FilledButton(
        onPressed: callback,
        style: style,
        child: content,
      ),
      FitButtonVariant.secondary => FilledButton.tonal(
        onPressed: callback,
        style: style,
        child: content,
      ),
      FitButtonVariant.outlined => OutlinedButton(
        onPressed: callback,
        style: style,
        child: content,
      ),
      FitButtonVariant.ghost => TextButton(
        onPressed: callback,
        style: style,
        child: content,
      ),
    };
    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: semanticLabel ?? label,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }

  Widget _content(Color foreground) {
    if (isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: FitSpacing.s8),
        Text(label),
      ],
    );
  }
}

enum FitButtonVariant { primary, secondary, outlined, ghost, danger, success }

enum FitButtonSize { compact, regular }
