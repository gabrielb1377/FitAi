import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/fit_layout.dart';
import '../tokens/fit_opacity.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';
import 'fit_button.dart';

/// Acao apenas com icone. [tooltip] e obrigatorio para que a acao seja clara
/// para leitores de tela e para interacoes por mouse/web.
class FitIconButton extends StatefulWidget {
  const FitIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.onPressedAsync,
    this.variant = FitIconButtonVariant.standard,
    this.enabled = true,
    this.isLoading = false,
    this.badge,
    this.semanticLabel,
    this.size = FitButtonSize.medium,
    this.fullWidth = false,
    this.enableHapticFeedback = false,
  }) : assert(onPressed == null || onPressedAsync == null);

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final FitIconButtonVariant variant;
  final bool enabled;
  final bool isLoading;
  final Widget? badge;
  final String? semanticLabel;
  final FitButtonSize size;
  final bool fullWidth;
  final bool enableHapticFeedback;

  @override
  State<FitIconButton> createState() => _FitIconButtonState();
}

class _FitIconButtonState extends State<FitIconButton> {
  bool _isSubmitting = false;

  bool get _enabled =>
      widget.enabled &&
      !widget.isLoading &&
      !_isSubmitting &&
      (widget.onPressed != null || widget.onPressedAsync != null);

  Future<void> _handlePressed() async {
    if (!_enabled) return;
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
    final foreground = switch (widget.variant) {
      FitIconButtonVariant.danger => colors.error,
      _ => colors.onSurface,
    };
    final background = switch (widget.variant) {
      FitIconButtonVariant.subtle => colors.surfaceContainerHighest,
      FitIconButtonVariant.danger => colors.error.withValues(
        alpha: FitOpacity.selected,
      ),
      _ => Colors.transparent,
    };
    final border = widget.variant == FitIconButtonVariant.outlined
        ? BorderSide(color: colors.outlineVariant)
        : BorderSide.none;
    final loading = widget.isLoading || _isSubmitting;
    final button = IconButton(
      tooltip: widget.tooltip,
      onPressed: _enabled ? _handlePressed : null,
      style: IconButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        disabledForegroundColor: colors.onSurface.withValues(
          alpha: FitOpacity.disabled,
        ),
        minimumSize: Size.square(widget.size.minimumHeight),
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.mediumBorder,
          side: border,
        ),
      ),
      icon: loading
          ? SizedBox(
              width: FitLayout.loadingSizeSmall,
              height: FitLayout.loadingSizeSmall,
              child: CircularProgressIndicator(
                strokeWidth: FitLayout.loadingStrokeThin,
                color: foreground,
              ),
            )
          : Icon(widget.icon, size: widget.size.iconSize),
    );
    final semanticButton = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.tooltip,
      value: loading ? 'Carregando' : null,
      child: widget.badge == null
          ? button
          : Stack(
              clipBehavior: Clip.none,
              children: [
                button,
                Positioned(
                  top: -FitSpacing.s2,
                  right: -FitSpacing.s2,
                  child: widget.badge!,
                ),
              ],
            ),
    );
    return widget.fullWidth
        ? SizedBox(width: double.infinity, child: semanticButton)
        : semanticButton;
  }
}

enum FitIconButtonVariant { standard, subtle, outlined, danger }
