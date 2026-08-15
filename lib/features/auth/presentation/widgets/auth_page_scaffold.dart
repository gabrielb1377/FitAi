import 'package:flutter/material.dart';

import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_duration.dart';
import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_spacing.dart';

/// Estrutura comum do AUTH: fundo premium, safe area e coluna central fluida.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: FitSpacing.s24),
    this.scrollable = true,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: FitLayout.domainAuthMaxContentWidth,
      ),
      child: Padding(padding: padding, child: child),
    );

    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        child: AnimatedPadding(
          duration: FitDuration.transition,
          curve: FitDuration.standardCurve,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: alignment,
            child: FocusTraversalGroup(
              child: scrollable
                  ? SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: content,
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}
