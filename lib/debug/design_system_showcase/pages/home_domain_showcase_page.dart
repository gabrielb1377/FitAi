import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes de domínio da Home.
class HomeDomainShowcasePage extends StatelessWidget {
  const HomeDomainShowcasePage({super.key});

  static void _noop() {}

  static const _metrics = [
    FitMetricData(label: 'Passos', value: '8.420', icon: FitIcons.steps),
    FitMetricData(label: 'Treinos', value: '4', icon: FitIcons.workout),
    FitMetricData(label: 'Corridas', value: '2', icon: FitIcons.running),
  ];

  @override
  Widget build(BuildContext context) {
    return DomainShowcaseScaffold(
      title: 'Home',
      children: [
        const FitGreetingHeader(
          greeting: 'Bom dia',
          name: 'Gabriel',
          contextLabel: 'Nível 18 · 2.450 XP',
        ),
        const FitDailySummaryCard(metrics: _metrics),
        FitTodayWorkoutCard(
          title: 'Upper A',
          subtitle:
              'Treino de hoje com uma descrição longa para validar escalonamento de texto.',
          actionLabel: 'Continuar treino',
          onAction: _noop,
          metrics: _metrics.take(2).toList(),
          progress: .42,
        ),
        const FitQuickStatsRow(metrics: _metrics),
        const FitQuickActionCard(
          label: 'Biblioteca',
          description: 'Encontre exercícios',
          icon: FitIcons.library,
          onTap: _noop,
        ),
        const FitCoachInsightCard(
          title: 'Coach FitIA',
          insight: 'Sua recuperação está adequada para o treino planejado.',
          actionLabel: 'Ver insight',
          onAction: _noop,
        ),
        const FitStreakCard(value: '12 dias', bestLabel: 'Melhor: 18 dias'),
        const FitDailyGoalCard(
          title: 'Meta principal',
          value: '68%',
          progress: .68,
          description: 'Reduzir gordura corporal',
        ),
        const FitRecentActivityCard(
          title: 'Corrida matinal',
          subtitle: '5,2 km · 28 min',
          icon: FitIcons.running,
          onTap: _noop,
        ),
        const FitNotificationPreview(
          title: 'Treino atualizado',
          message: 'Seu plano foi ajustado pelo Coach.',
          timeLabel: 'Agora',
          unread: true,
          onTap: _noop,
        ),
        const FitHomeSectionHeader(
          title: 'Atividades recentes',
          subtitle: 'Resumo da semana',
          onViewAll: _noop,
        ),
        const FitDashboardCustomizerTile(
          title: 'Coach FitIA',
          subtitle: 'Mostrar insight diário',
          enabled: true,
          onChanged: _ignoreBool,
        ),
        const FitDailySummaryCard(metrics: _metrics, loading: true),
        const DomainShowcaseStates(emptyTitle: 'Home vazia'),
      ],
    );
  }
}

void _ignoreBool(bool _) {}
