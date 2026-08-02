import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../screens/widgets/activities/activities_hub_cards.dart';
import '../../../../screens/widgets/activities/activities_hub_data.dart';
import '../../../../screens/widgets/activities/recent_activity.dart';
import '../../domain/activity_history_models.dart';
import '../controllers/activities_history_controller.dart';
import '../routes/activities_routes.dart';
import 'activity_history_widgets.dart';

/// Composicao do resumo de Atividades. Dados de treino concluido chegam apenas
/// da projecao canônica do journal; Corridas e Passos preservam seus fluxos.
class ActivitiesOverviewContent extends StatelessWidget {
  const ActivitiesOverviewContent({
    super.key,
    required this.history,
    required this.hubData,
    required this.hubLoading,
    required this.steps,
    required this.distance,
    required this.activeTime,
    required this.runSubtitle,
    required this.runDistance,
    required this.runPace,
    required this.stepsGoal,
    required this.stepsProgress,
    required this.showLocalBanner,
    required this.recentItems,
    required this.onOpenRuns,
    required this.onOpenSteps,
    required this.onRefresh,
  });

  final ActivitiesHistoryController history;
  final ActivitiesHubData hubData;
  final bool hubLoading;
  final String steps;
  final String distance;
  final String activeTime;
  final String runSubtitle;
  final String runDistance;
  final String runPace;
  final String stepsGoal;
  final double stepsProgress;
  final bool showLocalBanner;
  final List<RecentActivityItem> recentItems;
  final VoidCallback onOpenRuns;
  final VoidCallback onOpenSteps;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final workouts = history.filteredWorkouts;
    final lastWorkout = workouts.isEmpty ? null : workouts.first;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            key: const PageStorageKey('activities-overview-scroll'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s20,
              FitSpacing.s12,
              FitSpacing.s20,
              FitSpacing.s64,
            ),
            children: [
              FitHeader(
                title: 'Atividades',
                subtitle: 'Seu ritmo, consistencia e historico.',
                padding: EdgeInsets.zero,
                actions: [
                  FitIconButton(
                    icon: FitIcons.search,
                    tooltip: 'Pesquisar atividades',
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(ActivitiesRoutes.search),
                  ),
                  FitIconButton(
                    icon: FitIcons.calendar,
                    tooltip: 'Abrir calendario',
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(ActivitiesRoutes.calendar),
                  ),
                ],
              ),
              const SizedBox(height: FitSpacing.s20),
              ActivitySearchInput(controller: history),
              const SizedBox(height: FitSpacing.s12),
              ActivityPeriodFilters(
                controller: history,
                onOpenFilters: () => ActivityFilterSheet.show(context, history),
              ),
              const SizedBox(height: FitSpacing.s24),
              if (history.isLoading && !history.hasData)
                const _OverviewSkeleton()
              else ...[
                if (history.isShowingCachedOfflineData) ...[
                  FitOfflineState(
                    compact: true,
                    title: 'Historico local ativo',
                    description: 'Alguns treinos ainda aguardam sincronizacao.',
                    onRetry: () => history.refresh(),
                  ),
                  const SizedBox(height: FitSpacing.s16),
                ],
                FitSection(
                  title: 'Resumo do periodo',
                  subtitle: 'Dados de treinos concluidos',
                  action: TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(ActivitiesRoutes.calendar),
                    child: const Text('Calendario'),
                  ),
                  padding: EdgeInsets.zero,
                  child: ActivitySummaryGrid(
                    workouts: workouts,
                    streak: history.snapshot.streak,
                  ),
                ),
                const SizedBox(height: FitSpacing.s24),
                _MonthlySummary(workouts: workouts),
                const SizedBox(height: FitSpacing.s32),
                ActivitiesHubCards(
                  runSubtitle: runSubtitle,
                  runDistance: runDistance,
                  runPace: runPace,
                  steps: steps,
                  stepsGoal: stepsGoal,
                  stepsProgress: stepsProgress,
                  onOpenRuns: onOpenRuns,
                  onOpenSteps: onOpenSteps,
                ),
                if (showLocalBanner) ...[
                  const SizedBox(height: FitSpacing.s16),
                  const FitOfflineState(
                    compact: true,
                    title: 'Dados de movimento locais',
                    description:
                        'Passos e distancia usam dados deste dispositivo.',
                  ),
                ],
                const SizedBox(height: FitSpacing.s32),
                FitSection(
                  title: 'Historico',
                  subtitle: history.errorMessage,
                  onViewAll: () =>
                      Navigator.of(context).pushNamed(ActivitiesRoutes.history),
                  padding: EdgeInsets.zero,
                  child: _HistoryPreview(
                    history: history,
                    lastWorkout: lastWorkout,
                  ),
                ),
                const SizedBox(height: FitSpacing.s32),
                _RecentHubActivity(
                  items: recentItems,
                  hubData: hubData,
                  loading: hubLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      FitSkeleton(
        height: FitLayout.buttonHeightMedium,
        borderRadius: FitRadius.mediumBorder,
      ),
      SizedBox(height: FitSpacing.s16),
      FitSkeleton(
        height: FitLayout.skeletonListItemHeight,
        borderRadius: FitRadius.largeBorder,
      ),
      SizedBox(height: FitSpacing.s12),
      FitSkeleton(
        height: FitLayout.skeletonListItemHeight,
        borderRadius: FitRadius.largeBorder,
      ),
      SizedBox(height: FitSpacing.s12),
      FitSkeleton(
        height: FitLayout.skeletonListItemHeight,
        borderRadius: FitRadius.largeBorder,
      ),
    ],
  );
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.workouts});

  final List<WorkoutHistory> workouts;

  @override
  Widget build(BuildContext context) {
    final totalDuration = workouts.fold<int>(
      0,
      (total, workout) => total + workout.metrics.durationSeconds,
    );
    final totalSets = workouts.fold<int>(
      0,
      (total, workout) => total + workout.metrics.setCount,
    );
    return FitCard(
      title: 'Resumo mensal',
      subtitle: 'Visao consolidada do historico filtrado',
      leading: const Icon(FitIcons.calendarRange),
      variant: FitCardVariant.outlined,
      child: Row(
        children: [
          Expanded(
            child: FitMetric(
              label: 'Tempo total',
              value: formatActivityDuration(Duration(seconds: totalDuration)),
              icon: FitIcons.time,
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: FitMetric(
              label: 'Series',
              value: '$totalSets',
              icon: FitIcons.repetitions,
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: FitMetric(
              label: 'Ultimo treino',
              value: workouts.isEmpty
                  ? '--'
                  : formatActivityDate(workouts.first.finishedAt),
              icon: FitIcons.history,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({required this.history, required this.lastWorkout});

  final ActivitiesHistoryController history;
  final WorkoutHistory? lastWorkout;

  @override
  Widget build(BuildContext context) {
    if (history.errorMessage != null && !history.hasData) {
      return FitErrorState(
        error: history.errorMessage!,
        onRetry: history.refresh,
      );
    }
    if (lastWorkout == null) {
      return FitEmptyState(
        icon: FitIcons.history,
        title: 'Seu historico vai aparecer aqui',
        description:
            'Conclua um treino para acompanhar volume, series e evolucao.',
        actionLabel: 'Ver calendario',
        onAction: () =>
            Navigator.of(context).pushNamed(ActivitiesRoutes.calendar),
      );
    }
    final items = history.filteredWorkouts.take(3).toList(growable: false);
    final personalRecordSessions = history.snapshot.personalRecords
        .map((record) => record.sessionId)
        .toSet();
    return Column(
      children: [
        for (final workout in items) ...[
          ActivityTimelineCard(
            workout: workout,
            hasPersonalRecord: personalRecordSessions.contains(workout.id),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ActivitiesRoutes.detail, arguments: workout.id),
          ),
          if (workout != items.last) const SizedBox(height: FitSpacing.s12),
        ],
      ],
    );
  }
}

class _RecentHubActivity extends StatelessWidget {
  const _RecentHubActivity({
    required this.items,
    required this.hubData,
    required this.loading,
  });

  final List<RecentActivityItem> items;
  final ActivitiesHubData hubData;
  final bool loading;

  @override
  Widget build(BuildContext context) => FitSection(
    title: 'Movimento recente',
    subtitle: loading ? 'Atualizando dados locais...' : null,
    padding: EdgeInsets.zero,
    child: FitCard(
      variant: FitCardVariant.outlined,
      padding: const EdgeInsets.all(FitSpacing.s16),
      child: Column(
        children: [
          for (var index = 0; index < items.length && index < 3; index++) ...[
            _RecentHubActivityRow(item: items[index]),
            if (index < items.length - 1 && index < 2)
              const FitDivider(verticalSpacing: FitSpacing.s12),
          ],
        ],
      ),
    ),
  );
}

class _RecentHubActivityRow extends StatelessWidget {
  const _RecentHubActivityRow({required this.item});

  final RecentActivityItem item;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${item.title}: ${item.subtitle}',
    child: Row(
      children: [
        Icon(item.icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: FitSpacing.s2),
              Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}
