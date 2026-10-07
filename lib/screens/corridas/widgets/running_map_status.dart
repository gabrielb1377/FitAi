import 'package:flutter/material.dart';

import '../../../features/activities/application/running_map_controller.dart';
import '../../../services/running_location_source.dart';

/// Status text uses the existing permission state, without requesting it.
String runningMapStatus(RunningMapController map) {
  if (map.availability == RunningMapAvailability.unavailable) {
    return 'Mapa indisponível. A corrida continua.';
  }
  if (map.availability == RunningMapAvailability.tilesUnavailable) {
    return 'Mapa base indisponível. A rota local continua.';
  }
  return switch (map.locationStatus) {
    RunningLocationStatus.permissionDenied =>
      'Permissão de localização negada.',
    RunningLocationStatus.permissionDeniedForever =>
      'Localização bloqueada nas configurações do dispositivo.',
    RunningLocationStatus.serviceDisabled =>
      'Ative a localização do dispositivo.',
    RunningLocationStatus.unavailable => 'Localização indisponível.',
    _ =>
      map.currentPosition == null ? 'Aguardando posição aceita pelo GPS.' : '',
  };
}

class RunningMapFallback extends StatelessWidget {
  const RunningMapFallback({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(child: Icon(Icons.map_outlined)),
  );
}
