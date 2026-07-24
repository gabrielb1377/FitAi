import 'package:flutter/material.dart';

import '../../../../core/xp/xp_config.dart';
import '../../../../design_system/fit_design_system.dart';
import '../../../../models/historico_treino_model.dart';
import '../states/home_state.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeOverviewPage extends StatefulWidget {
  const HomeOverviewPage({
    super.key,
    required this.state,
    required this.xp,
    required this.level,
    required this.onOpenGoals,
    required this.onOpenProgress,
    required this.onOpenRecords,
    required this.onOpenChallenges,
  });

  final HomeState state;
  final int xp;
  final int level;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenRecords;
  final VoidCallback onOpenChallenges;

  @override
  State<HomeOverviewPage> createState() => _HomeOverviewPageState();
}

class _HomeOverviewPageState extends State<HomeOverviewPage> {
  static const _periods = [1, 7, 30, 90];
  var _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final history = _filteredHistory();
    final seconds = history.fold<int>(
      0,
      (total, item) => total + item.tempoSegundos,
    );
    final calories = history.fold<int>(
      0,
      (total, item) => total + item.caloriasEstimadas,
    );
    final volume = history.fold<double>(
      0,
      (total, item) => total + item.volumeTotal,
    );
    final target = XpConfig.xpParaProximoNivel(widget.level);
    final current = XpConfig.normalizarXp(widget.xp).clamp(0, target).toInt();
    final progress = target <= 0 ? 0.0 : current / target;

    return HomeDetailScaffold(
      title: 'Visão geral',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.calendar,
          tooltip: 'Abrir desafios',
          onPressed: widget.onOpenChallenges,
        ),
      ],
      child: HomePageBody(
        children: [
          HomeFilterStrip(
            labels: const ['Hoje', '7 dias', '30 dias', '90 dias'],
            selectedIndex: _selectedPeriod,
            onSelected: (value) => setState(() => _selectedPeriod = value),
          ),
          const HomeSectionGap(),
          FitCard(
            variant: FitCardVariant.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: FitSpacing.s8,
                  runSpacing: FitSpacing.s4,
                  children: [
                    Text('Resumo geral', style: context.textTheme.titleLarge),
                    TextButton(
                      onPressed: widget.onOpenGoals,
                      child: const Text('Editar metas'),
                    ),
                  ],
                ),
                const SizedBox(height: FitSpacing.s12),
                HomeMetricGrid(
                  preferredColumns: 3,
                  embedded: true,
                  items: [
                    HomeMetricItem(
                      label: 'XP total',
                      value: homeFormatNumber(widget.xp),
                      icon: Icons.bolt_rounded,
                      detail: '+${widget.state.weeklyXp}',
                      color: FitColors.primary,
                    ),
                    HomeMetricItem(
                      label: 'Treinos',
                      value: '${history.length}',
                      icon: FitIcons.workout,
                      detail: '${widget.state.workoutsThisWeek} na semana',
                    ),
                    HomeMetricItem(
                      label: 'Tempo',
                      value: homeFormatDuration(seconds),
                      icon: FitIcons.time,
                      detail: '${_periods[_selectedPeriod]} dias',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s12),
          FitCard(
            onTap: widget.onOpenProgress,
            variant: FitCardVariant.clickable,
            semanticLabel:
                'Nível ${widget.level}, ${(progress * 100).round()} por cento',
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nível ${widget.level}',
                        style: context.textTheme.titleLarge,
                      ),
                      const SizedBox(height: FitSpacing.s8),
                      FitProgressBar(
                        value: progress.clamp(0, 1).toDouble(),
                        label: 'Próximo nível',
                        trailing: '$current / $target XP',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FitSpacing.s16),
                const Icon(
                  FitIcons.achievement,
                  color: FitColors.achievement,
                  size: FitLayout.iconSizeLarge,
                ),
              ],
            ),
          ),
          const HomeSectionGap(),
          FitSectionHeader(
            title: 'Métricas principais',
            onViewAll: widget.onOpenProgress,
            viewAllLabel: 'Ver todas',
          ),
          const SizedBox(height: FitSpacing.s12),
          HomeMetricGrid(
            items: [
              HomeMetricItem(
                label: 'Treinos concluídos',
                value: '${history.length}',
                icon: FitIcons.workout,
              ),
              HomeMetricItem(
                label: 'Tempo total',
                value: homeFormatDuration(seconds),
                icon: FitIcons.time,
              ),
              HomeMetricItem(
                label: 'Calorias',
                value: '${homeFormatNumber(calories)} kcal',
                icon: FitIcons.calories,
                color: FitColors.energy,
              ),
              HomeMetricItem(
                label: 'Volume total',
                value: '${homeFormatNumber(volume)} kg',
                icon: FitIcons.weight,
                color: FitColors.xp,
              ),
            ],
          ),
          const HomeSectionGap(),
          HomeChartCard(
            title: 'Evolução semanal',
            points: _weeklyPoints(history),
            semanticLabel: 'Treinos concluídos nos últimos sete dias',
          ),
          const HomeSectionGap(),
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = [
                HomeListAction(
                  title: 'Sequência atual',
                  subtitle: '${widget.state.currentStreak} dias',
                  icon: FitIcons.streak,
                  color: FitColors.achievement,
                  onTap: widget.onOpenChallenges,
                ),
                HomeListAction(
                  title: 'Recordes',
                  subtitle: 'Ver melhores marcas',
                  icon: FitIcons.achievement,
                  color: FitColors.achievement,
                  onTap: widget.onOpenRecords,
                ),
              ];
              if (constraints.maxWidth < FitBreakpoints.mobile) {
                return Column(
                  children: [
                    actions.first,
                    const SizedBox(height: FitSpacing.s8),
                    actions.last,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: actions.first),
                  const SizedBox(width: FitSpacing.s8),
                  Expanded(child: actions.last),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<HistoricoTreinoModel> _filteredHistory() {
    final threshold = DateTime.now().subtract(
      Duration(days: _periods[_selectedPeriod]),
    );
    return widget.state.history
        .where((item) => !item.dataHora.isBefore(threshold))
        .toList();
  }

  List<FitChartPoint> _weeklyPoints(List<HistoricoTreinoModel> history) {
    final now = DateTime.now();
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final count = history.where((item) {
        final date = item.dataHora.toLocal();
        return date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).length;
      return FitChartPoint(
        label: labels[day.weekday - 1],
        value: count.toDouble(),
      );
    });
  }
}
