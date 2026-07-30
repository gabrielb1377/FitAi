import 'dart:async';

import 'package:fitai/design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/workout_vertical_local_store.dart';
import '../data/workout_vertical_repository.dart';
import '../data/workout_vertical_sync_transport.dart';
import '../domain/workout_vertical_models.dart';
import 'workout_vertical_slice_controller.dart';

/// Tela isolada, acessivel apenas no Developer Mode, para validar o slice.
class WorkoutVerticalSlicePage extends StatefulWidget {
  const WorkoutVerticalSlicePage({super.key, this.controller});

  final WorkoutVerticalSliceController? controller;

  @override
  State<WorkoutVerticalSlicePage> createState() =>
      _WorkoutVerticalSlicePageState();
}

class _WorkoutVerticalSlicePageState extends State<WorkoutVerticalSlicePage> {
  final _weightController = TextEditingController(text: '55');
  final _repsController = TextEditingController(text: '10');
  WorkoutVerticalSliceController? _controller;
  Timer? _clockTimer;
  bool _ownsController = false;
  bool _recoveryShown = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _ownsController = widget.controller == null;
    if (_controller != null) {
      _initialize(_controller!);
    } else {
      unawaited(_createDefaultController());
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _controller?.refreshClock();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  Future<void> _createDefaultController() async {
    final preferences = await SharedPreferences.getInstance();
    final transport = DebugWorkoutSyncTransport();
    final controller = WorkoutVerticalSliceController(
      repository: WorkoutVerticalRepository(
        localStore: SharedPreferencesWorkoutVerticalLocalStore(preferences),
        transport: AdaptiveWorkoutSyncTransport(debugTransport: transport),
      ),
      debugTransport: transport,
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    await _initialize(controller);
  }

  Future<void> _initialize(WorkoutVerticalSliceController controller) async {
    await controller.initialize();
    if (!mounted || !controller.needsRecoveryPrompt || _recoveryShown) return;
    _recoveryShown = true;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await _showRecoveryDialog(controller);
  }

  Future<void> _showRecoveryDialog(WorkoutVerticalSliceController controller) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Treino em andamento'),
        content: const Text(
          'Uma sessao local foi recuperada. Voce pode continuar sem conexao ou descartar esta sessao.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.discardRecoveredWorkout();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () async {
              await controller.continueRecoveredWorkout();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerSet(WorkoutVerticalSliceController controller) async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsController.text);
    if (weight == null || reps == null) {
      _showMessage('Informe uma carga e repeticoes validas.');
      return;
    }
    await controller.registerSet(weight: weight, reps: reps);
    if (!mounted || controller.errorMessage == null) return;
    _showMessage(controller.errorMessage!);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _buildPage(context, controller),
    );
  }

  Widget _buildPage(
    BuildContext context,
    WorkoutVerticalSliceController controller,
  ) {
    final session = controller.activeSession;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Workout Vertical Slice'),
        actions: [
          IconButton(
            tooltip: 'Simular reinicio do aplicativo',
            onPressed: controller.isLoading ? null : controller.simulateRestart,
            icon: const Icon(FitIcons.retry),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(FitSpacing.screenMargin),
                children: [
                  _SyncBanner(
                    offline: controller.isOffline,
                    pending: controller.hasPendingOutbox,
                    issue: controller.hasSyncIssue,
                    syncStatus: session?.syncStatus,
                  ),
                  const SizedBox(height: FitSpacing.s16),
                  if (session == null)
                    _StartWorkoutCard(controller: controller)
                  else ...[
                    _WorkoutSessionCard(
                      session: session,
                      rest: controller.restRemaining,
                      setCount: controller.activeSets.length,
                    ),
                    const SizedBox(height: FitSpacing.s16),
                    _RegisterSetCard(
                      controller: controller,
                      weightController: _weightController,
                      repsController: _repsController,
                      onRegister: () => _registerSet(controller),
                    ),
                    const SizedBox(height: FitSpacing.s16),
                    _SetHistory(sets: controller.activeSets),
                    const SizedBox(height: FitSpacing.s16),
                    _WorkoutActions(controller: controller, session: session),
                  ],
                  if (kDebugMode) ...[
                    const SizedBox(height: FitSpacing.s24),
                    _DebugControls(controller: controller),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({
    required this.offline,
    required this.pending,
    required this.issue,
    this.syncStatus,
  });

  final bool offline;
  final bool pending;
  final bool issue;
  final WorkoutSyncStatus? syncStatus;

  @override
  Widget build(BuildContext context) {
    final message = offline
        ? 'Offline: tudo continua salvo neste dispositivo.'
        : pending
        ? 'Sincronizacao pendente.'
        : issue
        ? 'Sincronizacao requer revisao.'
        : syncStatus == WorkoutSyncStatus.synced
        ? 'Sincronizado.'
        : 'Pronto para iniciar um treino local.';
    final icon = offline
        ? FitIcons.offline
        : pending
        ? FitIcons.backup
        : issue
        ? FitIcons.warning
        : FitIcons.success;
    return Semantics(
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: offline || issue
              ? FitColors.cardInner
              : FitColors.primaryContainer,
          borderRadius: FitRadius.mediumBorder,
          border: Border.all(
            color: offline || issue
                ? FitColors.borderSubtle
                : FitColors.primaryMuted,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s12),
          child: Row(
            children: [
              Icon(
                icon,
                color: offline || issue
                    ? FitColors.textSecondary
                    : FitColors.primary,
              ),
              const SizedBox(width: FitSpacing.s8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartWorkoutCard extends StatelessWidget {
  const _StartWorkoutCard({required this.controller});

  final WorkoutVerticalSliceController controller;

  @override
  Widget build(BuildContext context) => FitCard(
    title: 'Upper A de exemplo',
    subtitle: 'Supino reto · 4 series · descanso persistente',
    leading: const Icon(FitIcons.workout, color: FitColors.primary),
    child: FitButton(
      label: 'Iniciar treino local',
      leadingIcon: FitIcons.play,
      expand: true,
      isLoading: controller.isSaving,
      onPressedAsync: controller.startExampleWorkout,
      semanticLabel: 'Iniciar treino de exemplo salvo no dispositivo',
    ),
  );
}

class _WorkoutSessionCard extends StatelessWidget {
  const _WorkoutSessionCard({
    required this.session,
    required this.rest,
    required this.setCount,
  });

  final WorkoutSessionLocal session;
  final Duration rest;
  final int setCount;

  @override
  Widget build(BuildContext context) => FitCard(
    title: 'Supino reto',
    subtitle: 'Peito · Triceps · Ombros',
    leading: const Icon(FitIcons.exercise, color: FitColors.primary),
    trailing: Text('${session.currentSetIndex + 1}/4'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Series salvas: $setCount',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: FitSpacing.s8),
        Semantics(
          liveRegion: true,
          label: 'Descanso restante ${_restLabel(rest)}',
          child: Text(
            rest == Duration.zero
                ? 'Pronto para a proxima serie'
                : 'Descanso: ${_restLabel(rest)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    ),
  );
}

class _RegisterSetCard extends StatelessWidget {
  const _RegisterSetCard({
    required this.controller,
    required this.weightController,
    required this.repsController,
    required this.onRegister,
  });

  final WorkoutVerticalSliceController controller;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final Future<void> Function() onRegister;

  @override
  Widget build(BuildContext context) => FitCard(
    title: 'Registrar serie',
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FitNumberField(
                controller: weightController,
                label: 'Carga (kg)',
                semanticLabel: 'Carga da serie em quilogramas',
              ),
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: FitNumberField(
                controller: repsController,
                label: 'Repeticoes',
                semanticLabel: 'Numero de repeticoes da serie',
              ),
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s16),
        FitButton(
          label: 'Concluir serie',
          leadingIcon: FitIcons.check,
          expand: true,
          isLoading: controller.isSaving,
          onPressedAsync: onRegister,
          semanticLabel: 'Concluir e salvar a serie no dispositivo',
        ),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: FitSpacing.s8),
          Semantics(
            liveRegion: true,
            label: controller.errorMessage,
            child: Text(
              controller.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    ),
  );
}

class _SetHistory extends StatelessWidget {
  const _SetHistory({required this.sets});

  final List<WorkoutSetLocal> sets;

  @override
  Widget build(BuildContext context) => FitCard(
    title: 'Historico local',
    subtitle: sets.isEmpty ? 'Nenhuma serie registrada ainda.' : null,
    child: sets.isEmpty
        ? const SizedBox.shrink()
        : Column(
            children: [
              for (final set in sets)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${set.setIndex + 1}')),
                  title: Text(
                    '${set.weight.toStringAsFixed(1)} kg × ${set.reps}',
                  ),
                  subtitle: Text('Salva ${_timeLabel(set.completedAt)}'),
                  trailing: const Icon(
                    FitIcons.success,
                    color: FitColors.primary,
                  ),
                ),
            ],
          ),
  );
}

class _WorkoutActions extends StatelessWidget {
  const _WorkoutActions({required this.controller, required this.session});

  final WorkoutVerticalSliceController controller;
  final WorkoutSessionLocal session;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FitButton(
        label: session.status == WorkoutSessionStatus.paused
            ? 'Retomar treino'
            : 'Pausar treino',
        variant: FitButtonVariant.outlined,
        leadingIcon: session.status == WorkoutSessionStatus.paused
            ? FitIcons.play
            : FitIcons.pause,
        onPressedAsync: controller.pauseOrResume,
      ),
      const SizedBox(height: FitSpacing.s12),
      FitButton(
        label: 'Finalizar treino',
        variant: FitButtonVariant.success,
        leadingIcon: FitIcons.check,
        onPressedAsync: controller.finishWorkout,
      ),
      if (controller.hasPendingOutbox) ...[
        const SizedBox(height: FitSpacing.s12),
        FitButton(
          label: 'Tentar sincronizar novamente',
          variant: FitButtonVariant.ghost,
          leadingIcon: FitIcons.retry,
          onPressedAsync: controller.retryNow,
        ),
      ],
    ],
  );
}

class _DebugControls extends StatelessWidget {
  const _DebugControls({required this.controller});

  final WorkoutVerticalSliceController controller;

  @override
  Widget build(BuildContext context) => FitCard(
    title: 'Developer Mode',
    subtitle: 'Controles exclusivos para validar persistencia e outbox.',
    variant: FitCardVariant.outlined,
    child: Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Simular offline'),
          value: controller.isOffline,
          onChanged: controller.setOffline,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Falhar proxima persistencia'),
          value: controller.failNextPersistence,
          onChanged: controller.setFailNextPersistence,
        ),
        FitButton(
          label: 'Falhar proxima sincronizacao',
          variant: FitButtonVariant.ghost,
          leadingIcon: FitIcons.warning,
          onPressed: controller.simulateNextSyncFailure,
        ),
      ],
    ),
  );
}

String _restLabel(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _timeLabel(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
