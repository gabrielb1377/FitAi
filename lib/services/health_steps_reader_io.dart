import 'dart:io';

import 'package:health_connector/health_connector.dart';

import '../features/activities/domain/steps_health_source.dart';

class PlatformStepsHealthSource implements StepsHealthSource {
  HealthConnector? _connector;

  StepsHealthProvider get _provider => Platform.isAndroid
      ? StepsHealthProvider.healthConnect
      : Platform.isIOS
      ? StepsHealthProvider.healthKit
      : StepsHealthProvider.none;

  @override
  Future<StepsHealthStatus> checkStatus({
    bool requestPermission = false,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const StepsHealthStatus.notSupported();
    }

    try {
      final platformStatus = await HealthConnector.getHealthPlatformStatus();
      if (platformStatus != HealthPlatformStatus.available) {
        final needsInstall =
            platformStatus == HealthPlatformStatus.installationOrUpdateRequired;
        return StepsHealthStatus(
          provider: _provider,
          platformSupported: true,
          available: false,
          permission: StepsHealthPermissionState.unavailable,
          message: needsInstall
              ? 'Instale ou atualize o Health Connect para importar passos.'
              : 'A fonte de saude nao esta disponivel neste dispositivo.',
        );
      }

      final connector = await _ensureConnector();
      var permission = await connector.getPermissionStatus(
        HealthDataType.steps.readPermission,
      );
      if (permission != PermissionStatus.granted && requestPermission) {
        final results = await connector.requestPermissions([
          HealthDataType.steps.readPermission,
        ]);
        if (results.isNotEmpty) permission = results.first.status;
      }

      final mapped = switch (permission) {
        PermissionStatus.granted => StepsHealthPermissionState.granted,
        PermissionStatus.denied => StepsHealthPermissionState.denied,
        PermissionStatus.unknown => StepsHealthPermissionState.unknown,
      };
      return StepsHealthStatus(
        provider: _provider,
        platformSupported: true,
        available: true,
        permission: mapped,
        message: _permissionMessage(mapped),
      );
    } on Object {
      return StepsHealthStatus(
        provider: _provider,
        platformSupported: true,
        available: false,
        permission: StepsHealthPermissionState.unavailable,
        message: 'A fonte de saude esta temporariamente indisponivel.',
      );
    }
  }

  @override
  Future<StepsHealthReadResult> readDailyTotal({
    required DateTime start,
    required DateTime end,
    bool requestPermission = false,
  }) async {
    final status = await checkStatus(requestPermission: requestPermission);
    if (!status.canAttemptRead) {
      return StepsHealthReadResult(status: status, readAt: DateTime.now());
    }

    try {
      final connector = await _ensureConnector();
      final result = await connector.aggregate(
        HealthDataType.steps.aggregateSum(startTime: start, endTime: end),
      );
      final total = result.value.isFinite ? result.value.round() : 0;
      return StepsHealthReadResult(
        status: status,
        readAt: DateTime.now(),
        totalSteps: total < 0 ? 0 : total,
      );
    } on AuthorizationException {
      return StepsHealthReadResult(
        status: StepsHealthStatus(
          provider: _provider,
          platformSupported: true,
          available: true,
          permission: StepsHealthPermissionState.denied,
          message: 'Permissao para ler passos nao concedida.',
        ),
        readAt: DateTime.now(),
      );
    } on Object {
      return StepsHealthReadResult(
        status: StepsHealthStatus(
          provider: _provider,
          platformSupported: true,
          available: true,
          permission: status.permission,
          message:
              'Falha temporaria ao ler passos. O ultimo valor foi mantido.',
        ),
        readAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> dispose() async {
    _connector = null;
  }

  Future<HealthConnector> _ensureConnector() async {
    return _connector ??= await HealthConnector.create();
  }

  String _permissionMessage(StepsHealthPermissionState permission) {
    final provider = _provider == StepsHealthProvider.healthKit
        ? 'Apple Health'
        : 'Health Connect';
    return switch (permission) {
      StepsHealthPermissionState.granted => '$provider conectado.',
      StepsHealthPermissionState.unknown =>
        '$provider disponivel; a permissao sera confirmada pela leitura.',
      StepsHealthPermissionState.denied =>
        'Permissao para ler passos nao concedida.',
      _ => '$provider indisponivel.',
    };
  }
}

typedef PlatformHealthStepsReader = PlatformStepsHealthSource;
