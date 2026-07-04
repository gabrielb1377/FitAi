import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'workout_header.dart';

class WorkoutMobileShell extends StatelessWidget {
  final String headerTitle;
  final String elapsedTime;
  final VoidCallback onBack;
  final Widget child;
  final Widget bottomActions;

  const WorkoutMobileShell({
    super.key,
    required this.headerTitle,
    required this.elapsedTime,
    required this.onBack,
    required this.child,
    required this.bottomActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: WorkoutHeader(
                    title: headerTitle,
                    elapsedTime: elapsedTime,
                    onBack: onBack,
                  ),
                ),
                SliverToBoxAdapter(child: child),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: bottomActions,
          ),
        ),
      ),
    );
  }
}
