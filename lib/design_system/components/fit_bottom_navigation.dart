import 'package:flutter/material.dart';

import '../tokens/fit_elevation.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Destino visual da navegacao principal; nao conhece rotas ou estado global.
class FitNavigationDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const FitNavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

/// Barra inferior FitIA controlada externamente.
class FitBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<FitNavigationDestination> destinations;
  final ValueChanged<int> onSelected;

  const FitBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0),
       assert(selectedIndex < destinations.length);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        FitSpacing.s12,
        0,
        FitSpacing.s12,
        FitSpacing.s8,
      ),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.largeBorder,
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: FitRadius.largeBorder,
            boxShadow: FitElevation.level2,
          ),
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _Destination(
                    destination: destinations[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  final FitNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _Destination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: FitRadius.mediumBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected
                      ? destination.selectedIcon ?? destination.icon
                      : destination.icon,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
