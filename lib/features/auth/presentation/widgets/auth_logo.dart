import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Marca temporaria em vetor ate que o asset oficial seja integrado ao app.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact
        ? FitLayout.iconSizeLarge
        : FitLayout.buttonHeightLarge;
    final textStyle = (compact
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.displayLarge);
    return Semantics(
      label: 'FitIA',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: FitColors.primaryContainer,
                  borderRadius: FitRadius.mediumBorder,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: FitColors.primary,
                  size: compact
                      ? FitLayout.iconSizeButton
                      : FitLayout.iconSizeLarge,
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              Text.rich(
                TextSpan(
                  text: 'Fit',
                  style: textStyle?.copyWith(
                    color: FitColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(
                      text: 'IA',
                      style: const TextStyle(color: FitColors.ai),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
