import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Passos.
class StepsDomainShowcasePage extends StatelessWidget {
  const StepsDomainShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DomainShowcaseScaffold(
      title: 'Passos',
      children: [
        FitStepsProgressRing(progress: .72, stepsLabel: '7.240'),
        FitStepsSummaryCard(
          stepsLabel: '7.240',
          progress: .72,
          metrics: [
            FitMetricData(label: 'Km', value: '5,3', icon: FitIcons.distance),
            FitMetricData(label: 'Kcal', value: '280', icon: FitIcons.calories),
          ],
        ),
        FitStepsMetricRow(
          metrics: [
            FitMetricData(
              label: 'Passos',
              value: '7.240',
              icon: FitIcons.steps,
            ),
            FitMetricData(label: 'Meta', value: '10.000', icon: FitIcons.goal),
          ],
        ),
        FitStepsGoalCard(value: '7.240 / 10.000', progress: .72),
        FitStepsWeeklyChartCard(
          points: [
            FitChartPoint(label: 'S', value: 6200),
            FitChartPoint(label: 'T', value: 8400),
            FitChartPoint(label: 'Q', value: 7240),
          ],
        ),
        FitStepsStreakCard(value: '8 dias'),
        FitStepsHistoryRow(
          dateLabel: 'Hoje',
          stepsLabel: '7.240',
          distanceLabel: '5,3 km',
        ),
        FitStepsRankingCard(
          positionLabel: '12º',
          stepsLabel: '42.180',
          description: 'Ranking semanal',
        ),
        FitStepsAchievementCard(
          data: FitAchievementDisplayData(
            title: '10 mil passos',
            description: 'Alcance a meta diária',
            icon: FitIcons.achievement,
            progress: .72,
          ),
        ),
        FitStepsSummaryCard(stepsLabel: '--', progress: 0, loading: true),
        DomainShowcaseStates(emptyTitle: 'Sem passos'),
      ],
    );
  }
}
