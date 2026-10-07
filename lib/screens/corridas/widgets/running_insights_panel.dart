import 'package:flutter/material.dart';
import '../../../core/auth/local_account_data_boundary.dart';
import '../../../design_system/fit_design_system.dart';
import '../../../features/activities/data/running_metrics_repository.dart';
import '../../../features/activities/domain/running_metrics.dart';
import '../../../models/corrida_model.dart';

/// Compact read-only metrics within the existing run screen/detail.
class RunningInsightsPanel extends StatefulWidget {
  const RunningInsightsPanel({
    super.key,
    required this.run,
    this.showSummary = false,
  });
  final CorridaModel run;
  final bool showSummary;
  @override
  State<RunningInsightsPanel> createState() => _RunningInsightsPanelState();
}

class _RunningInsightsPanelState extends State<RunningInsightsPanel> {
  static const _repository = RunningMetricsRepository();
  late Future<(RunningPostRunSummary?, List<CorridaModel>)> _future;
  @override
  void initState() {
    super.initState();
    _reload();
    AccountSessionLifecycle.revision.addListener(_accountChanged);
  }

  @override
  void didUpdateWidget(RunningInsightsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run != widget.run) _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<(RunningPostRunSummary?, List<CorridaModel>)> _load() async {
    final summary = await _repository.summary(widget.run);
    return (summary, await _repository.history());
  }

  void _accountChanged() => setState(_reload);
  @override
  void dispose() {
    AccountSessionLifecycle.revision.removeListener(_accountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const FitCard(
          variant: FitCardVariant.outlined,
          child: Text('Métricas locais indisponíveis no momento.'),
        );
      }
      final data = snapshot.data;
      final summary = data?.$1;
      if (summary == null ||
          widget.run.userId != _repository.userId ||
          summary.run.userId != _repository.userId ||
          summary.run.id != widget.run.id) {
        return const SizedBox.shrink();
      }
      final reference = DateTime.tryParse(
        widget.run.endTime ?? widget.run.data,
      );
      final weekly = reference == null
          ? null
          : _repository.metrics.weekly(data!.$2, _repository.userId, reference);
      final monthly = reference == null
          ? null
          : _repository.metrics.monthly(
              data!.$2,
              _repository.userId,
              reference,
            );
      return FitCard(
        variant: FitCardVariant.outlined,
        title: widget.showSummary ? 'Resumo da corrida' : 'Evolução',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showSummary) ...[
              Text(
                '${summary.distanceKm.toStringAsFixed(2)} km · '
                '${summary.activeSeconds}s ativos · '
                '${_pace(summary.averagePaceSecondsPerKm)}',
              ),
              Text('${summary.splits.length} trechos registrados'),
              const SizedBox(height: FitSpacing.s12),
            ],
            if (summary.recordsAchieved.isEmpty)
              const Text('Sem novo recorde nesta corrida.'),
            for (final record in summary.recordsAchieved)
              Text('${_recordLabel(record.type)}: ${_recordValue(record)}'),
            if (summary.comparison case final comparison?) ...[
              const SizedBox(height: FitSpacing.s12),
              Text(
                'Versus corrida anterior de distância semelhante: '
                '${comparison.distanceDeltaKm.toStringAsFixed(2)} km · '
                '${comparison.paceDeltaSecondsPerKm.abs().toStringAsFixed(0)} s/km '
                '${comparison.paceDeltaSecondsPerKm <= 0 ? 'mais rápido' : 'mais lento'}',
              ),
            ],
            const SizedBox(height: FitSpacing.s12),
            if (weekly != null) Text(_period('Semana da corrida', weekly)),
            if (monthly != null) Text(_period('Mês da corrida', monthly)),
            const SizedBox(height: FitSpacing.s12),
            const Text(
              'Elevação indisponível: qualidade altimétrica não validada.',
            ),
          ],
        ),
      );
    },
  );

  String _period(String label, RunningPeriodMetrics value) =>
      '$label: ${value.numberOfRuns} corridas · '
      '${value.totalDistanceKm.toStringAsFixed(2)} km · '
      '${value.totalActiveSeconds}s · ${_pace(value.averagePaceSecondsPerKm)}';
  String _pace(double? seconds) => seconds == null
      ? 'Ritmo indisponível'
      : '${seconds.round() ~/ 60}:${(seconds.round() % 60).toString().padLeft(2, '0')} min/km';
  String _recordValue(RunningPersonalRecord record) => switch (record.type) {
    RunningRecordType.longestDistance =>
      '${record.value.toStringAsFixed(2)} km',
    RunningRecordType.bestAveragePace => _pace(record.value),
    _ =>
      '${record.value.round() ~/ 60}:${(record.value.round() % 60).toString().padLeft(2, '0')}',
  };
  String _recordLabel(RunningRecordType type) => switch (type) {
    RunningRecordType.fastest1K => 'Melhor 1 km (parciais completas)',
    RunningRecordType.fastest5K => 'Melhor 5 km (parciais completas)',
    RunningRecordType.fastest10K => 'Melhor 10 km (parciais completas)',
    RunningRecordType.longestDistance => 'Maior distância',
    RunningRecordType.bestAveragePace => 'Melhor ritmo médio',
  };
}
