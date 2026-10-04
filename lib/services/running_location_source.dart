import 'package:geolocator/geolocator.dart';

/// Estado da fronteira de localizacao usado pelo ciclo de vida da corrida.
///
/// O dominio recebe somente este estado e [RunningLocationSample], sem expor
/// tipos do plugin de plataforma para a logica de distancia, rota ou recovery.
enum RunningLocationStatus {
  idle,
  available,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

/// Amostra de localizacao independente da implementacao nativa.
///
/// Metadados podem ser nulos quando a plataforma nao os disponibiliza. A
/// validacao de coordenadas e das regras de corrida pertence ao core.
class RunningLocationSample {
  const RunningLocationSample({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.speedMps,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? altitude;
  final double? speedMps;
}

/// Fonte de localizacao da corrida.
///
/// A implementacao de producao encapsula o Geolocator. Testes podem fornecer
/// uma fonte deterministica sem plugins, dispositivos ou permissao nativa.
abstract interface class RunningLocationSource {
  Future<RunningLocationStatus> ensureReady();

  Stream<RunningLocationSample> get samples;
}

class GeolocatorRunningLocationSource implements RunningLocationSource {
  const GeolocatorRunningLocationSource();

  @override
  Future<RunningLocationStatus> ensureReady() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return RunningLocationStatus.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => RunningLocationStatus.available,
        LocationPermission.denied => RunningLocationStatus.permissionDenied,
        LocationPermission.deniedForever =>
          RunningLocationStatus.permissionDeniedForever,
        _ => RunningLocationStatus.unavailable,
      };
    } on Object {
      return RunningLocationStatus.unavailable;
    }
  }

  @override
  Stream<RunningLocationSample> get samples =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).map(
        (position) => RunningLocationSample(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speedMps: position.speed,
        ),
      );
}
