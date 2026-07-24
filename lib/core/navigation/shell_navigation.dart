import 'package:flutter/material.dart';

import '../../design_system/components/fit_bottom_navigation.dart';
import 'app_section.dart';

/// Bottom Navigation oficial do shell.
class ShellNavigation extends StatelessWidget {
  const ShellNavigation({
    super.key,
    required this.selectedSection,
    required this.onSelected,
  });

  final AppShellSection selectedSection;
  final ValueChanged<AppShellSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return FitBottomNavigation(
      selectedIndex: selectedSection.index,
      onSelected: (index) {
        final section = AppShellSection.fromIndex(index);
        if (section != null) onSelected(section);
      },
      destinations: [
        for (final section in AppShellSection.values)
          FitNavigationDestination(
            label: section.label,
            icon: section.icon,
            selectedIcon: section.selectedIcon,
          ),
      ],
    );
  }
}
