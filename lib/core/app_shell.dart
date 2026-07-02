import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_router.dart';
import 'navigation/bottom_navigation.dart';
import 'navigation/side_navigation.dart';

class AppShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppRouteDestination> destinations;
  final List<Widget> pages;

  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.pages,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int previousIndex = 0;

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      previousIndex = oldWidget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.selectedIndex.clamp(0, widget.pages.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= 840;
        final page = _AnimatedShellPage(
          index: index,
          previousIndex: previousIndex,
          child: widget.pages[index],
        );

        if (useSideNavigation) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                AppSideNavigation(
                  selectedIndex: index,
                  destinations: widget.destinations,
                  onDestinationSelected: widget.onDestinationSelected,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: page,
          bottomNavigationBar: AppBottomNavigation(
            selectedIndex: index,
            destinations: widget.destinations,
            onDestinationSelected: widget.onDestinationSelected,
          ),
        );
      },
    );
  }
}

class _AnimatedShellPage extends StatelessWidget {
  final int index;
  final int previousIndex;
  final Widget child;

  const _AnimatedShellPage({
    required this.index,
    required this.previousIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final forward = index >= previousIndex;

    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.curve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: Offset(forward ? 0.035 : -0.035, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(index), child: child),
    );
  }
}
