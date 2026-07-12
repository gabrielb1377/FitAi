import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class ReadyPlansLoading extends StatelessWidget {
  const ReadyPlansLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return FitListSkeleton(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemHeight: 126,
    );
  }
}
