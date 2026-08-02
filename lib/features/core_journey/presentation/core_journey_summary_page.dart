import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import 'core_journey_controller.dart';
import 'core_journey_history_page.dart';
import 'core_journey_scope.dart';
import 'core_journey_ui.dart';

class CoreJourneySummaryPage extends StatelessWidget {
  const CoreJourneySummaryPage({
    super.key,
    required this.controller,
    required this.sessionId,
  });

  final CoreJourneyController controller;
  final String sessionId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final session = controller.sessionById(sessionId);
      if (session == null || session.status != WorkoutSessionStatus.completed) {
        return CoreJourneyPageFrame(
          title: 'Resumo',
          showBackButton: true,
          onBack: () => Navigator.of(context).maybePop(),
          child: const FitEmptyState(
            icon: FitIcons.history,
            title: 'Resumo indisponivel',
            description:
                'Este treino ainda nao foi finalizado ou nao esta neste dispositivo.',
          ),
        );
      }
      final sets = controller.setsFor(session.id);
      final plan = controller.planById(session.planId);
      return CoreJourneyPageFrame(
        title: 'Treino concluido',
        subtitle: plan?.nome ?? 'Treino local',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s16,
            FitSpacing.s4,
            FitSpacing.s16,
            FitSpacing.s32,
          ),
          children: [
            CoreJourneySyncBanner(controller: controller),
            if (controller.hasPendingSync ||
                controller.hasSyncIssue ||
                controller.isOffline)
              const SizedBox(height: FitSpacing.s16),
            FitCard(
              variant: FitCardVariant.elevated,
              title: 'Resumo da sessao',
              leading: const Icon(FitIcons.success),
              semanticLabel:
                  'Resumo da sessao. ${sets.length} series. ${controller.volumeFor(session.id).toStringAsFixed(1)} quilogramas de volume. ${coreSyncLabel(session.syncStatus)}.',
              child: _SummaryMetrics(
                duration: controller.durationFor(session),
                exerciseCount: sets
                    .map((item) => item.exerciseId)
                    .toSet()
                    .length,
                setCount: sets.length,
                volume: controller.volumeFor(session.id),
                syncStatus: session.syncStatus,
              ),
            ),
            const SizedBox(height: FitSpacing.s20),
            FitPrimaryButton(
              label: 'Ver historico',
              icon: FitIcons.history,
              fullWidth: true,
              onPressed: () {
                final scope = CoreJourneyScope.maybeOf(context);
                if (scope != null) {
                  scope.onOpenPlanWorkoutHistory(session.id);
                  return;
                }
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        CoreJourneyHistoryPage(controller: controller),
                  ),
                );
              },
            ),
            const SizedBox(height: FitSpacing.s8),
            FitGhostButton(
              label: 'Voltar a Home',
              fullWidth: true,
              onPressed: () {
                final scope = CoreJourneyScope.maybeOf(context);
                if (scope != null) {
                  scope.onOpenHome();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  return;
                }
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      );
    },
  );
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({
    required this.duration,
    required this.exerciseCount,
    required this.setCount,
    required this.volume,
    required this.syncStatus,
  });

  final Duration duration;
  final int exerciseCount;
  final int setCount;
  final double volume;
  final WorkoutSyncStatus syncStatus;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _MetricRow(label: 'Duracao', value: formatCoreDuration(duration)),
      _MetricRow(label: 'Exercicios', value: '$exerciseCount'),
      _MetricRow(label: 'Series', value: '$setCount'),
      _MetricRow(label: 'Volume', value: '${volume.toStringAsFixed(1)} kg'),
      _MetricRow(label: 'Sincronizacao', value: coreSyncLabel(syncStatus)),
    ],
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: FitSpacing.s12),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );
}
