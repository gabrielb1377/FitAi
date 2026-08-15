import 'package:flutter/material.dart';

import '../tokens/fit_duration.dart';
import '../tokens/fit_elevation.dart';
import '../tokens/fit_layout.dart';
import '../tokens/fit_opacity.dart';
import '../tokens/fit_radius.dart';
import '../tokens/fit_spacing.dart';

/// Destino visual da navegacao principal; nao conhece rotas ou estado global.
class FitNavigationDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget? badge;
  final String? badgeSemanticLabel;
  final bool enabled;

  const FitNavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.badgeSemanticLabel,
    this.enabled = true,
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
        FitLayout.none,
        FitSpacing.s12,
        FitSpacing.s8,
      ),
      child: SizedBox(
        height: FitLayout.navigationContentHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: FitRadius.largeBorder,
            boxShadow: FitElevation.level1,
          ),
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: FitRadius.largeBorder,
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: FitRadius.largeBorder,
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
    final enabled = destination.enabled;
    final color = !enabled
        ? colors.onSurfaceVariant.withValues(alpha: FitOpacity.disabled)
        : selected
        ? colors.primary
        : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: destination.label,
      hint: selected ? 'Aba selecionada' : 'Abrir aba',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: FitRadius.mediumBorder,
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s4),
          child: AnimatedContainer(
            duration: FitDuration.fast,
            curve: FitDuration.curve,
            constraints: const BoxConstraints(
              minHeight: FitLayout.minimumTouchTarget,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary.withValues(alpha: FitOpacity.selected)
                  : Colors.transparent,
              borderRadius: FitRadius.mediumBorder,
            ),
            padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected
                      ? FitLayout.navigationSelectedScale
                      : FitLayout.navigationUnselectedScale,
                  duration: FitDuration.fast,
                  curve: FitDuration.curve,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        selected
                            ? destination.selectedIcon ?? destination.icon
                            : destination.icon,
                        color: color,
                        size: FitLayout.iconSize,
                      ),
                      if (destination.badge != null)
                        Positioned(
                          top: -FitLayout.navigationBadgeOffsetTop,
                          right: -FitLayout.navigationBadgeOffsetEnd,
                          child: Semantics(
                            label: destination.badgeSemanticLabel,
                            child: destination.badge!,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: FitSpacing.s4),
                SizedBox(
                  height: FitLayout.navigationLabelHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: FitDuration.fast,
                      curve: FitDuration.curve,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      child: Text(destination.label, maxLines: 1),
                    ),
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
