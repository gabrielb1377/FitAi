import 'package:flutter/material.dart';

import '../../../../screens/treinos/treinos_page.dart';

/// Adapter incremental para a raiz atual de Planos.
class PlansRootPage extends StatelessWidget {
  const PlansRootPage({super.key, this.onXpUpdated, this.onBack});

  final Future<void> Function()? onXpUpdated;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return TreinosPage(onXpAtualizado: onXpUpdated, onBack: onBack);
  }
}
