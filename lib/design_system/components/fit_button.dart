import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/fit_layout.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Botao semantico FitIA com variantes, loading e protecao contra duplo toque.
///
/// Para uma operacao assincrona, use [onPressedAsync]. Enquanto ela estiver em
/// andamento, o botao mostra loading e bloqueia novas interacoes.
class FitButton extends StatefulWidget {
  const FitButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onPressedAsync,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    this.variant = FitButtonVariant.primary,
    this.size = FitButtonSize.regular,
    this.expand = false,
    this.isLoading = false,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
    this.enableHapticFeedback = false,
  }) : assert(
         onPressed == null || onPressedAsync == null,
         'Use onPressed ou onPressedAsync, nunca ambos.',
       ),
       assert(
         icon == null || leadingIcon == null,
         'icon e leadingIcon representam a mesma posicao.',
       );

  final String label;
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;

  /// Alias legado para [leadingIcon].
  final IconData? icon;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final FitButtonVariant variant;
  final FitButtonSize size;
  final bool expand;
  final bool isLoading;
  final bool enabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool enableHapticFeedback;

  @override
  State<FitButton> createState() => _FitButtonState();
}

class _FitButtonState extends State<FitButton> {
  bool _isSubmitting = false;

  bool get _isEnabled =>
      widget.enabled &&
      !widget.isLoading &&
      !_isSubmitting &&
      (widget.onPressed != null || widget.onPressedAsync != null);

  Future<void> _handlePressed() async {
    if (!_isEnabled) return;
    if (widget.enableHapticFeedback) {
      unawaited(HapticFeedback.selectionClick());
    }

    final asyncCallback = widget.onPressedAsync;
    if (asyncCallback == null) {
      widget.onPressed?.call();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await asyncCallback();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height = widget.size.minimumHeight;
    final foreground = switch (widget.variant) {
      FitButtonVariant.danger => colors.onError,
      FitButtonVariant.success || FitButtonVariant.primary => colors.onPrimary,
      _ => colors.primary,
    };
    final background = switch (widget.variant) {
      FitButtonVariant.danger => colors.error,
      FitButtonVariant.success || FitButtonVariant.primary => colors.primary,
      FitButtonVariant.secondary => colors.secondaryContainer,
      _ => null,
    };
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(FitLayout.none, height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: FitSpacing.s16),
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: WidgetStatePropertyAll(foreground),
      backgroundColor: background == null
          ? null
          : WidgetStatePropertyAll(background),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: FitRadius.mediumBorder),
      ),
    );
    final isLoading = widget.isLoading || _isSubmitting;
    final content = _content(foreground, isLoading);
    final callback = _isEnabled ? _handlePressed : null;
    final button = switch (widget.variant) {
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
    final labeledButton = Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel ?? widget.label,
      value: isLoading ? 'Carregando' : null,
      child: widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
    return widget.tooltip == null
        ? labeledButton
        : Tooltip(message: widget.tooltip!, child: labeledButton);
  }

  Widget _content(Color foreground, bool isLoading) {
    if (isLoading) {
      return SizedBox(
        width: FitLayout.loadingSizeSmall,
        height: FitLayout.loadingSizeSmall,
        child: CircularProgressIndicator(
          strokeWidth: FitLayout.loadingStrokeThin,
          color: foreground,
        ),
      );
    }

    final leadingIcon = widget.leadingIcon ?? widget.icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: widget.size.iconSize),
          const SizedBox(width: FitSpacing.s8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: FitSpacing.s8),
          Icon(widget.trailingIcon, size: widget.size.iconSize),
        ],
      ],
    );
  }
}

enum FitButtonVariant { primary, secondary, outlined, ghost, danger, success }

enum FitButtonSize { small, medium, large, compact, regular }

extension FitButtonSizeTokens on FitButtonSize {
  double get minimumHeight => switch (this) {
    FitButtonSize.small || FitButtonSize.compact => FitLayout.buttonHeightSmall,
    FitButtonSize.medium ||
    FitButtonSize.regular => FitLayout.buttonHeightMedium,
    FitButtonSize.large => FitLayout.buttonHeightLarge,
  };

  double get iconSize => switch (this) {
    FitButtonSize.small || FitButtonSize.compact => FitLayout.iconSizeSmall,
    FitButtonSize.medium || FitButtonSize.regular => FitLayout.iconSizeButton,
    FitButtonSize.large => FitLayout.iconSizeMedium,
  };
}
