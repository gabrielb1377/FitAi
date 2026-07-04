import 'package:flutter/material.dart';

class WorkoutEmptyState extends StatelessWidget {
  const WorkoutEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Este treino nÃ£o possui exercÃ­cios.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withAlpha(160),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
