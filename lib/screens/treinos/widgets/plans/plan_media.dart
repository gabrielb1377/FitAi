import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/treino_model.dart';

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
    final path = _path;
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: FitColors.surfaceVariant,
          child: path.isEmpty ? _fallback() : _image(path),
        ),
      ),
    );
  }

  String get _path {
    final gif = exercise?.gifPath.trim() ?? '';
    if (gif.isNotEmpty) return gif;
    return exercise?.imagem.trim() ?? '';
  }

  Widget _image(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return Image.asset(
      path,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _fallback(),
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
