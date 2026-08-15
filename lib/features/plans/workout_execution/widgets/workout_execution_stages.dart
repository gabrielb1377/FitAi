import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';

/// Estados visuais intermediários da execução. O controlador da sessão
/// permanece em [TreinoEmAndamentoPage]; estes widgets não possuem timers.
enum WorkoutExecutionStage {
  active,
  exerciseSummary,
  interExerciseRest,
  nextExercise,
  paused,
}

class WorkoutExerciseSummaryStage extends StatelessWidget {
  const WorkoutExerciseSummaryStage({
    super.key,
    required this.exercise,
    required this.completedSets,
    required this.onContinue,
    required this.onClose,
  });

  final ExercicioModel exercise;
  final int completedSets;
  final VoidCallback onContinue;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _StageScaffold(
      title: 'Exercício concluído',
      onClose: onClose,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FitWorkoutCompletionHeader(
            title: exercise.nome,
            message: '$completedSets séries registradas.',
          ),
          const SizedBox(height: FitSpacing.s24),
          FitCard(
            variant: FitCardVariant.outlined,
            child: Text(
              'Bom trabalho. Faça uma pausa antes do próximo exercício.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: FitSpacing.s24),
          FitButton(
            label: 'Iniciar descanso',
            leadingIcon: Icons.timer_outlined,
            expand: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class WorkoutInterExerciseRestStage extends StatelessWidget {
  const WorkoutInterExerciseRestStage({
    super.key,
    required this.nextExercise,
    required this.remainingLabel,
    required this.progress,
    required this.paused,
    required this.onTogglePause,
    required this.onSkip,
    required this.onAddTime,
    required this.onClose,
  });

  final ExercicioModel nextExercise;
  final String remainingLabel;
  final double progress;
  final bool paused;
  final VoidCallback onTogglePause;
  final VoidCallback onSkip;
  final VoidCallback onAddTime;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _StageScaffold(
      title: 'Descanso',
      onClose: onClose,
      child: FitExerciseRestScreenContent(
        title: paused ? 'Descanso pausado' : 'Recupere-se',
        description: 'O próximo exercício será ${nextExercise.nome}.',
        timer: FitRestTimerWidget(
          remainingLabel: remainingLabel,
          progress: progress,
          paused: paused,
          onTogglePause: onTogglePause,
          onSkip: onSkip,
          onAddTime: onAddTime,
          addTimeLabel: '+15 s',
        ),
        nextExercise: FitNextExerciseCard(
          name: nextExercise.nome,
          details: _prescription(nextExercise),
        ),
      ),
    );
  }
}

class WorkoutNextExerciseStage extends StatelessWidget {
  const WorkoutNextExerciseStage({
    super.key,
    required this.exercise,
    required this.onStart,
    required this.onClose,
  });

  final ExercicioModel exercise;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _StageScaffold(
      title: 'Próximo exercício',
      onClose: onClose,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FitNextExerciseCard(
            name: exercise.nome,
            details: _prescription(exercise),
          ),
          const SizedBox(height: FitSpacing.s24),
          FitButton(
            label: 'Começar exercício',
            leadingIcon: Icons.play_arrow_rounded,
            expand: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class WorkoutPausedStage extends StatelessWidget {
  const WorkoutPausedStage({
    super.key,
    required this.workoutName,
    required this.elapsedLabel,
    required this.onResume,
    required this.onSettings,
    required this.onSwapExercise,
    required this.onEnd,
    required this.onDiscard,
  });

  final String workoutName;
  final String elapsedLabel;
  final VoidCallback onResume;
  final VoidCallback onSettings;
  final VoidCallback onSwapExercise;
  final VoidCallback onEnd;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return _StageScaffold(
      title: 'Treino pausado',
      onClose: onResume,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FitWorkoutCompletionHeader(
            title: workoutName,
            message: 'Tempo decorrido: $elapsedLabel',
            icon: Icons.pause_circle_outline_rounded,
          ),
          const SizedBox(height: FitSpacing.s24),
          FitCard(
            variant: FitCardVariant.outlined,
            child: Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              alignment: WrapAlignment.center,
              children: [
                FitButton(
                  label: 'Configurações',
                  size: FitButtonSize.compact,
                  variant: FitButtonVariant.outlined,
                  leadingIcon: Icons.settings_outlined,
                  onPressed: onSettings,
                ),
                FitButton(
                  label: 'Trocar exercício',
                  size: FitButtonSize.compact,
                  variant: FitButtonVariant.outlined,
                  leadingIcon: Icons.swap_horiz_rounded,
                  onPressed: onSwapExercise,
                ),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s24),
          FitButton(
            label: 'Continuar treino',
            leadingIcon: Icons.play_arrow_rounded,
            expand: true,
            onPressed: onResume,
          ),
          const SizedBox(height: FitSpacing.s12),
          FitButton(
            label: 'Encerrar e salvar',
            leadingIcon: Icons.stop_circle_outlined,
            expand: true,
            variant: FitButtonVariant.outlined,
            onPressed: onEnd,
          ),
          const SizedBox(height: FitSpacing.s12),
          FitButton(
            label: 'Descartar treino',
            leadingIcon: Icons.delete_outline_rounded,
            expand: true,
            variant: FitButtonVariant.danger,
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}

class _StageScaffold extends StatelessWidget {
  const _StageScaffold({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(FitSpacing.s16),
              child: Column(
                children: [
                  FitHeader(
                    title: title,
                    showBackButton: true,
                    onBack: onClose,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: FitSpacing.s16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: FitSpacing.s24),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _prescription(ExercicioModel exercise) {
  final sets = exercise.series <= 0 ? 3 : exercise.series;
  final reps = exercise.repeticoes.trim().isEmpty
      ? '8-12'
      : exercise.repeticoes;
  final rest = exercise.descansoSegundos <= 0 ? 60 : exercise.descansoSegundos;
  return '$sets séries · $reps reps · ${rest}s descanso';
}
