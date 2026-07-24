import 'package:flutter/material.dart';

import '../../../../screens/atividades_page.dart';

/// Adapter incremental para o hub atual de Atividades.
class ActivitiesRootPage extends StatelessWidget {
  const ActivitiesRootPage({
    super.key,
    required this.steps,
    required this.distance,
    required this.averageSpeed,
    required this.elapsedSeconds,
    required this.running,
    required this.onStartRunning,
    required this.onStopRunning,
  });

  final int steps;
  final double distance;
  final double averageSpeed;
  final int elapsedSeconds;
  final bool running;
  final VoidCallback onStartRunning;
  final VoidCallback onStopRunning;

  @override
  Widget build(BuildContext context) {
    return AtividadesPage(
      passos: steps,
      distancia: distance,
      velocidadeMedia: averageSpeed,
      segundos: elapsedSeconds,
      corridaIniciada: running,
      iniciarCorrida: onStartRunning,
      pararCorrida: onStopRunning,
    );
  }
}
