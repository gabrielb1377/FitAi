import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import 'core_journey_controller.dart';

String formatCoreDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String coreSyncLabel(WorkoutSyncStatus status) => switch (status) {
  WorkoutSyncStatus.synced => 'Sincronizado',
  WorkoutSyncStatus.syncing => 'Sincronizando',
  WorkoutSyncStatus.pending ||
  WorkoutSyncStatus.local => 'Pendente de sincronizacao',
  WorkoutSyncStatus.conflict => 'Conflito de sincronizacao',
  WorkoutSyncStatus.rejected ||
  WorkoutSyncStatus.failed => 'Falha de sincronizacao',
};

class CoreJourneySyncBanner extends StatelessWidget {
  const CoreJourneySyncBanner({super.key, required this.controller});

  final CoreJourneyController controller;

  @override
  Widget build(BuildContext context) {
    final hasIssue = controller.hasSyncIssue;
    final offline = controller.isOffline;
    final pending = controller.hasPendingSync;
    if (!offline && !pending && !hasIssue) return const SizedBox.shrink();
    final label = hasIssue
        ? 'Alguns dados precisam de revisao antes de sincronizar.'
        : offline
        ? 'Offline: seu treino continua salvo neste dispositivo.'
        : 'Sincronizacao pendente. Voce pode continuar usando o FitIA.';
    return Semantics(
      liveRegion: true,
      label: label,
      child: FitCard(
        variant: FitCardVariant.outlined,
        padding: const EdgeInsets.all(FitSpacing.s12),
        child: Row(
          children: [
            Icon(
              hasIssue
                  ? FitIcons.warning
                  : offline
                  ? FitIcons.offline
                  : FitIcons.backup,
              color: hasIssue
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            if (!offline && (pending || hasIssue))
              FitIconButton(
                icon: FitIcons.retry,
                tooltip: 'Tentar sincronizar novamente',
                onPressed: controller.isSyncing ? null : controller.retrySync,
              ),
          ],
        ),
      ),
    );
  }
}

class CoreJourneyPageFrame extends StatelessWidget {
  const CoreJourneyPageFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    namesRoute: true,
    label: title,
    child: Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        child: FocusTraversalGroup(
          child: Column(
            children: [
              FitHeader(
                title: title,
                subtitle: subtitle,
                showBackButton: showBackButton,
                onBack: onBack,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}
