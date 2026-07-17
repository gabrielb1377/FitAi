import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeDetailScaffold extends StatelessWidget {
  const HomeDetailScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FitHeader(
              title: title,
              subtitle: subtitle,
              showBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: actions,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
