import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/progression_models.dart';

abstract interface class ProgressionLocalStore {
  Future<ProgressionSnapshot?> load();
  Future<void> save(ProgressionSnapshot snapshot);
}

/// Um unico documento JSON evita gravacoes parciais entre XP, metas e marcos.
class SharedPreferencesProgressionStore implements ProgressionLocalStore {
  static const _key = 'fitia_progression_v1';

  @override
  Future<ProgressionSnapshot?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return ProgressionSnapshot.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> save(ProgressionSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _key,
      jsonEncode(snapshot.toJson()),
    );
    if (!saved) {
      throw StateError('Nao foi possivel persistir a progressao local.');
    }
  }
}

class InMemoryProgressionStore implements ProgressionLocalStore {
  ProgressionSnapshot? value;
  bool failNextSave = false;

  @override
  Future<ProgressionSnapshot?> load() async => value;

  @override
  Future<void> save(ProgressionSnapshot snapshot) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Falha de persistencia simulada.');
    }
    value = snapshot;
  }
}
