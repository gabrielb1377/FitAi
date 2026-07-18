import 'package:flutter/material.dart';

class WorkoutSetSnapshot {
  const WorkoutSetSnapshot({
    required this.number,
    required this.weight,
    required this.repetitions,
    required this.restSeconds,
    required this.isCompleted,
    required this.isCurrent,
  });

  final int number;
  final String weight;
  final String repetitions;
  final int restSeconds;
  final bool isCompleted;
  final bool isCurrent;
}

class WorkoutQuickAction {
  const WorkoutQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
}
