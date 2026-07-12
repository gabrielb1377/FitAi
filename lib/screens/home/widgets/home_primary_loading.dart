import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

/// Skeleton da acao principal enquanto a selecao do treino e carregada.
class HomePrimaryLoading extends StatelessWidget {
  const HomePrimaryLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitCard(
      variant: FitCardVariant.filled,
      elevation: 1,
      child: FitListSkeleton(
        itemCount: 2,
        itemHeight: 28,
        padding: EdgeInsets.zero,
        spacing: FitSpacing.s12,
      ),
    );
  }
}
