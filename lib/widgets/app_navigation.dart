import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppNavigationDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AppAdaptiveNavigationScaffold extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavigationDestination> destinations;
  final List<Widget> pages;

  const AppAdaptiveNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.pages,
  });

  @override
  State<AppAdaptiveNavigationScaffold> createState() =>
      _AppAdaptiveNavigationScaffoldState();
}

class _AppAdaptiveNavigationScaffoldState
    extends State<AppAdaptiveNavigationScaffold> {
  int previousIndex = 0;

  @override
  void didUpdateWidget(covariant AppAdaptiveNavigationScaffold oldWidget) {
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
        final usarRail = constraints.maxWidth >= 840;
        final page = _AnimatedNavigationPage(
          index: index,
          previousIndex: previousIndex,
          child: widget.pages[index],
        );

        if (usarRail) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _NavigationRailSurface(
                  selectedIndex: index,
                  extended: constraints.maxWidth >= 1180,
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
          bottomNavigationBar: _BottomNavigationSurface(
            selectedIndex: index,
            destinations: widget.destinations,
            onDestinationSelected: widget.onDestinationSelected,
          ),
        );
      },
    );
  }
}

class _AnimatedNavigationPage extends StatelessWidget {
  final int index;
  final int previousIndex;
  final Widget child;

  const _AnimatedNavigationPage({
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

class _BottomNavigationSurface extends StatelessWidget {
  final int selectedIndex;
  final List<AppNavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  const _BottomNavigationSurface({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(242),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: const Color(0xFF2A2A2A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(90),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              height: 68,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationRailSurface extends StatelessWidget {
  final int selectedIndex;
  final bool extended;
  final List<AppNavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  const _NavigationRailSurface({
    required this.selectedIndex,
    required this.extended,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: extended,
      minExtendedWidth: 210,
      backgroundColor: AppColors.surface,
      groupAlignment: -0.84,
      leading: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 18),
        child: _RailBrand(extended: extended),
      ),
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}

class _RailBrand extends StatelessWidget {
  final bool extended;

  const _RailBrand({required this.extended});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'fitai-navigation-brand',
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          const Text(
            'FitIA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}
