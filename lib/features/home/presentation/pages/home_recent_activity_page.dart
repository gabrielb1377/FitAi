import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/historico_treino_model.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

enum HomeActivityFilter { all, workout, cardio, steps }

class HomeRecentActivityPage extends StatefulWidget {
  const HomeRecentActivityPage({
    super.key,
    required this.history,
    required this.steps,
    required this.distance,
    required this.onOpenWorkout,
    required this.onOpenRunning,
    required this.onOpenSteps,
  });

  final List<HistoricoTreinoModel> history;
  final int steps;
  final double distance;
  final ValueChanged<HistoricoTreinoModel> onOpenWorkout;
  final VoidCallback onOpenRunning;
  final VoidCallback onOpenSteps;

  @override
  State<HomeRecentActivityPage> createState() => _HomeRecentActivityPageState();
}

class _HomeRecentActivityPageState extends State<HomeRecentActivityPage> {
  var _filter = HomeActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final items = _items().where(_matches).toList();
    return HomeDetailScaffold(
      title: 'Atividade recente',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: Icons.filter_list_rounded,
          tooltip: 'Filtrar atividades',
          onPressed: () => setState(() {
            _filter = _filter == HomeActivityFilter.all
                ? HomeActivityFilter.workout
                : HomeActivityFilter.all;
          }),
        ),
      ],
      child: HomePageBody(
        children: [
          HomeFilterStrip(
            labels: const ['Todas', 'Treino', 'Cardio', 'Passos'],
            selectedIndex: _filter.index,
            onSelected: (value) {
              setState(() => _filter = HomeActivityFilter.values[value]);
            },
          ),
          const SizedBox(height: FitSpacing.s16),
          if (items.isEmpty)
            const FitEmptyState(
              icon: FitIcons.history,
              title: 'Nenhuma atividade encontrada',
              description:
                  'Suas atividades registradas aparecerão nesta linha do tempo.',
            )
          else
            for (final item in items) ...[
              _ActivityCard(item: item),
              const SizedBox(height: FitSpacing.s8),
            ],
        ],
      ),
    );
  }

  List<_ActivityItem> _items() {
    final items = <_ActivityItem>[
      for (final history in widget.history)
        _ActivityItem(
          title: history.nomeTreino,
          subtitle:
              '${history.objetivo} · ${history.exerciciosConcluidos} exercícios · ${history.tempoFormatado}',
          value: '+${history.xpGanho} XP',
          date: history.dataHora,
          icon: FitIcons.workout,
          type: HomeActivityFilter.workout,
          onTap: () => widget.onOpenWorkout(history),
        ),
      if (widget.distance > 0)
        _ActivityItem(
          title: 'Corrida ao ar livre',
          subtitle: '${widget.distance.toStringAsFixed(1)} km registrados',
          value: 'Cardio',
          date: DateTime.now(),
          icon: FitIcons.running,
          color: FitColors.running,
          type: HomeActivityFilter.cardio,
          onTap: widget.onOpenRunning,
        ),
      if (widget.steps > 0)
        _ActivityItem(
          title: '${homeFormatNumber(widget.steps)} passos',
          subtitle: 'Movimentação de hoje',
          value: 'Hoje',
          date: DateTime.now(),
          icon: FitIcons.steps,
          color: FitColors.steps,
          type: HomeActivityFilter.steps,
          onTap: widget.onOpenSteps,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  bool _matches(_ActivityItem item) =>
      _filter == HomeActivityFilter.all || item.type == _filter;
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.date,
    required this.icon,
    required this.type,
    required this.onTap,
    this.color,
  });

  final String title;
  final String subtitle;
  final String value;
  final DateTime date;
  final IconData icon;
  final HomeActivityFilter type;
  final VoidCallback onTap;
  final Color? color;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return HomeListAction(
      title: item.title,
      subtitle: '${item.subtitle}\n${homeFormatDate(item.date)}',
      value: item.value,
      icon: item.icon,
      color: item.color,
      onTap: item.onTap,
    );
  }
}
