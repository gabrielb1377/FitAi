import 'package:flutter/material.dart';

import '../../../../models/exercicio_model.dart';

class ExerciseGifCard extends StatelessWidget {
  final ExercicioModel exercicio;

  const ExerciseGifCard({super.key, required this.exercicio});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4F6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.fitness_center_rounded,
              size: 76,
              color: Colors.black.withAlpha(80),
            ),
          ),
          const Positioned(left: 18, top: 18, child: _MiniBadge(label: 'GIF')),
          Positioned(
            right: 18,
            top: 18,
            child: _MiniBadge(label: exercicio.categoria),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(145),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
