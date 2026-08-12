import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_models.dart';

/// Armazena preferências de aparelho separadamente das preferências da conta.
abstract interface class SettingsLocalStore {
  Future<DeviceSettings?> loadDevice();
  Future<void> saveDevice(DeviceSettings value);
  Future<AccountSettings?> loadAccount(String userId);
  Future<void> saveAccount(String userId, AccountSettings value);
}

class SharedPreferencesSettingsLocalStore implements SettingsLocalStore {
  static const _deviceKey = 'fitia.settings.device.v1';
  static const _accountPrefix = 'fitia.settings.account.';

  @override
  Future<DeviceSettings?> loadDevice() =>
      _read(_deviceKey, DeviceSettings.fromJson);

  @override
  Future<void> saveDevice(DeviceSettings value) =>
      _write(_deviceKey, value.toJson());

  @override
  Future<AccountSettings?> loadAccount(String userId) =>
      _read(_accountKey(userId), AccountSettings.fromJson);

  @override
  Future<void> saveAccount(String userId, AccountSettings value) =>
      _write(_accountKey(userId), value.toJson());

  Future<T?> _read<T>(String key, T Function(Object?) converter) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return converter(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<void> _write(String key, Map<String, Object> value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(key, jsonEncode(value));
    if (!saved) {
      throw StateError('Nao foi possivel salvar as configuracoes locais.');
    }
  }

  String _accountKey(String userId) =>
      '$_accountPrefix${_safeUserId(userId)}.v1';

  String _safeUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return 'local';
    return normalized.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}

class InMemorySettingsLocalStore implements SettingsLocalStore {
  DeviceSettings? device;
  final Map<String, AccountSettings> accounts = {};
  bool failNextWrite = false;

  @override
  Future<DeviceSettings?> loadDevice() async => device;

  @override
  Future<void> saveDevice(DeviceSettings value) async {
    _throwIfNeeded();
    device = value;
  }

  @override
  Future<AccountSettings?> loadAccount(String userId) async => accounts[userId];

  @override
  Future<void> saveAccount(String userId, AccountSettings value) async {
    _throwIfNeeded();
    accounts[userId] = value;
  }

  void _throwIfNeeded() {
    if (!failNextWrite) return;
    failNextWrite = false;
    throw StateError('Falha de persistencia simulada.');
  }
}
