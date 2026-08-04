import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

/// Skeleton da pagina para manter a geometria durante a leitura local.
class ProfileLoadingView extends StatelessWidget {
  const ProfileLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s20,
        FitSpacing.s16,
        FitSpacing.s20,
        FitSpacing.s32,
      ),
      children: [
        const FitSkeleton(height: FitLayout.topBarHeight),
        const SizedBox(height: FitSpacing.s16),
        const FitSkeleton(height: FitLayout.domainQuickActionMinHeight),
        const SizedBox(height: FitSpacing.s24),
        const FitSkeleton(height: FitLayout.domainQuickActionMinHeight),
        const SizedBox(height: FitSpacing.s24),
        const FitSkeleton(height: FitLayout.domainQuickActionMinHeight),
      ],
    );
  }
}
