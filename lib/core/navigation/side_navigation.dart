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
    return Container(
      width: 238,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(right: BorderSide(color: AppColors.outlineSoft)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 30,
            spreadRadius: -18,
            offset: const Offset(16, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RailBrand(),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: destinations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    return _SideNavigationItem(
                      label: destination.label,
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      selected: selectedIndex == index,
                      onTap: () => onDestinationSelected(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'fitai-navigation-brand',
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(34),
                  blurRadius: 22,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.black,
              size: 25,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FITAI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Performance OS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideNavigationItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SideNavigationItem> createState() => _SideNavigationItemState();
}

class _SideNavigationItemState extends State<_SideNavigationItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final foreground = active ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: active,
      label: widget.label,
      child: AnimatedScale(
        scale: _hovered && !active ? 1.015 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) {
              if (_hovered != hovered) setState(() => _hovered = hovered);
            },
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: AnimatedContainer(
              duration: AppMotion.normal,
              curve: AppMotion.curve,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: active ? AppColors.gradientCardSoft : null,
                color: active
                    ? null
                    : (_hovered
                          ? AppColors.surfaceElevated
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: active
                      ? AppColors.primary.withAlpha(84)
                      : (_hovered ? AppColors.outline : Colors.transparent),
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: AppColors.primary.withAlpha(20),
                      blurRadius: 24,
                      spreadRadius: -12,
                      offset: const Offset(0, 14),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    active ? widget.selectedIcon : widget.icon,
                    color: foreground,
                    size: active ? 23 : 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: active ? 1 : 0,
                    duration: AppMotion.fast,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
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
