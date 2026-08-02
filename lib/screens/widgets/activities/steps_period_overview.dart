import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../features/activities/domain/steps_metrics.dart';
import '../../../models/daily_steps_model.dart';

class StepsPeriodOverview extends StatelessWidget {
  const StepsPeriodOverview({
    super.key,
    required this.title,
    required this.summary,
    required this.streak,
    required this.comparisonWithYesterday,
  });

  final String title;
  final StepsPeriodSummary summary;
  final int streak;
  final int comparisonWithYesterday;

  @override
  Widget build(BuildContext context) {
    final comparison = comparisonWithYesterday == 0
        ? 'Igual a ontem'
        : comparisonWithYesterday > 0
        ? '+$comparisonWithYesterday vs. ontem'
        : '$comparisonWithYesterday vs. ontem';
    return FitCard(
      title: title,
      subtitle: 'Leitura local do período selecionado.',
      leading: const Icon(Icons.insights_outlined),
      child: Wrap(
        spacing: FitSpacing.s12,
        runSpacing: FitSpacing.s12,
        children: [
          _PeriodMetric(label: 'Total', value: '${summary.total} passos'),
          _PeriodMetric(label: 'Média', value: '${summary.average}/dia'),
          _PeriodMetric(
            label: 'Metas',
            value: '${summary.goalReachedDays} dias',
          ),
          _PeriodMetric(label: 'Sequência', value: '$streak dias'),
          _PeriodMetric(label: 'Melhor dia', value: _bestDay(summary.bestDay)),
          _PeriodMetric(label: 'Hoje', value: comparison),
        ],
      ),
    );
  }

  String _bestDay(DailyStepsModel? record) =>
      record == null ? 'Sem dados' : '${record.steps} passos';
}

/// Gráfico de barras com resumo semântico entregue pelo componente oficial.
class StepsPeriodChart extends StatelessWidget {
  const StepsPeriodChart({
    super.key,
    required this.records,
    required this.title,
  });

  final List<DailyStepsModel> records;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ordered = [...records]..sort((a, b) => a.date.compareTo(b.date));
    return FitStepsWeeklyChartCard(
      title: title,
      subtitle: 'Cada barra representa um resumo diário de passos.',
      points: [
        for (final record in ordered)
          FitChartPoint(
            label: _labelFor(record.date),
            value: record.steps.toDouble(),
          ),
      ],
    );
  }

  String _labelFor(String key) {
    final date = DateTime.tryParse(key);
    if (date == null) return key;
    return '${date.day}/${date.month}';
  }
}

class _PeriodMetric extends StatelessWidget {
  const _PeriodMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FitLayout.domainMetricMinWidth,
      child: Semantics(
        label: '$label: $value',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: FitSpacing.s4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
