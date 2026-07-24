import 'package:flutter/material.dart';

import '../../../../core/xp/xp_config.dart';
import '../../../../design_system/fit_design_system.dart';
import '../../../../models/historico_treino_model.dart';
import '../states/home_state.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeProgressPage extends StatefulWidget {
  const HomeProgressPage({
    super.key,
    required this.state,
    required this.xp,
    required this.level,
  });

  final HomeState state;
  final int xp;
  final int level;

  @override
  State<HomeProgressPage> createState() => _HomeProgressPageState();
}

class _HomeProgressPageState extends State<HomeProgressPage> {
  static const _periods = [7, 30, 90];
  var _selected = 1;

  @override
  Widget build(BuildContext context) {
    final history = _history();
    final seconds = history.fold<int>(
      0,
      (total, item) => total + item.tempoSegundos,
    );
    final volume = history.fold<double>(
      0,
      (total, item) => total + item.volumeTotal,
    );
    final calories = history.fold<int>(
      0,
      (total, item) => total + item.caloriasEstimadas,
    );
    final target = XpConfig.xpParaProximoNivel(widget.level);
    final current = XpConfig.normalizarXp(widget.xp).clamp(0, target).toInt();
    final progress = target <= 0 ? 0.0 : current / target;
    return HomeDetailScaffold(
      title: 'Progresso rápido',
      subtitle: '',
      actions: [
        PopupMenuButton<int>(
          tooltip: 'Selecionar período',
          initialValue: _periods[_selected],
          onSelected: (value) {
            setState(() => _selected = _periods.indexOf(value));
          },
          itemBuilder: (_) => [
            for (final period in _periods)
              PopupMenuItem(value: period, child: Text('$period dias')),
          ],
          child: FitBadge(label: 'Últimos ${_periods[_selected]} dias'),
        ),
        const SizedBox(width: FitSpacing.s12),
      ],
      child: HomePageBody(
        children: [
          FitCard(
            variant: FitCardVariant.outlined,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('XP total', style: context.textTheme.labelMedium),
                      const SizedBox(height: FitSpacing.s4),
                      Text(
                        '${homeFormatNumber(widget.xp)} XP',
                        style: context.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: FitSpacing.s12),
                      FitProgressBar(
                        value: progress.clamp(0, 1).toDouble(),
                        label: '$target XP para o próximo nível',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FitSpacing.s16),
                FitCircularProgress(
                  value: progress.clamp(0, 1).toDouble(),
                  label: 'Nível ${widget.level}',
                  size: FitLayout.progressRingSize,
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s12),
          HomeMetricGrid(
            preferredColumns: 3,
            items: [
              HomeMetricItem(
                label: 'Treinos',
                value: '${history.length}',
                icon: FitIcons.workout,
                detail: '+${widget.state.workoutsThisWeek}',
              ),
              HomeMetricItem(
                label: 'Tempo',
                value: homeFormatDuration(seconds),
                icon: FitIcons.time,
                detail: 'período atual',
              ),
              HomeMetricItem(
                label: 'Volume',
                value: '${homeFormatNumber(volume)} kg',
                icon: FitIcons.weight,
                detail: 'total',
                color: FitColors.xp,
              ),
            ],
          ),
          const HomeSectionGap(),
          HomeChartCard(
            title: 'Volume total (kg)',
            subtitle: '${homeFormatNumber(volume)} no período',
            points: _points(history, (item) => item.volumeTotal),
            semanticLabel: 'Volume dos treinos por dia',
          ),
          const SizedBox(height: FitSpacing.s12),
          HomeChartCard(
            title: 'Calorias queimadas',
            subtitle: '${homeFormatNumber(calories)} kcal no período',
            points: _points(
              history,
              (item) => item.caloriasEstimadas.toDouble(),
            ),
            semanticLabel: 'Calorias queimadas por dia',
            color: FitColors.energy,
          ),
        ],
      ),
    );
  }

  List<HistoricoTreinoModel> _history() {
    final threshold = DateTime.now().subtract(
      Duration(days: _periods[_selected]),
    );
    return widget.state.history
        .where((item) => !item.dataHora.isBefore(threshold))
        .toList();
  }

  List<FitChartPoint> _points(
    List<HistoricoTreinoModel> history,
    double Function(HistoricoTreinoModel item) value,
  ) {
    if (history.isEmpty) return const [];
    final sorted = [...history]
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return [
      for (final item in sorted.take(8))
        FitChartPoint(
          label:
              '${item.dataHora.day.toString().padLeft(2, '0')}/${item.dataHora.month.toString().padLeft(2, '0')}',
          value: value(item),
        ),
    ];
  }
}
