import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeLoadingState extends StatelessWidget {
  const HomeLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FitSkeleton(height: 132),
        SizedBox(height: FitSpacing.s16),
        FitSkeleton(height: 76),
        SizedBox(height: FitSpacing.s16),
        FitSkeleton(height: 236),
        SizedBox(height: FitSpacing.s16),
        FitSkeleton(height: 64),
        SizedBox(height: FitSpacing.s16),
        FitSkeleton(height: 96),
      ],
    );
  }
}
