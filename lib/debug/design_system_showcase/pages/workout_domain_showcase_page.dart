import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes operacionais de Treino.
class WorkoutDomainShowcasePage extends StatelessWidget {
  const WorkoutDomainShowcasePage({super.key});

  static void _noop() {}

  static const _series = [
    FitSeriesDisplayData(
      index: 1,
      repetitions: '10',
      weight: 55,
      restLabel: '60s',
      completed: true,
    ),
    FitSeriesDisplayData(
      index: 2,
      repetitions: '12',
      weight: 55,
      restLabel: '60s',
      current: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DomainShowcaseScaffold(
      title: 'Treino',
      children: [
        const FitWorkoutHeader(
          title: 'Upper A',
          durationLabel: '48 min',
          onClose: _noop,
          onMore: _noop,
        ),
        const FitWorkoutProgressHeader(
          currentExercise: 2,
          totalExercises: 5,
          progress: .4,
        ),
        const FitExerciseMedia(),
        const FitExerciseHeader(
          name: 'Supino reto',
          muscleGroups: ['Peito', 'Tríceps', 'Ombros'],
          indexLabel: '2',
        ),
        const FitExerciseActionBar(
          actions: [
            FitGhostButton(
              label: 'Histórico',
              icon: FitIcons.history,
              onPressed: _noop,
            ),
            FitGhostButton(
              label: 'Ver GIF',
              icon: FitIcons.play,
              onPressed: _noop,
            ),
          ],
        ),
        const FitSeriesCounter(current: 2, total: 4),
        FitSeriesRow(data: _series[1], onTap: _noop),
        FitRepsSelector(value: 12, min: 1, max: 30, onChanged: (_) {}),
        FitWeightSelector(
          value: 55,
          min: 0,
          max: 200,
          step: 2.5,
          onChanged: (_) {},
        ),
        const FitRestTimerWidget(
          remainingLabel: '00:45',
          progress: .75,
          onTogglePause: _noop,
          onSkip: _noop,
          onAddTime: _noop,
        ),
        const FitExerciseRestScreenContent(
          title: 'Recupere-se',
          description: 'Próximo: remada baixa',
          timer: FitRestTimerWidget(remainingLabel: '00:45', progress: .75),
        ),
        const FitNextExerciseCard(
          name: 'Remada baixa',
          details: '4 séries · 10 repetições',
          onTap: _noop,
        ),
        const FitWorkoutMiniPlayer(
          title: 'Upper A',
          subtitle: 'Supino reto · Série 2',
          progress: .4,
          onTap: _noop,
          onTogglePause: _noop,
          onNext: _noop,
        ),
        const FitWorkoutCoachBubble(
          message: 'Mantenha a escápula estável nesta série.',
          actionLabel: 'Ver dica',
          onAction: _noop,
        ),
        const FitExerciseHistoryPreview(series: _series, onViewAll: _noop),
        const FitExerciseProgressPreview(
          points: [
            FitChartPoint(label: 'S1', value: 45),
            FitChartPoint(label: 'S2', value: 50),
            FitChartPoint(label: 'S3', value: 55),
          ],
          onViewDetails: _noop,
        ),
        const FitWorkoutSummaryCard(
          title: 'Upper A concluído',
          metrics: [
            FitMetricData(
              label: 'Tempo',
              value: '48',
              unit: 'min',
              icon: FitIcons.time,
            ),
            FitMetricData(
              label: 'Volume',
              value: '8.420',
              unit: 'kg',
              icon: FitIcons.weight,
            ),
          ],
        ),
        const FitWorkoutMetric(
          data: FitMetricData(
            label: 'Séries',
            value: '16',
            icon: FitIcons.repetitions,
          ),
        ),
        const FitPersonalRecordBadge(),
        const FitWorkoutXPCard(
          xpLabel: '+240 XP',
          progress: .72,
          nextLevelLabel: '280 XP para o nível 19',
        ),
        const FitWorkoutCompletionHeader(
          title: 'Treino concluído',
          message: 'Ótimo trabalho hoje.',
        ),
        const DomainShowcaseStates(emptyTitle: 'Treino sem dados'),
      ],
    );
  }
}
