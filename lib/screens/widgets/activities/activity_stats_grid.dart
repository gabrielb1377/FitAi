import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class ActivityStat {
  final String label;
  final String value;
  final IconData icon;

  const ActivityStat({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class ActivityStatsGrid extends StatelessWidget {
  final List<ActivityStat> items;

  const ActivityStatsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        final width =
            (constraints.maxWidth - FitSpacing.s16 * (columns - 1)) / columns;
        return Wrap(
          spacing: FitSpacing.s16,
          runSpacing: FitSpacing.s20,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: FitMetric(
                  label: item.label,
                  value: item.value,
                  icon: item.icon,
                ),
              ),
          ],
        );
      },
    );
  }
}
