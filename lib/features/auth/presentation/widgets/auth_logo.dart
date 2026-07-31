import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Marca temporaria em vetor ate que o asset oficial seja integrado ao app.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 34.0 : 56.0;
    final textSize = compact ? 28.0 : 42.0;
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
                  borderRadius: BorderRadius.circular(FitRadius.medium),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: FitColors.primary,
                  size: iconSize * .72,
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              Text.rich(
                TextSpan(
                  text: 'Fit',
                  style: TextStyle(
                    color: FitColors.textPrimary,
                    fontSize: textSize,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(
                      text: 'IA',
                      style: TextStyle(color: FitColors.primary),
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
