import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

class AuthPageTitle extends StatelessWidget {
  const AuthPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.centered = true,
  });

  final String title;
  final String subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final alignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: textAlign,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: FitColors.textPrimary),
          ),
        ),
        const SizedBox(height: FitSpacing.s8),
        Text(
          subtitle,
          textAlign: textAlign,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: FitColors.textSecondary),
        ),
      ],
    );
  }
}
