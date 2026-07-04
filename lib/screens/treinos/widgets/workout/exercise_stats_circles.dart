import 'package:flutter/material.dart';

class ExerciseStatsCircles extends StatelessWidget {
  final String reps;
  final String rest;
  final String series;

  const ExerciseStatsCircles({
    super.key,
    required this.reps,
    required this.rest,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CircleStat(value: reps, label: 'RepetiÃ§Ãµes'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CircleStat(value: rest, label: 'Repouso'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CircleStat(value: series, label: 'SÃ©ries'),
        ),
      ],
    );
  }
}

class _CircleStat extends StatelessWidget {
  final String value;
  final String label;

  const _CircleStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111820),
          border: Border.all(color: const Color(0xFF233241)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5C3).withAlpha(24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF00E5C3),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
