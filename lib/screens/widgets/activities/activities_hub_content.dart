import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import 'activities_hub_cards.dart';
import 'activities_summary.dart';
import 'recent_activity.dart';

class ActivitiesHubContent extends StatelessWidget {
  final String steps;
  final String distance;
  final String activeTime;
  final bool showLocalBanner;
  final String runSubtitle;
  final String runDistance;
  final String runPace;
  final String stepsGoal;
  final double stepsProgress;
  final VoidCallback onOpenRuns;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenCalendar;
  final RefreshCallback onRefresh;
  final List<RecentActivityItem> recentItems;

  const ActivitiesHubContent({
    super.key,
    required this.steps,
    required this.distance,
    required this.activeTime,
    required this.showLocalBanner,
    required this.runSubtitle,
    required this.runDistance,
    required this.runPace,
    required this.stepsGoal,
    required this.stepsProgress,
    required this.onOpenRuns,
    required this.onOpenSteps,
    required this.onOpenTimeline,
    required this.onOpenCalendar,
    required this.onRefresh,
    required this.recentItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            key: const PageStorageKey('atividades-hub-scroll'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              FitSpacing.s20,
              FitSpacing.s12,
              FitSpacing.s20,
              FitSpacing.s64 + FitSpacing.s32 + FitSpacing.s4,
            ),
            children: [
              const FitHeader(
                title: 'Atividades',
                subtitle: 'Acompanhe sua movimentacao.',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: FitSpacing.s24),
              ActivitiesSummary(
                steps: steps,
                distance: distance,
                activeTime: activeTime,
              ),
              if (showLocalBanner) ...[
                const SizedBox(height: FitSpacing.s20),
                _LocalDataBanner(),
              ],
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
              const SizedBox(height: FitSpacing.s24),
              _ActivitiesBrowseActions(
                onOpenTimeline: onOpenTimeline,
                onOpenCalendar: onOpenCalendar,
              ),
              const SizedBox(height: FitSpacing.s32),
              RecentActivity(items: recentItems),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivitiesBrowseActions extends StatelessWidget {
  const _ActivitiesBrowseActions({
    required this.onOpenTimeline,
    required this.onOpenCalendar,
  });

  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return FitSection(
      title: 'Acompanhar',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          FitActionRow(
            icon: FitIcons.activities,
            title: 'Linha do tempo',
            subtitle: 'Corridas e resumos diarios de passos.',
            onTap: onOpenTimeline,
          ),
          const Divider(),
          FitActionRow(
            icon: FitIcons.calendar,
            title: 'Calendario',
            subtitle: 'Veja corridas e metas de passos por dia.',
            onTap: onOpenCalendar,
          ),
        ],
      ),
    );
  }
}

class _LocalDataBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dados locais ativos',
      child: Row(
        children: [
          const FitBadge.offline(),
          const SizedBox(width: FitSpacing.s8),
          Expanded(
            child: Text(
              'Mostrando dados salvos no dispositivo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
