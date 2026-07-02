import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_router.dart';

class AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<AppRouteDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavigation({
    super.key,
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
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: onDestinationSelected,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: [
                for (final destination in destinations)
                  BottomNavigationBarItem(
                    icon: Icon(destination.icon),
                    activeIcon: Icon(destination.selectedIcon),
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
