import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';

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
      FitIconButtonVariant.subtle => colors.primaryContainer,
      FitIconButtonVariant.danger => colors.error.withAlpha(24),
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
        disabledForegroundColor: colors.onSurface.withAlpha(38),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.mediumBorder,
          side: border,
        ),
      ),
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : Icon(widget.icon),
    );
    return Semantics(
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
                Positioned(top: -2, right: -2, child: widget.badge!),
              ],
            ),
    );
  }
}

enum FitIconButtonVariant { standard, subtle, outlined, danger }
