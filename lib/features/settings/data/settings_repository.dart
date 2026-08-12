import 'dart:async';

import '../../../core/config/dev_config.dart';
import '../../auth/data/auth_service.dart';
import '../domain/settings_models.dart';
import 'settings_local_store.dart';

typedef SettingsUserIdResolver = Future<String> Function();

/// Repositorio da unica fonte local para Configuracoes.
///
/// O documento do aparelho sobrevive ao logout. O documento da conta e
/// namespaced pelo usuario para impedir que preferencias de pessoas distintas
/// sejam misturadas no mesmo dispositivo.
class SettingsRepository {
  SettingsRepository({
    required this.store,
    SettingsUserIdResolver? userIdResolver,
  }) : _userIdResolver = userIdResolver ?? _resolveCurrentUserId;

  factory SettingsRepository.local() =>
      SettingsRepository(store: SharedPreferencesSettingsLocalStore());

  final SettingsLocalStore store;
  final SettingsUserIdResolver _userIdResolver;
  Future<void> _serial = Future<void>.value();

  Future<SettingsSnapshot> load() async {
    final userId = await _userIdResolver();
    final device = await store.loadDevice() ?? DeviceSettings.defaults();
    final account =
        await store.loadAccount(userId) ?? AccountSettings.defaults();
    return SettingsSnapshot(
      userId: userId,
      settings: AppSettings(
        schemaVersion: AppSettings.currentSchemaVersion,
        device: device,
        account: account,
        updatedAt: _latestUpdatedAt(device, account),
      ),
    );
  }

  Future<SettingsSnapshot> update(
    SettingsSnapshot current,
    AppSettings Function(AppSettings value) transform,
  ) => _enqueue(() async {
    final updated = transform(current.settings);
    await store.saveDevice(updated.device);
    await store.saveAccount(current.userId, updated.account);
    return SettingsSnapshot(userId: current.userId, settings: updated);
  });

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _serial.then((_) => action());
    _serial = result.then<void>((_) {}, onError: (error, stackTrace) {});
    return result;
  }

  static Future<String> _resolveCurrentUserId() async {
    final session = await AuthService(bypassLogin: false).restoreSession();
    if (session != null) return session.userId;
    return DevConfig.enabled && DevConfig.fakeUser ? 'debug-gabriel' : 'local';
  }

  static DateTime _latestUpdatedAt(
    DeviceSettings device,
    AccountSettings account,
  ) {
    final values = <DateTime>[
      device.appearance.metadata.updatedAt,
      device.locale.metadata.updatedAt,
      account.units.metadata.updatedAt,
      account.workout.metadata.updatedAt,
      account.rest.metadata.updatedAt,
      account.notifications.metadata.updatedAt,
      account.privacy.metadata.updatedAt,
      account.security.metadata.updatedAt,
      account.sync.metadata.updatedAt,
      account.integrations.metadata.updatedAt,
    ];
    return values.reduce(
      (latest, value) => value.isAfter(latest) ? value : latest,
    );
  }
}

class SettingsSnapshot {
  const SettingsSnapshot({required this.userId, required this.settings});

  final String userId;
  final AppSettings settings;
}
