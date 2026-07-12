import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class ProfileSummary extends StatelessWidget {
  final String weight;
  final String height;
  final String bmi;
  final String activeDays;
  final String completedWorkouts;

  const ProfileSummary({
    super.key,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.activeDays,
    required this.completedWorkouts,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      FitMetric(
        label: 'Peso',
        value: weight,
        icon: Icons.monitor_weight_outlined,
      ),
      FitMetric(label: 'Altura', value: height, icon: Icons.height_rounded),
      FitMetric(
        label: 'IMC',
        value: bmi,
        icon: Icons.health_and_safety_outlined,
      ),
      FitMetric(
        label: 'Dias ativos',
        value: activeDays,
        icon: Icons.calendar_today_outlined,
      ),
      FitMetric(
        label: 'Treinos',
        value: completedWorkouts,
        icon: Icons.check_circle_outline_rounded,
      ),
    ];
    return FitSection(
      title: 'Resumo de evolucao',
      subtitle: 'O essencial da sua jornada',
      padding: EdgeInsets.zero,
      child: FitCard(
        variant: FitCardVariant.filled,
        elevation: 1,
        semanticLabel: 'Resumo de evolucao',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 5 : 2;
            final width =
                (constraints.maxWidth - FitSpacing.s16 * (columns - 1)) /
                columns;
            return Wrap(
              spacing: FitSpacing.s16,
              runSpacing: FitSpacing.s20,
              children: [
                for (final metric in metrics)
                  SizedBox(width: width, child: metric),
              ],
            );
          },
        ),
      ),
    );
  }
}
