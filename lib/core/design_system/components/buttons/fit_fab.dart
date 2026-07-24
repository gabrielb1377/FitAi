import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Floating action button controlado externamente e sem conhecimento de rotas.
class FitFAB extends StatefulWidget {
  const FitFAB({
    super.key,
    required this.icon,
    required this.tooltip,
    this.label,
    this.onPressed,
    this.onPressedAsync,
    this.loading = false,
    this.enabled = true,
    this.fullWidth = false,
    this.size = FitButtonSize.medium,
    this.enableHapticFeedback = false,
    this.semanticLabel,
  }) : assert(onPressed == null || onPressedAsync == null);

  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final bool loading;
  final bool enabled;
  final bool fullWidth;
  final FitButtonSize size;
  final bool enableHapticFeedback;
  final String? semanticLabel;

  @override
  State<FitFAB> createState() => _FitFABState();
}

class _FitFABState extends State<FitFAB> {
  bool _submitting = false;

  bool get _enabled =>
      widget.enabled &&
      !widget.loading &&
      !_submitting &&
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

    setState(() => _submitting = true);
    try {
      await asyncCallback();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.loading || _submitting;
    final colors = Theme.of(context).colorScheme;
    final foreground = _enabled ? colors.onPrimary : FitColors.textDisabled;
    final background = _enabled ? colors.primary : FitColors.surfaceDisabled;
    final icon = loading
        ? SizedBox.square(
            dimension: FitLayout.loadingSizeSmall,
            child: CircularProgressIndicator(
              strokeWidth: FitLayout.loadingStrokeThin,
              color: foreground,
            ),
          )
        : Icon(widget.icon, size: widget.size.iconSize);
    final callback = _enabled ? _handlePressed : null;
    final Widget button;

    if (widget.label != null || widget.fullWidth) {
      button = FloatingActionButton.extended(
        tooltip: widget.tooltip,
        onPressed: callback,
        backgroundColor: background,
        foregroundColor: foreground,
        icon: icon,
        label: Text(widget.label ?? widget.tooltip),
      );
    } else {
      button = switch (widget.size) {
        FitButtonSize.small ||
        FitButtonSize.compact => FloatingActionButton.small(
          tooltip: widget.tooltip,
          onPressed: callback,
          backgroundColor: background,
          foregroundColor: foreground,
          child: icon,
        ),
        FitButtonSize.large => FloatingActionButton.large(
          tooltip: widget.tooltip,
          onPressed: callback,
          backgroundColor: background,
          foregroundColor: foreground,
          child: icon,
        ),
        FitButtonSize.medium || FitButtonSize.regular => FloatingActionButton(
          tooltip: widget.tooltip,
          onPressed: callback,
          backgroundColor: background,
          foregroundColor: foreground,
          child: icon,
        ),
      };
    }

    final result = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label ?? widget.tooltip,
      value: loading ? 'Carregando' : null,
      child: button,
    );
    return widget.fullWidth
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s16),
            child: SizedBox(width: double.infinity, child: result),
          )
        : result;
  }
}
