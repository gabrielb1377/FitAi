import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Perfil.
class ProfileDomainShowcasePage extends StatelessWidget {
  const ProfileDomainShowcasePage({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    const achievement = FitAchievementDisplayData(
      title: 'Primeira semana',
      description: 'Complete sete dias ativos',
      icon: FitIcons.achievement,
      progress: .72,
    );
    return const DomainShowcaseScaffold(
      title: 'Perfil',
      children: [
        FitProfileHeader(
          name: 'Gabriel',
          subtitle: 'Nível 18',
          badge: FitLevelBadge(label: '2.450 XP'),
        ),
        FitProfileAvatar(name: 'Gabriel', onTap: _noop),
        FitLevelBadge(label: 'Nível 18'),
        FitXPProgressCard(
          xpLabel: '2.450 XP',
          progress: .72,
          nextLevelLabel: '280 XP para o nível 19',
        ),
        FitAchievementCard(data: achievement, onTap: _noop),
        FitAchievementBadge(unlocked: true),
        FitBodyMetricCard(
          data: FitMetricData(
            label: 'Peso',
            value: '78,4',
            unit: 'kg',
            icon: FitIcons.weight,
          ),
        ),
        FitWeightProgressCard(
          valueLabel: '78,4 kg',
          progress: .64,
          description: '-1,2 kg no período',
          points: [
            FitChartPoint(label: 'S1', value: 80),
            FitChartPoint(label: 'S2', value: 79),
            FitChartPoint(label: 'S3', value: 78.4),
          ],
        ),
        FitMeasurementRow(
          label: 'Cintura',
          valueLabel: '82 cm',
          changeLabel: '-2 cm',
          onTap: _noop,
        ),
        FitProgressPhotoCard(
          dateLabel: '24 de julho',
          description: 'Frente',
          onTap: _noop,
        ),
        FitPersonalRecordCard(
          title: 'Maior carga',
          value: '120 kg',
          description: 'Agachamento',
        ),
        FitProfileStatisticCard(
          data: FitMetricData(
            label: 'Treinos',
            value: '84',
            icon: FitIcons.workout,
          ),
        ),
        FitProfileMenuTile(
          title: 'Configurações',
          description:
              'Preferências, privacidade e integrações da sua conta FitIA',
          icon: FitIcons.settings,
          onTap: _noop,
        ),
        FitConnectedDeviceCard(
          name: 'Health Connect',
          description: 'Sincronizado hoje',
          connected: true,
          onTap: _noop,
        ),
        FitPublicProfileHeader(
          name: 'Gabriel',
          subtitle: '84 treinos · 12 conquistas',
          badge: FitLevelBadge(label: 'Nível 18'),
        ),
        DomainShowcaseStates(emptyTitle: 'Perfil sem dados'),
      ],
    );
  }
}
