import 'dart:io';

import 'package:health_connector/health_connector.dart';

class HealthStepsAvailability {
  const HealthStepsAvailability({
    required this.platformSupported,
    required this.available,
    required this.message,
  });

  final bool platformSupported;
  final bool available;
  final String message;
}

class PlatformHealthStepsReader {
  HealthConnector? _connector;

  Future<HealthStepsAvailability> checkAvailability() async {
    if (!Platform.isAndroid) {
      return const HealthStepsAvailability(
        platformSupported: false,
        available: false,
        message: 'Health Connect indisponivel nesta plataforma.',
      );
    }

    final status = await HealthConnector.getHealthPlatformStatus();
    switch (status) {
      case HealthPlatformStatus.available:
        await _ensureConnector();
        return const HealthStepsAvailability(
          platformSupported: true,
          available: true,
          message: 'Health Connect disponivel.',
        );
      case HealthPlatformStatus.installationOrUpdateRequired:
        return const HealthStepsAvailability(
          platformSupported: true,
          available: false,
          message:
              'Instale ou atualize o Health Connect para ler passos reais.',
        );
      case HealthPlatformStatus.unavailable:
        return const HealthStepsAvailability(
          platformSupported: false,
          available: false,
          message: 'Health Connect indisponivel neste aparelho.',
        );
    }
  }

  Future<bool> ensureStepsPermission({required bool requestPermission}) async {
    final connector = await _ensureConnector();
    if (connector == null) return false;

    final permission = HealthDataType.steps.readPermission;
    final currentStatus = await connector.getPermissionStatus(permission);
    if (currentStatus == PermissionStatus.granted) return true;
    if (!requestPermission) return false;

    final results = await connector.requestPermissions([permission]);
    return results.any((result) => result.status == PermissionStatus.granted);
  }

  Future<int> readSteps({
    required DateTime start,
    required DateTime end,
  }) async {
    final connector = await _ensureConnector();
    if (connector == null) return 0;

    final result = await connector.aggregate(
      HealthDataType.steps.aggregateSum(startTime: start, endTime: end),
    );

    return result.value < 0 ? 0 : result.value.round();
  }

  Future<HealthConnector?> _ensureConnector() async {
    if (!Platform.isAndroid) return null;
    _connector ??= await HealthConnector.create();
    return _connector;
  }
}
