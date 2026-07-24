import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Corridas.
class RunningDomainShowcasePage extends StatelessWidget {
  const RunningDomainShowcasePage({super.key});

  static void _noop() {}

  static const _metrics = [
    FitMetricData(
      label: 'Distância',
      value: '5,2',
      unit: 'km',
      icon: FitIcons.distance,
    ),
    FitMetricData(
      label: 'Pace',
      value: '5:28',
      unit: '/km',
      icon: FitIcons.pace,
    ),
    FitMetricData(label: 'Tempo', value: '28:26', icon: FitIcons.time),
  ];

  @override
  Widget build(BuildContext context) {
    return DomainShowcaseScaffold(
      title: 'Corridas',
      children: [
        const FitRunningDashboardCard(
          title: 'Última corrida',
          subtitle: 'Hoje, 07:30',
          metrics: _metrics,
        ),
        FitRunMetric(data: _metrics[0]),
        const FitRunLiveMetricGrid(metrics: _metrics),
        const FitRunMapContainer(),
        const Wrap(
          spacing: FitSpacing.s8,
          runSpacing: FitSpacing.s8,
          children: [
            FitGPSStatus(state: FitGPSState.connecting),
            FitGPSStatus(state: FitGPSState.connected),
            FitGPSStatus(state: FitGPSState.weak),
            FitGPSStatus(state: FitGPSState.unavailable),
          ],
        ),
        const FitRunControlBar(active: false, onStart: _noop),
        const FitRunControlBar(
          active: true,
          onTogglePause: _noop,
          onFinish: _noop,
        ),
        const FitRunPausePanel(durationLabel: '28:26', onResume: _noop),
        const FitRunSummaryCard(title: 'Corrida concluída', metrics: _metrics),
        const FitPaceChartCard(
          points: [
            FitChartPoint(label: '1', value: 5.6),
            FitChartPoint(label: '2', value: 5.3),
            FitChartPoint(label: '3', value: 5.1),
          ],
        ),
        const FitHeartRateZoneCard(
          zoneLabel: 'Zona 3',
          valueLabel: '18 min',
          progress: .62,
          description: 'Aeróbico',
        ),
        const FitSplitRow(
          label: 'Km 1',
          paceLabel: '5:28/km',
          durationLabel: '5:28',
        ),
        const FitRouteCard(
          title: 'Parque Central',
          subtitle: 'Rota circular',
          metrics: _metrics,
          onTap: _noop,
        ),
        const FitIntervalStepCard(
          title: 'Corrida forte',
          durationLabel: '02:00',
          description: 'Etapa 2 de 6',
          current: true,
        ),
        const FitPersonalRunRecordCard(title: 'Melhor 5 km', value: '25:18'),
        const FitRunningDashboardCard(
          title: 'Carregando corridas',
          metrics: _metrics,
          loading: true,
        ),
        const DomainShowcaseStates(emptyTitle: 'Sem corridas'),
      ],
    );
  }
}
