import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import 'planos_official_primitives.dart';

/// Dados de apresentacao de um treino do plano.
///
/// Mantem os IDs e a ordem recebidos da pagina, sem criar uma segunda fonte de
/// dados para a estrutura do plano.
class PlanosDetailWorkout {
  const PlanosDetailWorkout({
    required this.id,
    required this.name,
    required this.weekday,
    required this.exerciseCount,
    required this.isCurrent,
  });

  final String id;
  final String name;
  final String weekday;
  final int exerciseCount;
  final bool isCurrent;
}

/// Conteudo visual do detalhe de plano da migracao UI-M1.4.
///
/// A pagina proprietaria continua responsavel pela navegacao, persistencia e
/// acoes de dominio. Este widget recebe somente dados ja calculados.
class PlanosPlanDetailContent extends StatelessWidget {
  const PlanosPlanDetailContent({
    super.key,
    required this.planName,
    required this.description,
    required this.objective,
    required this.mediaAssetPath,
    required this.daysPerWeek,
    required this.estimatedMinutes,
    required this.exerciseCount,
    required this.weeklyCompleted,
    required this.weeklyTarget,
    required this.currentWeekLabel,
    required this.workouts,
    required this.onBack,
    required this.onMore,
    required this.onOpenWeek,
    required this.onOpenCalendar,
    required this.onOpenProgress,
    required this.onOpenWorkout,
    this.isOffline = false,
    this.hasPartialFailure = false,
  });

  final String planName;
  final String description;
  final String objective;
  final String? mediaAssetPath;
  final int daysPerWeek;
  final int estimatedMinutes;
  final int exerciseCount;
  final int weeklyCompleted;
  final int weeklyTarget;
  final String currentWeekLabel;
  final List<PlanosDetailWorkout> workouts;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final VoidCallback onOpenWeek;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenProgress;
  final ValueChanged<PlanosDetailWorkout> onOpenWorkout;
  final bool isOffline;
  final bool hasPartialFailure;

  @override
  Widget build(BuildContext context) {
    final target = weeklyTarget <= 0 ? 1 : weeklyTarget;
    final completed = weeklyCompleted.clamp(0, target);
    final progress = completed / target;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s16,
        FitSpacing.s4,
        FitSpacing.s16,
        FitSpacing.s32,
      ),
      children: [
        _PlanHero(
          planName: planName,
          objective: objective,
          mediaAssetPath: mediaAssetPath,
          onBack: onBack,
          onMore: onMore,
        ),
        const SizedBox(height: FitSpacing.s16),
        if (description.trim().isNotEmpty) ...[
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FitSpacing.s16),
        ],
        _PlanMetrics(
          daysPerWeek: daysPerWeek,
          estimatedMinutes: estimatedMinutes,
          exerciseCount: exerciseCount,
        ),
        const SizedBox(height: FitSpacing.s16),
        FitCard(
          variant: FitCardVariant.outlined,
          semanticLabel:
              'Progresso semanal: $completed de $target treinos concluidos.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progresso do plano',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: FitSpacing.s12),
              FitProgress(
                value: progress,
                label: currentWeekLabel,
                trailing: '$completed de $target treinos',
                animate: true,
              ),
            ],
          ),
        ),
        if (isOffline) ...[
          const SizedBox(height: FitSpacing.s12),
          const FitInfoCard(
            title: 'Offline',
            description: 'Exibindo o plano salvo neste dispositivo.',
            icon: FitIcons.offline,
            tone: FitInfoCardTone.warning,
          ),
        ],
        if (hasPartialFailure) ...[
          const SizedBox(height: FitSpacing.s12),
          const FitInfoCard(
            title: 'Alguns dados estao indisponiveis',
            description:
                'O plano continua acessivel enquanto atualizamos os dados.',
            icon: FitIcons.warning,
            tone: FitInfoCardTone.warning,
          ),
        ],
        const SizedBox(height: FitSpacing.s16),
        _QuickLinks(
          onOpenWeek: onOpenWeek,
          onOpenCalendar: onOpenCalendar,
          onOpenProgress: onOpenProgress,
        ),
        const SizedBox(height: FitSpacing.s24),
        _WorkoutsSectionHeader(
          currentWeekLabel: currentWeekLabel,
          onOpenWeek: onOpenWeek,
        ),
        const SizedBox(height: FitSpacing.s12),
        if (workouts.isEmpty)
          const FitEmptyState(
            icon: FitIcons.workout,
            title: 'Nenhum treino neste plano',
            description: 'Adicione treinos ao plano antes de iniciar.',
          )
        else
          for (final workout in workouts) ...[
            _WorkoutRow(workout: workout, onTap: () => onOpenWorkout(workout)),
            const SizedBox(height: FitSpacing.s8),
          ],
        const SizedBox(height: FitSpacing.s16),
        const FitInfoCard(
          title: 'Coach FitIA',
          description: 'Nenhuma recomendacao esta disponivel para este plano.',
          icon: FitIcons.ai,
          tone: FitInfoCardTone.info,
        ),
      ],
    );
  }
}

class _PlanHero extends StatelessWidget {
  const _PlanHero({
    required this.planName,
    required this.objective,
    required this.mediaAssetPath,
    required this.onBack,
    required this.onMore,
  });

  final String planName;
  final String objective;
  final String? mediaAssetPath;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Plano ativo: $planName. Objetivo: $objective.',
      child: Stack(
        children: [
          PlanosPlanMedia(
            assetPath: mediaAssetPath,
            label: 'Capa do plano $planName',
            height: FitLayout.domainChartHeight + FitSpacing.s32,
          ),
          Positioned(
            top: FitSpacing.s8,
            left: FitSpacing.s8,
            child: FitIconButton(
              icon: FitIcons.back,
              tooltip: 'Voltar para Planos',
              variant: FitIconButtonVariant.outlined,
              onPressed: onBack,
            ),
          ),
          Positioned(
            top: FitSpacing.s8,
            right: FitSpacing.s8,
            child: FitIconButton(
              icon: FitIcons.more,
              tooltip: 'Opcoes do plano',
              variant: FitIconButtonVariant.outlined,
              onPressed: onMore,
            ),
          ),
          Positioned(
            right: FitSpacing.s12,
            bottom: FitSpacing.s12,
            child: FitChip(label: objective, selected: true),
          ),
          Positioned(
            left: FitSpacing.s16,
            right: FitSpacing.s16,
            bottom: FitSpacing.s12,
            child: Padding(
              padding: const EdgeInsets.only(right: FitSpacing.s64),
              child: Text(
                planName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMetrics extends StatelessWidget {
  const _PlanMetrics({
    required this.daysPerWeek,
    required this.estimatedMinutes,
    required this.exerciseCount,
  });

  final int daysPerWeek;
  final int estimatedMinutes;
  final int exerciseCount;

  @override
  Widget build(BuildContext context) {
    return PlanosMetricRow(
      metrics: [
        PlanosMetricData(
          label: 'dias/semana',
          value: '$daysPerWeek',
          icon: FitIcons.calendar,
        ),
        PlanosMetricData(
          label: 'duracao',
          value: estimatedMinutes > 0 ? '$estimatedMinutes min' : '-',
          icon: FitIcons.time,
        ),
        PlanosMetricData(
          label: 'exercicios',
          value: '$exerciseCount',
          icon: FitIcons.exercise,
        ),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({
    required this.onOpenWeek,
    required this.onOpenCalendar,
    required this.onOpenProgress,
  });

  final VoidCallback onOpenWeek;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickLink(
            icon: FitIcons.list,
            label: 'Treinos',
            onTap: onOpenWeek,
          ),
        ),
        const SizedBox(width: FitSpacing.s8),
        Expanded(
          child: _QuickLink(
            icon: FitIcons.calendarRange,
            label: 'Calendario',
            onTap: onOpenCalendar,
          ),
        ),
        const SizedBox(width: FitSpacing.s8),
        Expanded(
          child: _QuickLink(
            icon: FitIcons.progress,
            label: 'Progresso',
            onTap: onOpenProgress,
          ),
        ),
      ],
    );
  }
}

class _WorkoutsSectionHeader extends StatelessWidget {
  const _WorkoutsSectionHeader({
    required this.currentWeekLabel,
    required this.onOpenWeek,
  });

  final String currentWeekLabel;
  final VoidCallback onOpenWeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!FitBreakpoints.isSmallMobile(constraints.maxWidth)) {
          return FitSectionHeader(
            title: 'Treinos da semana',
            badge: FitChip(label: currentWeekLabel),
            viewAllLabel: 'Ver semana',
            onViewAll: onOpenWeek,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treinos da semana',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: FitSpacing.s8),
            Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FitChip(label: currentWeekLabel),
                TextButton(
                  onPressed: onOpenWeek,
                  child: const Text('Ver semana'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FitCard(
        variant: FitCardVariant.clickable,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: FitSpacing.s4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout, required this.onTap});

  final PlanosDetailWorkout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stateLabel = workout.isCurrent
        ? 'Hoje'
        : '$workout.exerciseCount exercicios';
    return Semantics(
      button: true,
      selected: workout.isCurrent,
      label: '${workout.weekday}, ${workout.name}. $stateLabel.',
      child: FitCard(
        variant: FitCardVariant.clickable,
        selected: workout.isCurrent,
        onTap: onTap,
        padding: const EdgeInsets.all(FitSpacing.s12),
        child: Row(
          children: [
            SizedBox(
              width: FitSpacing.s32,
              child: Text(
                workout.weekday,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: FitSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: FitSpacing.s2),
                  Text(
                    stateLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              workout.isCurrent ? FitIcons.play : FitIcons.forward,
              color: workout.isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
