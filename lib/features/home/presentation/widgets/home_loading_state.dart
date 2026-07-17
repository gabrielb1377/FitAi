import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeLoadingState extends StatelessWidget {
  const HomeLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitSkeleton(height: 210),
        SizedBox(height: FitSpacing.s24),
        FitSkeleton(height: 18, width: 96),
        SizedBox(height: FitSpacing.s12),
        FitSkeleton(height: 118),
        SizedBox(height: FitSpacing.s24),
        FitSkeleton(height: 150),
      ],
    );
  }
}
