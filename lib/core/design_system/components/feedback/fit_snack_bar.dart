import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_duration.dart';
import '../../../../design_system/tokens/fit_icons.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Papel semântico do feedback transitório.
enum FitSnackBarTone { neutral, success, info, warning, error }

/// Configuração imutável de SnackBar alinhada ao Design System.
class FitSnackBar {
  const FitSnackBar({
    required this.message,
    this.tone = FitSnackBarTone.neutral,
    this.actionLabel,
    this.onAction,
    this.duration = FitDuration.snackBar,
  }) : assert((actionLabel == null) == (onAction == null));

  final String message;
  final FitSnackBarTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;

  /// Mostra o feedback no [ScaffoldMessenger] mais próximo.
  void show(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = switch (tone) {
      FitSnackBarTone.neutral => colors.onSurfaceVariant,
      FitSnackBarTone.success => FitColors.success,
      FitSnackBarTone.info => FitColors.info,
      FitSnackBarTone.warning => FitColors.warning,
      FitSnackBarTone.error => colors.error,
    };
    final icon = switch (tone) {
      FitSnackBarTone.neutral => FitIcons.info,
      FitSnackBarTone.success => FitIcons.success,
      FitSnackBarTone.info => FitIcons.info,
      FitSnackBarTone.warning => FitIcons.warning,
      FitSnackBarTone.error => FitIcons.error,
    };
    final snackBar = SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: FitRadius.mediumBorder),
      content: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: FitSpacing.s12),
          Expanded(child: Text(message)),
        ],
      ),
      action: onAction == null
          ? null
          : SnackBarAction(label: actionLabel!, onPressed: onAction!),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
