import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../design_system/design_system.dart';
import '../../../models/exercicio_model.dart';
import '../../../models/treino_model.dart';
import '../../../widgets/exercicio_gif_viewer.dart';
import '../../workout_vertical_slice/domain/workout_vertical_models.dart';
import 'core_journey_controller.dart';
import 'core_journey_scope.dart';
import 'core_journey_summary_page.dart';
import 'core_journey_ui.dart';

class CoreJourneyWorkoutPage extends StatefulWidget {
  const CoreJourneyWorkoutPage({
    super.key,
    required this.controller,
    required this.plan,
    required this.sessionId,
  });

  final CoreJourneyController controller;
  final TreinoModel plan;
  final String sessionId;

  @override
  State<CoreJourneyWorkoutPage> createState() => _CoreJourneyWorkoutPageState();
}

class _CoreJourneyWorkoutPageState extends State<CoreJourneyWorkoutPage> {
  final _weightController = TextEditingController(text: '55');
  final _repsController = TextEditingController(text: '10');
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final session = widget.controller.sessionById(widget.sessionId);
      if (session == null) return _missingSession(context);
      if (session.status == WorkoutSessionStatus.completed) {
        return CoreJourneySummaryPage(
          controller: widget.controller,
          sessionId: session.id,
        );
      }
      final exercise = _currentExercise(session);
      if (exercise == null) return _missingExercise(context);
      final completed = widget.controller
          .setsFor(session.id)
          .where((item) => item.exerciseId == exercise.id)
          .toList(growable: false);
      return CoreJourneyPageFrame(
        title: widget.plan.nome,
        subtitle: 'Treino em andamento',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            FitSpacing.s16,
            FitSpacing.s4,
            FitSpacing.s16,
            FitSpacing.s32,
          ),
          children: [
            CoreJourneySyncBanner(controller: widget.controller),
            if (widget.controller.hasPendingSync ||
                widget.controller.hasSyncIssue ||
                widget.controller.isOffline)
              const SizedBox(height: FitSpacing.s16),
            _WorkoutProgress(session: session, plan: widget.plan),
            const SizedBox(height: FitSpacing.s16),
            _ExerciseCard(
              exercise: exercise,
              session: session,
              completed: completed.length,
            ),
            const SizedBox(height: FitSpacing.s16),
            _SetInput(
              weightController: _weightController,
              repsController: _repsController,
              exercise: exercise,
              completed: completed.length,
              onRegister: () => _register(session, exercise),
            ),
            const SizedBox(height: FitSpacing.s16),
            _SetHistory(sets: completed),
            const SizedBox(height: FitSpacing.s20),
            FitButton(
              label: 'Finalizar treino',
              variant: FitButtonVariant.ghost,
              expand: true,
              onPressed: () => _finish(session),
            ),
          ],
        ),
      );
    },
  );

  ExercicioModel? _currentExercise(WorkoutSessionLocal session) {
    if (widget.plan.exercicios.isEmpty) return null;
    final index = session.currentExerciseIndex.clamp(
      0,
      widget.plan.exercicios.length - 1,
    );
    return widget.plan.exercicios[index];
  }

  Future<void> _register(
    WorkoutSessionLocal session,
    ExercicioModel exercise,
  ) async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsController.text);
    if (weight == null || reps == null) {
      FitFeedback.showError(context, 'Informe carga e repeticoes validas.');
      return;
    }
    final result = await widget.controller.registerSet(
      sessionId: session.id,
      exercise: exercise,
      weight: weight,
      reps: reps,
    );
    if (!mounted) return;
    if (result == null) {
      FitFeedback.showError(
        context,
        widget.controller.errorMessage ?? 'Nao foi possivel salvar a serie.',
      );
      return;
    }
    FitFeedback.showSuccess(
      context,
      result.duplicate
          ? 'Esta serie ja estava registrada.'
          : 'Serie salva neste dispositivo.',
    );
  }

  Future<void> _finish(WorkoutSessionLocal session) async {
    final previousFocus = FocusManager.instance.primaryFocus;
    final confirmed = await FitConfirmDialog.show(
      context: context,
      title: 'Finalizar treino?',
      message: 'O resumo sera salvo localmente e sincronizado quando possivel.',
      confirmLabel: 'Finalizar',
      cancelLabel: 'Continuar treino',
    );
    if (confirmed != true) {
      if (mounted && (previousFocus?.canRequestFocus ?? false)) {
        previousFocus!.requestFocus();
      }
      return;
    }
    if (!mounted) return;
    final finished = await widget.controller.finishWorkout(session.id);
    if (!mounted || finished == null) {
      if (mounted) {
        FitFeedback.showError(
          context,
          widget.controller.errorMessage ?? 'Nao foi possivel finalizar.',
        );
      }
      return;
    }
    if (CoreJourneyScope.maybeOf(context) != null) {
      await Navigator.of(context).pushReplacementNamed<void, void>(
        AppRoutes.coreWorkoutSummary,
        arguments: session.id,
      );
      return;
    }
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => CoreJourneySummaryPage(
          controller: widget.controller,
          sessionId: session.id,
        ),
      ),
    );
  }

  Widget _missingSession(BuildContext context) => CoreJourneyPageFrame(
    title: 'Treino',
    showBackButton: true,
    onBack: () => Navigator.of(context).maybePop(),
    child: const FitEmptyState(
      icon: FitIcons.history,
      title: 'Sessao nao encontrada',
      description:
          'Volte aos planos para iniciar ou continuar um treino valido.',
    ),
  );

  Widget _missingExercise(BuildContext context) => CoreJourneyPageFrame(
    title: widget.plan.nome,
    showBackButton: true,
    onBack: () => Navigator.of(context).maybePop(),
    child: const FitErrorState(
      title: 'Exercicio indisponivel',
      error: 'Este plano nao possui um exercicio valido para executar.',
    ),
  );
}

class _WorkoutProgress extends StatelessWidget {
  const _WorkoutProgress({required this.session, required this.plan});

  final WorkoutSessionLocal session;
  final TreinoModel plan;

  @override
  Widget build(BuildContext context) {
    final total = plan.exercicios.isEmpty ? 1 : plan.exercicios.length;
    final value = (session.currentExerciseIndex / total).clamp(0, 1).toDouble();
    return FitProgress(
      value: value,
      label: 'Exercicio ${session.currentExerciseIndex + 1} de $total',
      trailing: '${(value * 100).round()}%',
      animate: true,
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.session,
    required this.completed,
  });

  final ExercicioModel exercise;
  final WorkoutSessionLocal session;
  final int completed;

  @override
  Widget build(BuildContext context) => FitCard(
    variant: FitCardVariant.elevated,
    title: exercise.nome,
    subtitle: exercise.musculos.join(', '),
    semanticLabel:
        '${exercise.nome}. Musculos: ${exercise.musculos.join(', ')}. Serie ${completed + 1} de ${exercise.series}. ${exercise.repeticoes} repeticoes. Descanso de ${exercise.descansoSegundos} segundos.',
    leading: const Icon(FitIcons.exercise),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          image: true,
          label: 'Midia do exercicio ${exercise.nome}',
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: FitRadius.mediumBorder,
              child: ExercicioGifImage(
                canonicalExerciseId: exercise.canonicalExerciseId.isNotEmpty
                    ? exercise.canonicalExerciseId
                    : exercise.id,
                titulo: exercise.nome,
                fit: BoxFit.cover,
                placeholder: _ExerciseMediaFallback(
                  exerciseName: exercise.nome,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: FitSpacing.s12),
        Text(
          '${exercise.series} series  |  ${exercise.repeticoes} reps  |  ${exercise.descansoSegundos}s descanso',
        ),
        const SizedBox(height: FitSpacing.s4),
        Text(
          'Serie ${completed + 1} de ${exercise.series}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    ),
  );
}

class _ExerciseMediaFallback extends StatelessWidget {
  const _ExerciseMediaFallback({this.exerciseName});

  final String? exerciseName;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: exerciseName == null
        ? 'Midia do exercicio indisponivel'
        : 'Midia indisponivel para $exerciseName',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: FitRadius.mediumBorder,
      ),
      child: const Center(child: Icon(FitIcons.exercise, size: 48)),
    ),
  );
}

class _SetInput extends StatelessWidget {
  const _SetInput({
    required this.weightController,
    required this.repsController,
    required this.exercise,
    required this.completed,
    required this.onRegister,
  });

  final TextEditingController weightController;
  final TextEditingController repsController;
  final ExercicioModel exercise;
  final int completed;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: FitNumberField(
              controller: weightController,
              label: 'Carga (kg)',
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: FitNumberField(
              controller: repsController,
              label: 'Repeticoes',
            ),
          ),
        ],
      ),
      const SizedBox(height: FitSpacing.s12),
      FitPrimaryButton(
        label: completed >= exercise.series
            ? 'Series concluidas'
            : 'Concluir serie',
        icon: FitIcons.check,
        fullWidth: true,
        onPressed: completed >= exercise.series ? null : onRegister,
      ),
    ],
  );
}

class _SetHistory extends StatelessWidget {
  const _SetHistory({required this.sets});

  final List<WorkoutSetLocal> sets;

  @override
  Widget build(BuildContext context) => FitCard(
    title: 'Historico da sessao',
    subtitle: '${sets.length} series salvas',
    semanticLabel: 'Historico da sessao. ${sets.length} series salvas.',
    child: sets.isEmpty
        ? const Text('A primeira serie salva aparecera aqui.')
        : Column(
            children: [
              for (final item in sets)
                Padding(
                  padding: const EdgeInsets.only(bottom: FitSpacing.s8),
                  child: Row(
                    children: [
                      Expanded(child: Text('Serie ${item.setIndex + 1}')),
                      Text(
                        '${item.weight.toStringAsFixed(1)} kg x ${item.reps}',
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
}
