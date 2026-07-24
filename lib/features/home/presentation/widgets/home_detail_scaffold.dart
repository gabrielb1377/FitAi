import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeDetailScaffold extends StatelessWidget {
  const HomeDetailScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.bottomNavigationBar,
    this.centerTitle = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitColors.background,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FitTopBar(
              title: title,
              subtitle: subtitle.trim().isEmpty ? null : subtitle,
              showBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: actions,
              centerTitle: centerTitle,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
