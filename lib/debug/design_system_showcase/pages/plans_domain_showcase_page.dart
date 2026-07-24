import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes de domínio de Planos.
class PlansDomainShowcasePage extends StatelessWidget {
  const PlansDomainShowcasePage({super.key});

  static void _noop() {}

  static const _metrics = [
    FitMetricData(label: 'Dias', value: '4', icon: FitIcons.calendar),
    FitMetricData(
      label: 'Duração',
      value: '45',
      unit: 'min',
      icon: FitIcons.time,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DomainShowcaseScaffold(
      title: 'Planos',
      children: [
        const FitPlanCard(
          name: 'Upper / Lower',
          objective: 'Hipertrofia',
          progress: .62,
          onTap: _noop,
        ),
        const FitPlanCompactCard(
          name: 'PPL Intermediário',
          subtitle: '5 dias por semana',
          status: FitPlanStatus.paused,
          onTap: _noop,
        ),
        const FitPlanHeader(
          name: 'Upper / Lower',
          subtitle: 'Hipertrofia · Intermediário',
        ),
        const FitPlanProgress(value: .62, trailing: '3 de 5 treinos'),
        const Wrap(
          spacing: FitSpacing.s8,
          runSpacing: FitSpacing.s8,
          children: [
            FitPlanStatusBadge(status: FitPlanStatus.active),
            FitPlanStatusBadge(status: FitPlanStatus.paused),
            FitPlanStatusBadge(status: FitPlanStatus.completed),
            FitPlanStatusBadge(status: FitPlanStatus.archived),
            FitPlanStatusBadge(status: FitPlanStatus.public),
            FitPlanStatusBadge(status: FitPlanStatus.private),
            FitPlanStatusBadge(status: FitPlanStatus.locked),
            FitPlanStatusBadge(status: FitPlanStatus.loading),
          ],
        ),
        const FitPlanWeekSelector(
          weeks: [
            FitPlanWeekData(label: 'S1', completed: true),
            FitPlanWeekData(label: 'S2', current: true),
            FitPlanWeekData(label: 'S3', locked: true),
          ],
          onSelected: _ignoreInt,
        ),
        const FitWorkoutDayCard(
          name: 'Upper A',
          subtitle: 'Peito · Costas · Ombros',
          metrics: _metrics,
          onTap: _noop,
        ),
        const FitPlanExerciseRow(
          name: 'Supino reto',
          details: '4 séries · 8–10 repetições',
          onTap: _noop,
        ),
        const FitPlanCreationOptionCard(
          title: 'Plano com IA',
          description: 'Personalizado com seus dados e objetivos.',
          icon: FitIcons.ai,
          tone: FitDomainTone.ai,
          onTap: _noop,
        ),
        const FitPlanSummaryCard(
          title: 'Resumo do plano',
          subtitle: 'Upper / Lower',
          metrics: _metrics,
        ),
        const FitPlanStatisticCard(
          metric: FitMetricData(
            label: 'Volume',
            value: '12.480',
            unit: 'kg',
            icon: FitIcons.weight,
          ),
        ),
        const FitPlanComparisonCard(
          title: 'Comparação',
          currentLabel: '3 dias',
          comparisonLabel: '4 dias',
          description: 'Frequência semanal',
        ),
        const FitPlanTemplateCard(
          name: 'Força 5×5',
          description: 'Template para academia',
          onTap: _noop,
        ),
        const FitArchivedPlanCard(
          name: 'ABC anterior',
          description: 'Arquivado em junho',
          onRestore: _noop,
        ),
        const FitWorkoutDayCard(name: 'Dia bloqueado', locked: true),
        const DomainShowcaseStates(emptyTitle: 'Sem planos'),
      ],
    );
  }
}

void _ignoreInt(int _) {}
