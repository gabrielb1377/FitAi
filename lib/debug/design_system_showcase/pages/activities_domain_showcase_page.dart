import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Atividades.
class ActivitiesDomainShowcasePage extends StatelessWidget {
  const ActivitiesDomainShowcasePage({super.key});

  static void _noop() {}

  static const _metrics = [
    FitMetricData(
      label: 'Tempo',
      value: '48',
      unit: 'min',
      icon: FitIcons.time,
    ),
    FitMetricData(label: 'Calorias', value: '420', icon: FitIcons.calories),
  ];

  @override
  Widget build(BuildContext context) {
    return DomainShowcaseScaffold(
      title: 'Atividades',
      children: [
        const FitActivityCard(
          title: 'Corrida',
          subtitle: 'Última atividade',
          icon: FitIcons.running,
          onTap: _noop,
        ),
        const FitActivityCompactRow(
          title: 'Caminhada',
          subtitle: 'Hoje · 3,2 km',
          type: FitActivityType.walk,
          onTap: _noop,
        ),
        const Wrap(
          spacing: FitSpacing.s8,
          children: [
            FitActivityTypeChip(type: FitActivityType.strength),
            FitActivityTypeChip(type: FitActivityType.run, selected: true),
            FitActivityTypeChip(type: FitActivityType.steps),
          ],
        ),
        FitActivityMetric(data: _metrics[0]),
        const FitActivitySummaryCard(
          title: 'Resumo de hoje',
          type: FitActivityType.run,
          metrics: _metrics,
        ),
        const Wrap(
          spacing: FitSpacing.s8,
          children: [
            FitActivityCalendarDay(dayLabel: 'SEG', valueLabel: '10'),
            FitActivityCalendarDay(
              dayLabel: 'TER',
              valueLabel: '11',
              selected: true,
              completed: true,
            ),
          ],
        ),
        const FitActivityHistoryItem(
          title: 'Corrida matinal',
          type: FitActivityType.run,
          dateLabel: 'Hoje, 07:30',
          metrics: _metrics,
          onTap: _noop,
        ),
        FitActivityFilterBar(
          types: const [
            FitActivityType.strength,
            FitActivityType.run,
            FitActivityType.steps,
          ],
          selected: FitActivityType.run,
          onSelected: (_) {},
        ),
        const FitWeeklyActivityChartCard(
          points: [
            FitChartPoint(label: 'S', value: 2),
            FitChartPoint(label: 'T', value: 1),
            FitChartPoint(label: 'Q', value: 3),
          ],
        ),
        const FitActivityRecordCard(
          title: 'Maior distância',
          value: '10,2 km',
          description: 'Novo recorde mensal',
        ),
        const FitActivityEmptyState(),
        const FitActivitySummaryCard(
          title: 'Carregando',
          metrics: _metrics,
          loading: true,
        ),
        const DomainShowcaseStates(emptyTitle: 'Sem atividades'),
      ],
    );
  }
}
