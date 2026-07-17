import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

enum AuthInlineMessageTone { error, info, success }

class AuthInlineMessage extends StatelessWidget {
  const AuthInlineMessage({
    super.key,
    required this.message,
    this.tone = AuthInlineMessageTone.error,
  });

  final String message;
  final AuthInlineMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AuthInlineMessageTone.error => FitColors.error,
      AuthInlineMessageTone.info => FitColors.info,
      AuthInlineMessageTone.success => FitColors.success,
    };
    final icon = switch (tone) {
      AuthInlineMessageTone.error => Icons.error_outline_rounded,
      AuthInlineMessageTone.info => Icons.info_outline_rounded,
      AuthInlineMessageTone.success => Icons.check_circle_outline_rounded,
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FitSpacing.s12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: FitRadius.mediumBorder,
          border: Border.all(color: color.withAlpha(90)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: FitSpacing.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: FitColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
