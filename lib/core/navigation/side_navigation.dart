import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_router.dart';

class AppSideNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<AppRouteDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  const AppSideNavigation({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: true,
      minExtendedWidth: 210,
      backgroundColor: AppColors.surface,
      groupAlignment: -0.84,
      leading: const Padding(
        padding: EdgeInsets.only(top: 18, bottom: 18),
        child: _RailBrand(),
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
  const _RailBrand();

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
        const SizedBox(width: 12),
        const Text(
          'FITAI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
