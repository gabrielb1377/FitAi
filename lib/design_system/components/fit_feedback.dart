import 'package:flutter/material.dart';

import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Helpers locais de feedback. Eles nao substituem SnackBars existentes nem
/// criam estado global; cada chamada usa o [BuildContext] atual.
abstract final class FitFeedback {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.check_circle_outline_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: Theme.of(context).colorScheme.error,
    );
  }

  static void showOffline(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.cloud_off_rounded,
      color: Theme.of(context).colorScheme.secondary,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            label: message,
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Icon(icon, color: color ?? colors.primary),
                  const SizedBox(width: FitSpacing.s12),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
          ),
        ),
      );
  }
}
