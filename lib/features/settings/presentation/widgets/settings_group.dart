import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class SettingsGroupItem {
  const SettingsGroupItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.items});

  final String title;
  final List<SettingsGroupItem> items;

  @override
  Widget build(BuildContext context) {
    return FitSection(
      title: title,
      child: FitCard(
        variant: FitCardVariant.outlined,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              FitActionTile(
                title: items[index].title,
                description: items[index].description,
                icon: items[index].icon,
                destructive: items[index].destructive,
                onTap: items[index].onTap,
              ),
              if (index < items.length - 1) const FitDivider(),
            ],
          ],
        ),
      ),
    );
  }
}
