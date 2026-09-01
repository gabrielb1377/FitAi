import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../widgets/exercicio_gif_viewer.dart';

class PlanMedia extends StatelessWidget {
  const PlanMedia({
    super.key,
    required this.plan,
    this.width,
    this.height,
    this.borderRadius = FitRadius.largeBorder,
    this.fit = BoxFit.cover,
  });

  final TreinoModel plan;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final exercise = plan.exercicios.isEmpty ? null : plan.exercicios.first;
    return ExerciseMedia(
      exercise: exercise,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: fit,
    );
  }
}

class ExerciseMedia extends StatelessWidget {
  const ExerciseMedia({
    super.key,
    required this.exercise,
    this.width,
    this.height,
    this.borderRadius = FitRadius.largeBorder,
    this.fit = BoxFit.cover,
  });

  final ExercicioModel? exercise;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final exercise = this.exercise;
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: FitColors.surfaceVariant,
          child: exercise == null
              ? _fallback()
              : ExercicioGifImage(
                  canonicalExerciseId:
                      exercise.canonicalExerciseId.trim().isNotEmpty
                      ? exercise.canonicalExerciseId
                      : exercise.id,
                  titulo: exercise.nome,
                  fit: fit,
                  placeholder: _fallback(),
                ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: FitColors.primary,
        size: 34,
      ),
    );
  }
}
