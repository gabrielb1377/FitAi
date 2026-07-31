import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/workout_vertical_models.dart';

/// Contrato de persistencia local do treino e de sua outbox.
abstract interface class WorkoutVerticalLocalStore {
  Future<WorkoutSliceSnapshot> read();

  Future<void> write(WorkoutSliceSnapshot snapshot);
}

/// Journal copy-on-write com dois snapshots verificaveis.
///
/// A versao anterior gravava toda a jornada em uma unica chave. Agora uma nova
/// revisao e escrita no slot inativo e so depois se torna ativa. A revisao
/// anterior continua disponivel para recuperar escrita interrompida ou conteudo
/// corrompido no slot atual.
class SharedPreferencesWorkoutVerticalLocalStore
    implements WorkoutVerticalLocalStore {
  SharedPreferencesWorkoutVerticalLocalStore(
    this._preferences, {
    String userScope = anonymousScope,
  }) : _userScope = _normalizeScope(userScope);

  /// Chave V1 preservada apenas para migracao nao destrutiva.
  static const storageKey = 'fitai.workoutVerticalSlice.v1';
  static const anonymousScope = 'anonymous';
  static const _journalVersion = 2;

  final SharedPreferences _preferences;
  final String _userScope;

  static String storageKeyFor(String userScope) {
    final normalized = _normalizeScope(userScope);
    return normalized == anonymousScope
        ? storageKey
        : '$storageKey.user.$normalized';
  }

  static String journalActiveKeyFor(String userScope) =>
      '${storageKeyFor(userScope)}.journal.active';

  static String journalSlotAKeyFor(String userScope) =>
      '${storageKeyFor(userScope)}.journal.a';

  static String journalSlotBKeyFor(String userScope) =>
      '${storageKeyFor(userScope)}.journal.b';

  static String recoveryKeyFor(String userScope) =>
      '${storageKeyFor(userScope)}.journal.recovery';

  String get scopedStorageKey => storageKeyFor(_userScope);
  String get _activeKey => journalActiveKeyFor(_userScope);
  String get _slotAKey => journalSlotAKeyFor(_userScope);
  String get _slotBKey => journalSlotBKeyFor(_userScope);
  String get _recoveryKey => recoveryKeyFor(_userScope);

  @override
  Future<WorkoutSliceSnapshot> read() async {
    final records = _readRecords();
    final activeSlot = _preferences.getString(_activeKey);
    final active = activeSlot == 'a'
        ? records['a']
        : activeSlot == 'b'
        ? records['b']
        : null;
    if (active != null) return active.snapshot;

    final fallback = records.values.fold<_JournalRecord?>(
      null,
      (current, candidate) =>
          current == null || candidate.revision > current.revision
          ? candidate
          : current,
    );
    if (fallback != null) return fallback.snapshot;

    final legacy = _preferences.getString(scopedStorageKey);
    if (legacy == null || legacy.isEmpty) {
      if (_hasJournalData()) {
        await _preserveUnreadableData();
        throw StateError(
          'Dados locais do treino precisam de recuperacao. Uma copia foi preservada.',
        );
      }
      return const WorkoutSliceSnapshot.empty();
    }

    try {
      final snapshot = WorkoutSliceSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(legacy) as Map),
      );
      await write(snapshot);
      return snapshot;
    } on FormatException catch (error) {
      await _preserveUnreadableData(legacy: legacy);
      throw StateError(
        'Dados locais do treino invalidos e preservados para recuperacao: ${error.message}',
      );
    }
  }

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    final records = _readRecords();
    final activeSlot = _preferences.getString(_activeKey);
    final latest = records.values.fold<_JournalRecord?>(
      null,
      (current, candidate) =>
          current == null || candidate.revision > current.revision
          ? candidate
          : current,
    );
    final next = _JournalRecord.fromSnapshot(
      snapshot,
      revision: (latest?.revision ?? 0) + 1,
    );

    if (latest == null) {
      await _writeSlot('a', next);
      await _writeSlot('b', next);
      await _writeActiveSlot('a');
      return;
    }

    final String currentSlot;
    if (activeSlot == 'a' || activeSlot == 'b') {
      currentSlot = activeSlot!;
    } else {
      currentSlot = records.entries
          .firstWhere((entry) => identical(entry.value, latest))
          .key;
    }
    final targetSlot = currentSlot == 'a' ? 'b' : 'a';
    await _writeSlot(targetSlot, next);
    await _writeActiveSlot(targetSlot);
    await _writeSlot(currentSlot, next);
  }

  Map<String, _JournalRecord> _readRecords() {
    final records = <String, _JournalRecord>{};
    final slotA = _decodeRecord(_preferences.getString(_slotAKey));
    final slotB = _decodeRecord(_preferences.getString(_slotBKey));
    if (slotA != null) records['a'] = slotA;
    if (slotB != null) records['b'] = slotB;
    return records;
  }

  _JournalRecord? _decodeRecord(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return _JournalRecord.decode(raw);
    } on FormatException {
      return null;
    }
  }

  bool _hasJournalData() =>
      (_preferences.getString(_slotAKey)?.isNotEmpty ?? false) ||
      (_preferences.getString(_slotBKey)?.isNotEmpty ?? false) ||
      (_preferences.getString(_activeKey)?.isNotEmpty ?? false);

  Future<void> _writeSlot(String slot, _JournalRecord record) async {
    final key = slot == 'a' ? _slotAKey : _slotBKey;
    final persisted = await _preferences.setString(key, record.encode());
    if (!persisted) {
      throw StateError('Nao foi possivel gravar o journal local do treino.');
    }
  }

  Future<void> _writeActiveSlot(String slot) async {
    final persisted = await _preferences.setString(_activeKey, slot);
    if (!persisted) {
      throw StateError('Nao foi possivel confirmar o journal local do treino.');
    }
  }

  Future<void> _preserveUnreadableData({String? legacy}) async {
    final preserved = jsonEncode({
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
      'legacy': legacy ?? _preferences.getString(scopedStorageKey),
      'slotA': _preferences.getString(_slotAKey),
      'slotB': _preferences.getString(_slotBKey),
      'active': _preferences.getString(_activeKey),
    });
    await _preferences.setString(_recoveryKey, preserved);
  }

  static String _normalizeScope(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return anonymousScope;
    return normalized.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }
}

class _JournalRecord {
  const _JournalRecord({required this.revision, required this.snapshot});

  final int revision;
  final WorkoutSliceSnapshot snapshot;

  factory _JournalRecord.fromSnapshot(
    WorkoutSliceSnapshot snapshot, {
    required int revision,
  }) => _JournalRecord(revision: revision, snapshot: snapshot);

  factory _JournalRecord.decode(String raw) {
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (decoded['version'] !=
          SharedPreferencesWorkoutVerticalLocalStore._journalVersion) {
        throw const FormatException('Versao de journal desconhecida.');
      }
      final revision = decoded['revision'];
      final payload = decoded['payload'];
      final checksum = decoded['checksum'];
      if (revision is! int ||
          revision < 1 ||
          payload is! Map ||
          checksum is! String) {
        throw const FormatException('Journal incompleto.');
      }
      final payloadMap = Map<String, dynamic>.from(payload);
      if (_checksum(jsonEncode(payloadMap)) != checksum) {
        throw const FormatException('Checksum do journal invalido.');
      }
      return _JournalRecord(
        revision: revision,
        snapshot: WorkoutSliceSnapshot.fromJson(payloadMap),
      );
    } on TypeError catch (error) {
      throw FormatException('Journal invalido: $error');
    }
  }

  String encode() {
    final payload = snapshot.toJson();
    return jsonEncode({
      'version': SharedPreferencesWorkoutVerticalLocalStore._journalVersion,
      'revision': revision,
      'payload': payload,
      'checksum': _checksum(jsonEncode(payload)),
    });
  }
}

String _checksum(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
