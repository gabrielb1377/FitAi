import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../states/home_state.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeDailySummaryPage extends StatelessWidget {
  const HomeDailySummaryPage({
    super.key,
    required this.state,
    required this.steps,
    required this.distance,
    required this.onOpenOverview,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final HomeState state;
  final int steps;
  final double distance;
  final VoidCallback onOpenOverview;
  final DateTime Function() _now;

  @override
  Widget build(BuildContext context) {
    final now = _now();
    final workoutToday = state.history.any((item) {
      final date = item.dataHora.toLocal();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    });
    return HomeDetailScaffold(
      title: 'Resumo diário',
      subtitle: '',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: FitSpacing.s12),
          child: Icon(
            FitIcons.calendar,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: FitLayout.iconSizeCompact,
          ),
        ),
      ],
      child: HomePageBody(
        children: [
          Row(
            children: [
              Icon(
                Icons.chevron_left_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: Text(
                  _longDate(now),
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          FitCard(
            title: 'Seu dia em resumo',
            variant: FitCardVariant.outlined,
            trailing: const FitCircularProgress(
              value: 1,
              label: 'Hoje',
              size: FitLayout.progressRingSize,
            ),
            child: Text(
              workoutToday
                  ? 'Você manteve sua rotina de treino hoje. Continue acompanhando sua recuperação.'
                  : 'Seu dia ainda está em andamento. Pequenas ações ajudam a manter a consistência.',
              style: context.textTheme.bodyMedium,
            ),
          ),
          const HomeSectionGap(),
          const FitSectionHeader(title: 'Insights principais'),
          const SizedBox(height: FitSpacing.s12),
          HomeListAction(
            title: 'Consistência',
            subtitle: '${state.currentStreak} dias de sequência',
            icon: FitIcons.progress,
            onTap: onOpenOverview,
          ),
          const SizedBox(height: FitSpacing.s8),
          HomeListAction(
            title: 'Desempenho',
            subtitle:
                '${state.workoutsThisWeek} treinos e ${state.weeklyXp} XP nesta semana',
            icon: Icons.bar_chart_rounded,
            color: FitColors.info,
            onTap: onOpenOverview,
          ),
          const SizedBox(height: FitSpacing.s8),
          HomeListAction(
            title: 'Recuperação',
            subtitle: workoutToday
                ? 'Priorize sono e hidratação após o treino'
                : 'Seu corpo está pronto para uma nova atividade',
            icon: Icons.bedtime_outlined,
            color: FitColors.xp,
          ),
          const SizedBox(height: FitSpacing.s8),
          HomeListAction(
            title: 'Movimento',
            subtitle:
                '${homeFormatNumber(steps)} passos · ${distance.toStringAsFixed(1)} km',
            icon: FitIcons.steps,
            color: FitColors.steps,
          ),
          const HomeSectionGap(),
          const FitSectionHeader(title: 'O que focar amanhã'),
          const SizedBox(height: FitSpacing.s12),
          HomeListAction(
            title: state.selection.treino?.nome ?? 'Recuperação ativa',
            subtitle:
                state.recommendation?.texto ??
                'Mantenha a rotina e respeite os sinais do seu corpo.',
            icon: FitIcons.coach,
            color: FitColors.ai,
          ),
          const SizedBox(height: FitSpacing.s16),
          FitOutlinedButton(
            label: 'Ver relatório completo',
            icon: FitIcons.progress,
            fullWidth: true,
            onPressed: onOpenOverview,
          ),
        ],
      ),
    );
  }

  String _longDate(DateTime value) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${value.day} de ${months[value.month - 1]} de ${value.year}';
  }
}
