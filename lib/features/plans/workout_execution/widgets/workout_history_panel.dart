import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/exercise_history_model.dart';
import '../../../../models/historico_serie_treino_model.dart';

enum WorkoutHistoryMetric { sets, load, volume }

/// WORK-009. Histórico offline-first do exercício atual.
///
/// A superfície combina registros persistidos com as séries ainda não
/// finalizadas da sessão, sem misturar identidades de exercícios substituídos.
class WorkoutExerciseHistoryPanel extends StatefulWidget {
  const WorkoutExerciseHistoryPanel({
    super.key,
    required this.exercise,
    required this.history,
    this.sessionSeries = const [],
    this.currentSessionId,
  });

  final ExercicioModel exercise;
  final Future<ExerciseHistorySnapshot> history;
  final List<HistoricoSerieTreinoModel> sessionSeries;
  final String? currentSessionId;

  @override
  State<WorkoutExerciseHistoryPanel> createState() =>
      _WorkoutExerciseHistoryPanelState();
}

class _WorkoutExerciseHistoryPanelState
    extends State<WorkoutExerciseHistoryPanel> {
  WorkoutHistoryMetric _metric = WorkoutHistoryMetric.sets;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExerciseHistorySnapshot>(
      future: widget.history,
      builder: (context, snapshot) {
        final executions = _mergeExecutions(snapshot.data);
        final previousExecutions = executions
            .where((execution) => execution.id != _currentSessionId)
            .toList(growable: false);
        final previousPerformance = previousExecutions.isEmpty
            ? null
            : previousExecutions.first;
        final loading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExerciseIdentity(exercise: widget.exercise),
            const SizedBox(height: FitSpacing.s16),
            _MetricSelector(
              selected: _metric,
              onSelected: (metric) => setState(() => _metric = metric),
            ),
            const SizedBox(height: FitSpacing.s16),
            if (loading && executions.isEmpty)
              const Column(
                children: [
                  FitSkeleton(height: 72),
                  SizedBox(height: FitSpacing.s8),
                  FitSkeleton(height: 72),
                  SizedBox(height: FitSpacing.s8),
                  FitSkeleton(height: 72),
                ],
              )
            else if (snapshot.hasError && executions.isEmpty)
              const FitErrorState(
                error:
                    'Não foi possível carregar o histórico neste dispositivo.',
              )
            else if (executions.isEmpty)
              const FitEmptyState(
                icon: Icons.history_rounded,
                title: 'Nenhuma série registrada ainda',
                description:
                    'As séries concluídas deste exercício aparecerão aqui.',
              )
            else ...[
              _HistorySummary(executions: executions),
              const SizedBox(height: FitSpacing.s12),
              if (previousPerformance != null) ...[
                _PreviousPerformance(execution: previousPerformance),
                const SizedBox(height: FitSpacing.s12),
              ],
              for (var index = 0; index < executions.length; index++) ...[
                _ExecutionCard(
                  execution: executions[index],
                  metric: _metric,
                  isCurrentSession: executions[index].id == _currentSessionId,
                ),
                if (index < executions.length - 1)
                  const SizedBox(height: FitSpacing.s8),
              ],
              if (snapshot.hasError) ...[
                const SizedBox(height: FitSpacing.s12),
                Text(
                  'Exibindo somente os dados disponíveis nesta sessão.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  String get _currentSessionId {
    final explicit = widget.currentSessionId?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    if (widget.sessionSeries.isEmpty) return '';
    return widget.sessionSeries.first.sessaoTreinoId;
  }

  List<ExerciseExecution> _mergeExecutions(ExerciseHistorySnapshot? snapshot) {
    final persisted = snapshot?.executions ?? const <ExerciseExecution>[];
    if (widget.sessionSeries.isEmpty) return persisted;

    final sessionId = _currentSessionId;
    final series = [...widget.sessionSeries]
      ..sort((a, b) => a.serieNumero.compareTo(b.serieNumero));
    final latest = series
        .map((entry) => entry.dataHora)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final current = ExerciseExecution(
      id: sessionId,
      exerciseId: widget.exercise.id,
      exerciseKey: series.first.chaveExercicio,
      exerciseName: widget.exercise.nome,
      workoutId: series.first.treinoId,
      workoutName: series.first.nomeTreino,
      date: latest,
      sets: series,
    );

    return [
      current,
      ...persisted.where((execution) => execution.id != sessionId),
    ];
  }
}

class _PreviousPerformance extends StatelessWidget {
  const _PreviousPerformance({required this.execution});

  final ExerciseExecution execution;

  @override
  Widget build(BuildContext context) => FitCard(
    variant: FitCardVariant.outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance anterior · ${_date(execution.date)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: FitSpacing.s8),
        for (var index = 0; index < execution.sets.length; index++) ...[
          Text(
            'Série ${index + 1}  ·  ${_number(execution.sets[index].peso)} kg × ${execution.sets[index].repeticoes} reps',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (index < execution.sets.length - 1)
            const SizedBox(height: FitSpacing.s4),
        ],
      ],
    ),
  );
}

class _ExerciseIdentity extends StatelessWidget {
  const _ExerciseIdentity({required this.exercise});

  final ExercicioModel exercise;

  @override
  Widget build(BuildContext context) {
    final muscles = <String>{
      ...exercise.musculos.where((item) => item.trim().isNotEmpty),
      ...exercise.musculosSecundarios.where((item) => item.trim().isNotEmpty),
    }.take(2).join(' · ');

    return Row(
      children: [
        Container(
          width: FitLayout.avatarMedium,
          height: FitLayout.avatarMedium,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: FitColors.primaryContainer,
            borderRadius: FitRadius.mediumBorder,
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: FitColors.primary,
          ),
        ),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: FitSpacing.s2),
              Text(
                muscles.isEmpty ? exercise.categoria : muscles,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.selected, required this.onSelected});

  final WorkoutHistoryMetric selected;
  final ValueChanged<WorkoutHistoryMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final metric in WorkoutHistoryMetric.values) ...[
          if (metric != WorkoutHistoryMetric.values.first)
            const SizedBox(width: FitSpacing.s8),
          Expanded(
            child: FitFilterChip(
              label: _label(metric),
              selected: selected == metric,
              onSelected: (_) => onSelected(metric),
            ),
          ),
        ],
      ],
    );
  }

  String _label(WorkoutHistoryMetric value) => switch (value) {
    WorkoutHistoryMetric.sets => 'Séries',
    WorkoutHistoryMetric.load => 'Carga',
    WorkoutHistoryMetric.volume => 'Volume',
  };
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.executions});

  final List<ExerciseExecution> executions;

  @override
  Widget build(BuildContext context) {
    final sets = executions.expand((execution) => execution.sets).toList();
    final maxLoad = sets.fold<double>(
      0,
      (value, set) => set.peso > value ? set.peso : value,
    );
    final totalVolume = executions.fold<double>(
      0,
      (value, execution) => value + execution.volume,
    );

    return Row(
      children: [
        Expanded(
          child: FitStatistic(
            label: 'Sessões',
            value: '${executions.length}',
            icon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(width: FitSpacing.s8),
        Expanded(
          child: FitStatistic(
            label: 'Maior carga',
            value: _number(maxLoad),
            unit: 'kg',
            icon: Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: FitSpacing.s8),
        Expanded(
          child: FitStatistic(
            label: 'Volume',
            value: _number(totalVolume),
            unit: 'kg',
            icon: Icons.stacked_line_chart_rounded,
          ),
        ),
      ],
    );
  }
}

class _ExecutionCard extends StatelessWidget {
  const _ExecutionCard({
    required this.execution,
    required this.metric,
    required this.isCurrentSession,
  });

  final ExerciseExecution execution;
  final WorkoutHistoryMetric metric;
  final bool isCurrentSession;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      borderColor: isCurrentSession ? FitColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isCurrentSession ? 'Sessão atual' : _date(execution.date),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (isCurrentSession) const FitStatusChip(label: 'Em andamento'),
            ],
          ),
          const SizedBox(height: FitSpacing.s8),
          if (metric == WorkoutHistoryMetric.sets)
            for (var index = 0; index < execution.sets.length; index++) ...[
              _SetRow(set: execution.sets[index]),
              if (index < execution.sets.length - 1)
                const SizedBox(height: FitSpacing.s4),
            ]
          else
            _MetricValue(
              label: metric == WorkoutHistoryMetric.load
                  ? 'Melhor carga'
                  : 'Volume da sessão',
              value: metric == WorkoutHistoryMetric.load
                  ? '${_number(execution.bestSet?.peso ?? 0)} kg'
                  : '${_number(execution.volume)} kg',
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.set});

  final HistoricoSerieTreinoModel set;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: FitSpacing.s24,
          child: Text(
            '${set.serieNumero}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: FitColors.primary),
          ),
        ),
        Expanded(
          child: Text(
            '${_number(set.peso)} kg × ${set.repeticoes} reps',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '${set.descansoSegundos}s',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MetricValue extends StatelessWidget {
  const _MetricValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _number(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
