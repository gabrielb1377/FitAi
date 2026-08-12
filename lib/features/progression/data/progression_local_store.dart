import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/progression_models.dart';

abstract interface class ProgressionLocalStore {
  Future<ProgressionSnapshot?> load(String userId);
  Future<void> save(ProgressionSnapshot snapshot);
}

/// Um unico documento JSON evita gravacoes parciais entre XP, metas e marcos.
class SharedPreferencesProgressionStore implements ProgressionLocalStore {
  static const _legacyKey = 'fitia_progression_v1';
  static const _keyPrefix = 'fitia.progression.v2.user.';

  @override
  Future<ProgressionSnapshot?> load(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final scoped = _decode(preferences.getString(_keyFor(userId)));
    if (scoped != null) return scoped;

    // A chave v1 nao continha dono confiavel. Somente o perfil local anonimo
    // pode le-la; contas autenticadas iniciam um documento proprio e seguro.
    return _safeUserId(userId) == 'local'
        ? _decode(preferences.getString(_legacyKey))
        : null;
  }

  @override
  Future<void> save(ProgressionSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _keyFor(snapshot.userId),
      jsonEncode(snapshot.toJson()),
    );
    if (!saved) {
      throw StateError('Nao foi possivel persistir a progressao local.');
    }
  }

  ProgressionSnapshot? _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ProgressionSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  String _keyFor(String userId) => '$_keyPrefix${_safeUserId(userId)}.v1';

  static String _safeUserId(String userId) {
    final normalized = userId.trim().toLowerCase();
    if (normalized.isEmpty) return 'local';
    return normalized.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
  }
}

class InMemoryProgressionStore implements ProgressionLocalStore {
  final Map<String, ProgressionSnapshot> _values = {};
  bool failNextSave = false;

  @override
  Future<ProgressionSnapshot?> load(String userId) async => _values[userId];

  @override
  Future<void> save(ProgressionSnapshot snapshot) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Falha de persistencia simulada.');
    }
    _values[snapshot.userId] = snapshot;
  }
}
