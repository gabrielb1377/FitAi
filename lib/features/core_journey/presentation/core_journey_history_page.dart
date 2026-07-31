import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import 'core_journey_controller.dart';
import 'core_journey_summary_page.dart';
import 'core_journey_ui.dart';

/// Historico local-first. Uma sessao concluida aparece uma vez pois a lista e
/// derivada diretamente do snapshot idempotente do vertical slice.
class CoreJourneyHistoryPage extends StatelessWidget {
  const CoreJourneyHistoryPage({
    super.key,
    required this.controller,
    this.title = 'Historico de treinos',
    this.subtitle = 'Salvo neste dispositivo',
    this.showBackButton = true,
  });

  final CoreJourneyController controller;
  final String title;
  final String subtitle;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => CoreJourneyPageFrame(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton && Navigator.of(context).canPop(),
      onBack: showBackButton && Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      child: controller.completedSessions.isEmpty
          ? const FitEmptyState(
              icon: FitIcons.history,
              title: 'Nenhum treino concluido',
              description:
                  'Quando voce finalizar uma sessao, ela aparecera aqui mesmo offline.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s16,
                FitSpacing.s4,
                FitSpacing.s16,
                FitSpacing.s32,
              ),
              itemCount: controller.completedSessions.length + 1,
              separatorBuilder: (_, index) => SizedBox(
                height: index == 0 ? FitSpacing.s16 : FitSpacing.s12,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CoreJourneySyncBanner(controller: controller);
                }
                final session = controller.completedSessions[index - 1];
                return _HistoryRow(
                  controller: controller,
                  session: session,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CoreJourneySummaryPage(
                        controller: controller,
                        sessionId: session.id,
                      ),
                    ),
                  ),
                );
              },
            ),
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.controller,
    required this.session,
    required this.onTap,
  });

  final CoreJourneyController controller;
  final WorkoutSessionLocal session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plan = controller.planById(session.planId);
    final sets = controller.setsFor(session.id);
    return FitCard(
      variant: FitCardVariant.clickable,
      title: plan?.nome ?? 'Treino',
      subtitle: formatCoreDuration(controller.durationFor(session)),
      leading: const Icon(FitIcons.success),
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
      child: Text(
        '${sets.length} series  |  ${controller.volumeFor(session.id).toStringAsFixed(1)} kg  |  ${coreSyncLabel(session.syncStatus)}',
      ),
    );
  }
}
