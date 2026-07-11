import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ready_plans_service.dart';

class ReadyPlanFavoritesService extends ChangeNotifier {
  ReadyPlanFavoritesService._({ReadyPlansService? readyPlansService})
    : _readyPlansService = readyPlansService ?? ReadyPlansService();

  @visibleForTesting
  ReadyPlanFavoritesService.forTesting({ReadyPlansService? readyPlansService})
    : _readyPlansService = readyPlansService ?? ReadyPlansService();

  static final ReadyPlanFavoritesService instance =
      ReadyPlanFavoritesService._();

  static const _favoritesKey = 'fitai.ready_plan_favorites.v1';
  static const _pendingKey = 'fitai.ready_plan_favorite_pending.v1';

  final ReadyPlansService _readyPlansService;
  final Set<String> _favoriteIds = <String>{};
  String? _bearerToken;
  bool _loaded = false;
  bool _syncing = false;

  bool get initialized => _loaded;
  bool get syncing => _syncing;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  Future<Set<String>> loadFavoriteIds() async {
    if (_loaded) return favoriteIds;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_favoritesKey) ?? const <String>[];
    _favoriteIds
      ..clear()
      ..addAll(saved.map((id) => id.trim()).where((id) => id.isNotEmpty));
    _loaded = true;
    _debugLog('Favoritos locais carregados: ${_favoriteIds.length}.');
    notifyListeners();
    return favoriteIds;
  }

  bool isFavorite(String id) => _favoriteIds.contains(id.trim());

  Future<bool> toggleFavorite(String id) async {
    await loadFavoriteIds();
    final favorite = !isFavorite(id);
    if (favorite) {
      await addFavorite(id);
    } else {
      await removeFavorite(id);
    }
    return favorite;
  }

  Future<void> addFavorite(String id) async {
    final favoriteId = id.trim();
    if (favoriteId.isEmpty) return;
    await loadFavoriteIds();
    if (_favoriteIds.add(favoriteId)) {
      notifyListeners();
      await _saveFavoriteIds();
      await _queueOperation(favoriteId, true);
    }
  }

  Future<void> removeFavorite(String id) async {
    final favoriteId = id.trim();
    if (favoriteId.isEmpty) return;
    await loadFavoriteIds();
    if (_favoriteIds.remove(favoriteId)) {
      notifyListeners();
      await _saveFavoriteIds();
      await _queueOperation(favoriteId, false);
    }
  }

  void configureBearerToken(String? bearerToken) {
    final nextToken = bearerToken?.trim();
    _bearerToken = nextToken == null || nextToken.isEmpty ? null : nextToken;
    if (_bearerToken != null) {
      unawaited(syncFromBackend());
      unawaited(syncPending());
    }
  }

  Future<void> syncFromBackend() async {
    final token = _bearerToken;
    if (token == null) return;

    try {
      final remoteIds = await _readyPlansService.fetchFavoriteIds(token);
      final countBefore = _favoriteIds.length;
      _favoriteIds.addAll(remoteIds);
      final changed = _favoriteIds.length != countBefore;
      if (changed) {
        await _saveFavoriteIds();
        notifyListeners();
      }
      _debugLog('Favoritos autenticados sincronizados: ${remoteIds.length}.');
    } on ReadyPlansException catch (error) {
      _debugLog('Favoritos remotos pendentes: ${error.message}');
    }
  }

  Future<void> syncPending() async {
    final token = _bearerToken;
    if (token == null || _syncing) return;

    _syncing = true;
    notifyListeners();
    try {
      final pending = await _loadPending();
      final remaining = <Map<String, dynamic>>[];

      for (final operation in pending) {
        final id = operation['id']?.toString().trim() ?? '';
        final favorite = operation['favorite'] == true;
        if (id.isEmpty) continue;

        try {
          if (favorite) {
            await _readyPlansService.addFavorite(id, token);
          } else {
            await _readyPlansService.removeFavorite(id, token);
          }
        } on ReadyPlansException catch (error) {
          remaining.add(operation);
          _debugLog('Favorito pendente para $id: ${error.message}');
        }
      }

      await _savePending(remaining);
      if (remaining.isEmpty) _debugLog('Fila de favoritos sincronizada.');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _queueOperation(String id, bool favorite) async {
    final pending = await _loadPending();
    pending.removeWhere((item) => item['id']?.toString() == id);
    pending.add({
      'id': id,
      'favorite': favorite,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _savePending(pending);
    _debugLog('Operação de favorito pendente: $id=$favorite.');
    unawaited(syncPending());
  }

  Future<void> _saveFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.toList()..sort());
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_pendingKey) ?? const <String>[];
    final pending = <Map<String, dynamic>>[];
    for (final value in raw) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) pending.add(Map<String, dynamic>.from(decoded));
      } catch (_) {
        _debugLog('Operação de favorito inválida ignorada.');
      }
    }
    return pending;
  }

  Future<void> _savePending(List<Map<String, dynamic>> pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pendingKey, pending.map(jsonEncode).toList());
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[ReadyPlanFavorites] $message');
  }
}
