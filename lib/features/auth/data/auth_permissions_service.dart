import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/steps_service.dart';

enum AuthPermissionType { activity, location, notifications, healthConnect }

enum AuthPermissionStatus { pending, granted, denied, unavailable }

extension AuthPermissionStatusLabel on AuthPermissionStatus {
  String get label => switch (this) {
    AuthPermissionStatus.pending => 'Pendente',
    AuthPermissionStatus.granted => 'Permitida',
    AuthPermissionStatus.denied => 'Agora nao',
    AuthPermissionStatus.unavailable => 'Indisponivel',
  };
}

/// Solicita somente a permissao escolhida pelo usuario e guarda sua decisao
/// localmente. Nenhuma permissao e disparada automaticamente ao abrir a tela.
class AuthPermissionsService {
  static const _keyPrefix = 'fitai.auth.permission.v1.';

  Future<Map<AuthPermissionType, AuthPermissionStatus>> loadStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final type in AuthPermissionType.values)
        type: _readStatus(prefs, type),
    };
  }

  Future<AuthPermissionStatus> request(AuthPermissionType type) async {
    final status = switch (type) {
      AuthPermissionType.location => await _requestLocation(),
      AuthPermissionType.activity ||
      AuthPermissionType.healthConnect => await _requestHealthConnect(),
      AuthPermissionType.notifications => AuthPermissionStatus.unavailable,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(type), status.name);
    return status;
  }

  AuthPermissionStatus _readStatus(
    SharedPreferences prefs,
    AuthPermissionType type,
  ) {
    final value = prefs.getString(_keyFor(type));
    if (value == null && type == AuthPermissionType.notifications) {
      return AuthPermissionStatus.unavailable;
    }
    return AuthPermissionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AuthPermissionStatus.pending,
    );
  }

  Future<AuthPermissionStatus> _requestLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return AuthPermissionStatus.denied;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse
          ? AuthPermissionStatus.granted
          : AuthPermissionStatus.denied;
    } on Object catch (error) {
      _debugLog('Localizacao indisponivel: $error');
      return AuthPermissionStatus.unavailable;
    }
  }

  Future<AuthPermissionStatus> _requestHealthConnect() async {
    try {
      final steps = StepsService.instance;
      await steps.initialize();
      await steps.syncNow(requestPermission: true);

      if (steps.permissionGranted) return AuthPermissionStatus.granted;
      return steps.platformSupported
          ? AuthPermissionStatus.denied
          : AuthPermissionStatus.unavailable;
    } on Object catch (error) {
      _debugLog('Health Connect indisponivel: $error');
      return AuthPermissionStatus.unavailable;
    }
  }

  String _keyFor(AuthPermissionType type) => '$_keyPrefix${type.name}';

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[AuthPermissions] $message');
  }
}
