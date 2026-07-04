import 'package:flutter/material.dart';

import 'workout_header.dart';
import 'workout_primary_action.dart';

class WorkoutScreenLayout extends StatelessWidget {
  final String title;
  final String time;
  final double progress;
  final VoidCallback onBack;
  final VoidCallback onPrimaryAction;
  final Widget child;

  const WorkoutScreenLayout({
    super.key,
    required this.title,
    required this.time,
    required this.progress,
    required this.onBack,
    required this.onPrimaryAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 430
                ? 430.0
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    WorkoutHeader(
                      title: title,
                      time: time,
                      progress: progress,
                      onBack: onBack,
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: WorkoutPrimaryAction(onTap: onPrimaryAction),
            ),
          ),
        ),
      ),
    );
  }
}
