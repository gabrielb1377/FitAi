import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delimita os dados locais legados que ainda nao possuem namespace proprio.
///
/// O journal do treino, Configuracoes e Progressao moderna usam chaves por
/// usuario. Os dados legados ainda centralizados no SharedPreferences sao
/// arquivados ao alternar de conta e restaurados somente para seu proprietario.
/// Nada e apagado durante logout: a troca acontece antes da nova sessao.
class LocalAccountDataBoundary {
  LocalAccountDataBoundary({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _ownerKey = 'fitia.localAccountBoundary.owner.v1';
  static const _archivePrefix = 'fitia.localAccountBoundary.archive.';
  static const _legacyScope = 'legacy-unowned';

  final Future<SharedPreferences> Function() _preferencesLoader;
  static Future<void> _serial = Future<void>.value();

  /// Torna [userId] o dono ativo dos dados legados deste dispositivo.
  ///
  /// Uma sessao restaurada pode reivindicar dados sem dono, pois a identidade
  /// ja existia antes desta versao. Um login novo preserva esse dado ambiguo
  /// em `legacy-unowned`, sem entrega-lo a uma conta diferente.
  Future<void> activate(String userId, {bool claimUnownedData = false}) =>
      _enqueue(() async {
        final preferences = await _preferencesLoader();
        final nextOwner = _scope(userId);
        final currentOwner = preferences.getString(_ownerKey);

        if (currentOwner == nextOwner) return;

        if (currentOwner == null || currentOwner.isEmpty) {
          if (_accountKeys(preferences).isNotEmpty) {
            await _archiveAndClear(
              preferences,
              claimUnownedData ? nextOwner : _legacyScope,
            );
          }
        } else {
          await _archiveAndClear(preferences, _scope(currentOwner));
        }

        await _restore(preferences, nextOwner);
        final saved = await preferences.setString(_ownerKey, nextOwner);
        if (!saved) {
          throw StateError('Nao foi possivel definir a conta local ativa.');
        }
      });

  /// Retorna o dono ativo dos dados legados, sem expor o conteúdo arquivado.
  ///
  /// O valor é usado pelo fluxo de autenticação para restaurar a conta anterior
  /// se o armazenamento seguro da nova sessão falhar durante uma troca.
  Future<String?> activeOwner() => _enqueue(() async {
    final preferences = await _preferencesLoader();
    return preferences.getString(_ownerKey);
  });

  /// Retorna o mesmo escopo seguro usado para identificar o dono local.
  ///
  /// Consumidores que migram dados legados podem comparar este valor com
  /// [activeOwner] sem replicar a normalizacao do identificador de conta.
  static String scopeForUser(String userId) => _scope(userId);

  Future<void> _archiveAndClear(
    SharedPreferences preferences,
    String scope,
  ) async {
    final keys = _accountKeys(preferences).toList(growable: false);
    if (keys.isEmpty) return;
    final values = <String, Object>{};
    for (final key in keys) {
      final entry = _encodeValue(preferences.get(key));
      if (entry != null) values[key] = entry;
    }
    final payload = jsonEncode({
      'version': 1,
      'owner': scope,
      'archivedAt': DateTime.now().toUtc().toIso8601String(),
      'values': values,
    });
    final archived = await preferences.setString(_archiveKey(scope), payload);
    if (!archived) {
      throw StateError('Nao foi possivel preservar os dados locais da conta.');
    }
    for (final key in keys) {
      final removed = await preferences.remove(key);
      if (!removed) {
        throw StateError('Nao foi possivel isolar os dados locais da conta.');
      }
    }
  }

  Future<void> _restore(SharedPreferences preferences, String scope) async {
    final raw = preferences.getString(_archiveKey(scope));
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['values'] is! Map) return;
      final values = Map<String, dynamic>.from(decoded['values'] as Map);
      for (final entry in values.entries) {
        if (!_isAccountDataKey(entry.key) || entry.value is! Map) continue;
        await _restoreValue(
          preferences,
          entry.key,
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    } on FormatException {
      // O arquivo corrompido fica preservado para recuperacao assistida.
    }
  }

  Set<String> _accountKeys(SharedPreferences preferences) =>
      preferences.getKeys().where(_isAccountDataKey).toSet();

  bool _isAccountDataKey(String key) =>
      !_isReservedKey(key) && !key.startsWith('flutter.');

  bool _isReservedKey(String key) =>
      key == _ownerKey ||
      key.startsWith(_archivePrefix) ||
      key.startsWith('fitia.auth.') ||
      key.startsWith('fitia.settings.device.') ||
      key.startsWith('fitia.settings.account.') ||
      key.startsWith('fitia.progression.v2.user.') ||
      key.startsWith('fitia.aiChat.v1.user.') ||
      key.startsWith('fitia.workoutVerticalSlice.v1.user.');

  Object? _encodeValue(Object? value) {
    if (value is String) return {'type': 'string', 'value': value};
    if (value is bool) return {'type': 'bool', 'value': value};
    if (value is int) return {'type': 'int', 'value': value};
    if (value is double) return {'type': 'double', 'value': value};
    if (value is List<String>) return {'type': 'stringList', 'value': value};
    return null;
  }

  Future<void> _restoreValue(
    SharedPreferences preferences,
    String key,
    Map<String, dynamic> entry,
  ) async {
    final type = entry['type'];
    final value = entry['value'];
    final saved = switch (type) {
      'string' when value is String => await preferences.setString(key, value),
      'bool' when value is bool => await preferences.setBool(key, value),
      'int' when value is int => await preferences.setInt(key, value),
      'double' when value is double => await preferences.setDouble(key, value),
      'stringList' when value is List => await preferences.setStringList(
        key,
        value.whereType<String>().toList(growable: false),
      ),
      _ => true,
    };
    if (!saved) {
      throw StateError('Nao foi possivel restaurar dados locais da conta.');
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _serial.then((_) => action());
    _serial = result.then<void>((_) {}, onError: (error, stackTrace) {});
    return result;
  }

  String _archiveKey(String scope) => '$_archivePrefix${_scope(scope)}.v1';

  static String _scope(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'local';
    return normalized.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
  }
}

/// Sinal interno para caches de preferencias que dependem da conta ativa.
abstract final class AccountSessionLifecycle {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static String? _activeUserId;

  static String? get activeUserId => _activeUserId;

  static void setActiveUser(String? userId) {
    final normalized = userId?.trim();
    final next = normalized == null || normalized.isEmpty ? null : normalized;
    if (_activeUserId == next) return;
    _activeUserId = next;
    revision.value += 1;
  }
}
