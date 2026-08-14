import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../features/settings/application/settings_runtime.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/treinos/controllers/plan_day_data.dart';
import '../../../../screens/treinos/exercicio_detalhe_page.dart';
import '../../../../screens/treinos/treino_em_andamento_page.dart';
import '../../../../screens/treinos/workout_day_page.dart';
import '../widgets/workout_preparation_content.dart';

/// WORK-001. Prévia de um treino pertencente a um plano.
///
/// A página deriva apenas métricas presentes no plano e não cria uma sessão.
class WorkoutPreviewPage extends StatefulWidget {
  const WorkoutPreviewPage({super.key, required this.plan, required this.day});

  final TreinoModel plan;
  final PlanDayData day;

  @override
  State<WorkoutPreviewPage> createState() => _WorkoutPreviewPageState();
}

class _WorkoutPreviewPageState extends State<WorkoutPreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth > 640 ? 640 : constraints.maxWidth,
              height: constraints.maxHeight,
              child: WorkoutPreparationContent(
                workoutName: widget.day.title,
                planLabel: '${widget.plan.objetivo} · ${widget.day.label}',
                exercises: widget.day.workout.exercicios,
                estimatedMinutes: _minutes(widget.plan),
                defaultRestSeconds:
                    WorkoutSettingsRuntime.rest.defaultRestSeconds,
                onBack: () => Navigator.of(context).maybePop(),
                onOpenExercise: _openExercise,
                onOpenExerciseList: _openExerciseList,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.day.workout.exercicios.isEmpty
          ? null
          : _WorkoutPreparationStartBar(onStart: _startWorkout),
    );
  }

  int _minutes(TreinoModel plan) =>
      plan.tempoEstimado <= 0 ? 45 : plan.tempoEstimado;

  Future<void> _startWorkout() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TreinoEmAndamentoPage(
        treino: widget.day.workout,
        nomeDia: widget.day.label,
        grupoDia: widget.day.title,
      ),
    ),
  );

  void _openExercise(ExercicioModel exercise) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExercicioDetalhePage(exercicio: exercise),
      ),
    );
  }

  void _openExerciseList() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkoutDayPage(plan: widget.plan, day: widget.day),
      ),
    );
  }
}

class _WorkoutPreparationStartBar extends StatelessWidget {
  const _WorkoutPreparationStartBar({required this.onStart});

  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FitColors.background,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          FitSpacing.s16,
          FitSpacing.s8,
          FitSpacing.s16,
          FitSpacing.s16,
        ),
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: FitButton(
              label: 'Iniciar treino',
              leadingIcon: FitIcons.play,
              semanticLabel: 'Iniciar treino',
              tooltip: 'Iniciar treino',
              expand: true,
              size: FitButtonSize.large,
              onPressedAsync: onStart,
            ),
          ),
        ),
      ),
    );
  }
}
