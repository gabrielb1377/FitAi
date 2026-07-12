import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class ProfileSettingsItem {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const ProfileSettingsItem({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}

class ProfileSettingsGroup {
  final String title;
  final List<ProfileSettingsItem> items;

  const ProfileSettingsGroup({required this.title, required this.items});
}

class ProfileSettings extends StatelessWidget {
  final List<ProfileSettingsGroup> groups;

  const ProfileSettings({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final group in groups) ...[
          FitSection(
            title: group.title,
            padding: EdgeInsets.zero,
            child: FitCard(
              variant: FitCardVariant.outlined,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < group.items.length; index++) ...[
                    _SettingsRow(item: group.items[index]),
                    if (index < group.items.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
          if (group != groups.last) const SizedBox(height: FitSpacing.s24),
        ],
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final ProfileSettingsItem item;

  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${item.label}. ${item.description}',
      child: ListTile(
        minVerticalPadding: FitSpacing.s8,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s16,
          vertical: FitSpacing.s4,
        ),
        onTap: item.onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: FitRadius.mediumBorder,
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, color: colors.secondary),
        ),
        title: Text(item.label),
        subtitle: Text(
          item.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Tooltip(
          message: 'Abrir',
          child: Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
