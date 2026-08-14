import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import 'workout_session_chrome.dart';
import 'workout_session_exercise_panel.dart';
import 'workout_session_models.dart';

/// Superficie oficial da execucao de treino.
///
/// O widget recebe apenas estado projetado e callbacks da sessao. Regras de
/// persistencia, descanso, historico e finalizacao permanecem no controlador
/// chamador.
class OfficialWorkoutSession extends StatelessWidget {
  const OfficialWorkoutSession({
    super.key,
    required this.title,
    required this.elapsedTime,
    required this.exercise,
    required this.exerciseIndex,
    required this.exerciseCount,
    required this.completedSets,
    required this.targetSets,
    required this.repetitionsController,
    required this.weightController,
    required this.restSeconds,
    required this.isResting,
    required this.progress,
    required this.history,
    required this.quickActions,
    required this.onClose,
    required this.onMenu,
    required this.onViewExecution,
    required this.onViewMuscles,
    required this.onCompleteSet,
    required this.onRestTap,
    required this.onViewAllHistory,
    required this.onChanged,
    this.restTotalSeconds = 60,
    this.restPaused = false,
    this.nextExerciseName,
    this.onRestTogglePause,
    this.onRestSkip,
    this.onRestAddTime,
    this.onPrevious,
    this.onNext,
  });

  final String title;
  final String elapsedTime;
  final ExercicioModel exercise;
  final int exerciseIndex;
  final int exerciseCount;
  final int completedSets;
  final int targetSets;
  final TextEditingController repetitionsController;
  final TextEditingController weightController;
  final int restSeconds;
  final bool isResting;
  final double progress;
  final List<WorkoutSetSnapshot> history;
  final List<WorkoutQuickAction> quickActions;
  final VoidCallback onClose;
  final VoidCallback onMenu;
  final VoidCallback onViewExecution;
  final VoidCallback onViewMuscles;
  final Future<void> Function() onCompleteSet;
  final VoidCallback onRestTap;
  final VoidCallback onViewAllHistory;
  final ValueChanged<String> onChanged;
  final int restTotalSeconds;
  final bool restPaused;
  final String? nextExerciseName;
  final VoidCallback? onRestTogglePause;
  final VoidCallback? onRestSkip;
  final VoidCallback? onRestAddTime;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final coachAction = _actionNamed('Coach IA');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: FitColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                FitSpacing.s20,
                FitSpacing.s16,
                FitSpacing.s20,
                FitSpacing.s32 + bottomInset,
              ),
              children: [
                WorkoutSessionHeader(
                  title: title,
                  elapsedLabel: _elapsedLabel(elapsedTime),
                  onClose: onClose,
                  onMenu: onMenu,
                ),
                const SizedBox(height: FitSpacing.s20),
                WorkoutProgressHeader(
                  progress: progress,
                  exerciseIndex: exerciseIndex + 1,
                  exerciseCount: exerciseCount,
                ),
                const SizedBox(height: FitSpacing.s20),
                WorkoutExercisePanel(
                  exercise: exercise,
                  exerciseNumber: exerciseIndex + 1,
                  targetSets: targetSets,
                  completedSets: completedSets,
                  repetitionsController: repetitionsController,
                  weightController: weightController,
                  restSeconds: restSeconds,
                  isResting: isResting,
                  restTotalSeconds: restTotalSeconds,
                  restPaused: restPaused,
                  nextExerciseName: nextExerciseName,
                  history: history,
                  onViewExecution: onViewExecution,
                  onViewMuscles: onViewMuscles,
                  onCoach: coachAction?.onTap,
                  onCompleteSet: onCompleteSet,
                  onRestTap: onRestTap,
                  onViewAllHistory: onViewAllHistory,
                  onChanged: onChanged,
                  onRestTogglePause: onRestTogglePause,
                  onRestSkip: onRestSkip,
                  onRestAddTime: onRestAddTime,
                ),
                const SizedBox(height: FitSpacing.s20),
                WorkoutQuickActionsPanel(actions: quickActions),
                const SizedBox(height: FitSpacing.s20),
                WorkoutSessionBottomNavigation(
                  exerciseIndex: exerciseIndex,
                  exerciseCount: exerciseCount,
                  onPrevious: onPrevious,
                  onNext: onNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  WorkoutQuickAction? _actionNamed(String label) {
    for (final action in quickActions) {
      if (action.label == label) return action;
    }
    return null;
  }

  String _elapsedLabel(String value) {
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null)) return value;
    final hours = parts[0]!;
    final minutes = parts[1]!;
    final seconds = parts[2]!;
    final prefix = hours == 0
        ? minutes.toString().padLeft(2, '0')
        : '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    return '$prefix:${seconds.toString().padLeft(2, '0')}';
  }
}
