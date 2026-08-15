import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class RecentActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const RecentActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class RecentActivity extends StatelessWidget {
  final List<RecentActivityItem> items;

  const RecentActivity({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return FitSection(
      title: 'Historico resumido',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length && index < 3; index++) ...[
            _RecentActivityRow(item: items[index]),
            if (index < items.length - 1 && index < 2) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  final RecentActivityItem item;

  const _RecentActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.title}: ${item.subtitle}',
      child: Row(
        children: [
          Icon(item.icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
