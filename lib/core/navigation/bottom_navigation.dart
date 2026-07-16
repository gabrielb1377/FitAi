import 'package:flutter/material.dart';

import '../../design_system/components/fit_bottom_navigation.dart';
import '../app_router.dart';

/// Fachada legada para consumidores que ainda importam a navegacao antiga.
///
/// A shell oficial usa [FitBottomNavigation] diretamente. Este wrapper preserva
/// o contrato anterior sem manter duas implementacoes visuais em paralelo.
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
    return FitBottomNavigation(
      selectedIndex: selectedIndex,
      onSelected: onDestinationSelected,
      destinations: [
        for (final destination in destinations)
          FitNavigationDestination(
            label: destination.label,
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
          ),
      ],
    );
  }
}
