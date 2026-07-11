import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_config.dart';
import '../models/ready_plan_model.dart';

class ReadyPlansException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkUnavailable;

  const ReadyPlansException(
    this.message, {
    this.statusCode,
    this.isNetworkUnavailable = false,
  });

  @override
  String toString() => 'ReadyPlansException: $message';
}

class ReadyPlanCopyResult {
  final String message;
  final String workoutId;

  const ReadyPlanCopyResult({required this.message, required this.workoutId});
}

enum ReadyPlansSource { backend, cache }

class ReadyPlansListResult {
  final List<ReadyPlanModel> plans;
  final ReadyPlansSource source;
  final DateTime? updatedAt;

  const ReadyPlansListResult({
    required this.plans,
    required this.source,
    this.updatedAt,
  });

  bool get isFromCache => source == ReadyPlansSource.cache;
}

class ReadyPlansService {
  ReadyPlansService({http.Client? client}) : _client = client ?? http.Client();

  static const _cacheVersion = 1;
  static const _plansCacheKey = 'fitai.ready_plans.cache.v1';
  static const _plansCacheUpdatedAtKey =
      'fitai.ready_plans.cache.updated_at.v1';
  static const _detailCachePrefix = 'fitai.ready_plan.detail.v1.';

  final http.Client _client;

  Future<ReadyPlansListResult> listPlans() async {
    try {
      final json = await _getObject('/ready-plans');
      final plans = _decodePlans(json['plans']);

      if (plans.isEmpty) {
        throw const ReadyPlansException('Biblioteca vazia.');
      }

      await savePlansCache(plans);
      _debugLog(
        'Backend success: biblioteca recebida com ${plans.length} plano(s).',
      );
      return ReadyPlansListResult(
        plans: plans,
        source: ReadyPlansSource.backend,
        updatedAt: DateTime.now(),
      );
    } catch (error) {
      _debugLog('Backend offline ou resposta invalida: $error');
      final cachedPlans = await loadPlansCache();

      if (cachedPlans != null) {
        final updatedAt = await _loadPlansCacheUpdatedAt();
        _debugLog('Cache loaded: ${cachedPlans.length} plano(s).');
        return ReadyPlansListResult(
          plans: cachedPlans,
          source: ReadyPlansSource.cache,
          updatedAt: updatedAt,
        );
      }

      if (error is ReadyPlansException) rethrow;
      throw const ReadyPlansException(
        'Não foi possível carregar os planos agora.',
      );
    }
  }

  Future<ReadyPlanModel> getPlanDetails(String id) async {
    if (id.trim().isEmpty) {
      throw const ReadyPlansException('Plano inválido.');
    }

    try {
      final json = await _getObject('/ready-plans/${Uri.encodeComponent(id)}');
      final planJson = _map(json['plan']);

      if (planJson == null) {
        throw const ReadyPlansException('Detalhes do plano indisponíveis.');
      }

      final plan = ReadyPlanModel.fromJson(planJson);
      if (!_hasCompleteDetails(plan)) {
        throw const ReadyPlansException('Detalhes incompletos da biblioteca.');
      }

      await savePlanDetailCache(plan);
      _debugLog('Backend success: detalhe salvo para $id.');
      return plan;
    } catch (error) {
      _debugLog('Detalhe indisponivel no backend: $error');
      final cachedPlan = await loadPlanDetailCache(id);

      if (cachedPlan != null) {
        _debugLog('Cache loaded: detalhe salvo para $id.');
        return cachedPlan;
      }

      if (error is ReadyPlansException) rethrow;
      throw const ReadyPlansException('Detalhes do plano indisponíveis.');
    }
  }

  Future<void> savePlansCache(List<ReadyPlanModel> plans) async {
    if (!_isValidPlans(plans)) {
      _debugLog('Cache invalid: lista vazia ou incompleta nao foi salva.');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      await prefs.setString(
        _plansCacheKey,
        jsonEncode({
          'version': _cacheVersion,
          'updatedAt': now,
          'plans': plans.map((plan) => plan.toJson()).toList(),
        }),
      );
      await prefs.setString(_plansCacheUpdatedAtKey, now);
      _debugLog('Cache updated: lista de planos salva.');
    } catch (error) {
      _debugLog('Falha ao atualizar cache de planos: $error');
    }
  }

  Future<List<ReadyPlanModel>?> loadPlansCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansCacheKey);

    if (raw == null || raw.trim().isEmpty) {
      _debugLog('Cache missing: lista de planos.');
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      final wrapper = _map(decoded);
      if (wrapper?['version'] != _cacheVersion) {
        throw const FormatException('schema antigo');
      }

      final plans = _decodePlans(wrapper?['plans']);
      if (!_isValidPlans(plans)) {
        throw const FormatException('lista vazia');
      }

      return plans;
    } catch (error) {
      _debugLog('Cache invalid: lista de planos ($error).');
      await clearInvalidReadyPlansCache();
      return null;
    }
  }

  Future<void> savePlanDetailCache(ReadyPlanModel plan) async {
    if (!_hasCompleteDetails(plan)) {
      _debugLog('Cache invalid: detalhe incompleto nao foi salvo.');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _detailCacheKey(plan.id),
        jsonEncode({
          'version': _cacheVersion,
          'updatedAt': DateTime.now().toIso8601String(),
          'plan': plan.toJson(),
        }),
      );
      _debugLog('Cache updated: detalhe salvo para ${plan.id}.');
    } catch (error) {
      _debugLog('Falha ao atualizar detalhe em cache: $error');
    }
  }

  Future<ReadyPlanModel?> loadPlanDetailCache(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _detailCacheKey(id);
    final raw = prefs.getString(key);

    if (raw == null || raw.trim().isEmpty) {
      _debugLog('Cache missing: detalhe de $id.');
      return null;
    }

    try {
      final wrapper = _map(jsonDecode(raw));
      if (wrapper?['version'] != _cacheVersion) {
        throw const FormatException('schema antigo');
      }
      final planJson = _map(wrapper?['plan']);
      final plan = planJson == null ? null : ReadyPlanModel.fromJson(planJson);
      if (plan == null || !_hasCompleteDetails(plan) || plan.id != id) {
        throw const FormatException('detalhe incompleto');
      }
      return plan;
    } catch (error) {
      _debugLog('Cache invalid: detalhe de $id ($error).');
      await prefs.remove(key);
      return null;
    }
  }

  Future<List<ReadyPlanModel>> mergeCachedDetails(
    List<ReadyPlanModel> plans,
  ) async {
    final enriched = await Future.wait(
      plans.map((plan) async {
        final detail = await loadPlanDetailCache(plan.id);
        return detail ?? plan;
      }),
    );
    return enriched;
  }

  Future<void> clearInvalidReadyPlansCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where(
          (key) =>
              key == _plansCacheKey ||
              key == _plansCacheUpdatedAtKey ||
              key.startsWith(_detailCachePrefix),
        )
        .toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
    _debugLog('Cache cleared: somente dados de ready plans.');
  }

  Future<ReadyPlanCopyResult> copyReadyPlan(
    String id, {
    String? bearerToken,
    String? clientId,
    String? idempotencyKey,
  }) async {
    if (id.trim().isEmpty) {
      throw const ReadyPlansException('Plano inválido.', statusCode: 400);
    }

    final key = idempotencyKey?.trim().isNotEmpty == true
        ? idempotencyKey!.trim()
        : _newIdempotencyKey();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Idempotency-Key': key,
      if (clientId != null && clientId.trim().isNotEmpty)
        'X-FitIA-Client-Id': clientId.trim(),
      if (bearerToken != null && bearerToken.trim().isNotEmpty)
        'Authorization': 'Bearer ${bearerToken.trim()}',
    };

    final json = await _postObject(
      '/ready-plans/${Uri.encodeComponent(id)}/copy',
      headers,
    );
    final plan = _map(json['plan']);
    final workoutId = plan?['id']?.toString().trim() ?? '';

    if (workoutId.isEmpty) {
      throw const ReadyPlansException(
        'Resposta inválida ao adicionar o plano.',
      );
    }

    return ReadyPlanCopyResult(
      message: json['message']?.toString().trim().isNotEmpty == true
          ? json['message'].toString()
          : 'Plano adicionado com sucesso.',
      workoutId: workoutId,
    );
  }

  Future<Set<String>> fetchFavoriteIds(String bearerToken) async {
    final json = await _getObject(
      '/ready-plans/favorites',
      headers: _authorizationHeaders(bearerToken),
    );
    final ids = json['favoriteIds'];
    if (ids is! List) return <String>{};
    return ids
        .map((item) => item.toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> addFavorite(String id, String bearerToken) async {
    await _postObject(
      '/ready-plans/${Uri.encodeComponent(id)}/favorite',
      _authorizationHeaders(bearerToken),
    );
  }

  Future<void> removeFavorite(String id, String bearerToken) async {
    await _deleteObject(
      '/ready-plans/${Uri.encodeComponent(id)}/favorite',
      _authorizationHeaders(bearerToken),
    );
  }

  Future<Map<String, dynamic>> _getObject(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await _client
          .get(
            ApiConfig.endpoint(path),
            headers: {'Accept': 'application/json', ...headers},
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _debugLog('Backend respondeu ${response.statusCode} em $path.');
        throw _exceptionForStatus(response.statusCode, loading: true);
      }

      final decoded = jsonDecode(response.body);
      final object = _map(decoded);
      if (object == null) {
        throw const ReadyPlansException('Resposta inválida da biblioteca.');
      }

      return object;
    } on TimeoutException {
      _debugLog('Timeout ao consultar $path.');
      throw const ReadyPlansException(
        'Não foi possível carregar os planos agora.',
        isNetworkUnavailable: true,
      );
    } on FormatException {
      _debugLog('JSON inválido em $path.');
      throw const ReadyPlansException('Resposta inválida da biblioteca.');
    } on ReadyPlansException {
      rethrow;
    } catch (error) {
      _debugLog('Falha ao consultar $path: $error');
      throw const ReadyPlansException(
        'Não foi possível carregar os planos agora.',
        isNetworkUnavailable: true,
      );
    }
  }

  Future<DateTime?> _loadPlansCacheUpdatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_plansCacheUpdatedAtKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  List<ReadyPlanModel> _decodePlans(dynamic value) {
    return _maps(value)
        .map(ReadyPlanModel.fromJson)
        .where((plan) => plan.id.isNotEmpty && plan.name.isNotEmpty)
        .toList();
  }

  bool _isValidPlans(List<ReadyPlanModel> plans) =>
      plans.isNotEmpty &&
      plans.every(
        (plan) => plan.id.trim().isNotEmpty && plan.name.trim().isNotEmpty,
      );

  bool _hasCompleteDetails(ReadyPlanModel plan) {
    return plan.id.trim().isNotEmpty &&
        plan.name.trim().isNotEmpty &&
        plan.days.isNotEmpty &&
        plan.days.every((day) => day.exercises.isNotEmpty);
  }

  String _detailCacheKey(String id) =>
      '$_detailCachePrefix${Uri.encodeComponent(id)}';

  Future<Map<String, dynamic>> _postObject(
    String path,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _client
          .post(ApiConfig.endpoint(path), headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _debugLog('Backend respondeu ${response.statusCode} em $path.');
        throw _exceptionForStatus(response.statusCode, loading: false);
      }

      final decoded = jsonDecode(response.body);
      final object = _map(decoded);
      if (object == null) {
        throw const ReadyPlansException(
          'Resposta inválida ao adicionar o plano.',
        );
      }
      return object;
    } on TimeoutException {
      _debugLog('Timeout ao copiar plano.');
      throw const ReadyPlansException(
        'Backend indisponível. O plano será salvo localmente.',
        isNetworkUnavailable: true,
      );
    } on FormatException {
      _debugLog('JSON inválido ao copiar plano.');
      throw const ReadyPlansException(
        'Resposta inválida ao adicionar o plano.',
      );
    } on ReadyPlansException {
      rethrow;
    } catch (error) {
      _debugLog('Falha ao copiar plano: $error');
      throw const ReadyPlansException(
        'Backend indisponível. O plano será salvo localmente.',
        isNetworkUnavailable: true,
      );
    }
  }

  Future<Map<String, dynamic>> _deleteObject(
    String path,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _client
          .delete(ApiConfig.endpoint(path), headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _favoriteException(response.statusCode);
      }

      if (response.body.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      final object = _map(decoded);
      if (object == null) {
        throw const ReadyPlansException(
          'Resposta inválida ao sincronizar favoritos.',
        );
      }
      return object;
    } on TimeoutException {
      throw const ReadyPlansException(
        'Backend indisponível para sincronizar favoritos.',
        isNetworkUnavailable: true,
      );
    } on ReadyPlansException {
      rethrow;
    } catch (error) {
      _debugLog('Falha ao remover favorito: $error');
      throw const ReadyPlansException(
        'Backend indisponível para sincronizar favoritos.',
        isNetworkUnavailable: true,
      );
    }
  }

  ReadyPlansException _exceptionForStatus(
    int statusCode, {
    required bool loading,
  }) {
    if (loading) {
      return ReadyPlansException(
        'Não foi possível carregar os planos agora.',
        statusCode: statusCode,
      );
    }

    switch (statusCode) {
      case 400:
        return const ReadyPlansException('Plano inválido.', statusCode: 400);
      case 401:
        return const ReadyPlansException(
          'Sua sessão não permite adicionar este plano.',
          statusCode: 401,
        );
      case 404:
        return const ReadyPlansException(
          'Plano pronto não encontrado.',
          statusCode: 404,
        );
      case 409:
        return const ReadyPlansException(
          'Este plano já foi adicionado.',
          statusCode: 409,
        );
      default:
        return ReadyPlansException(
          'Não foi possível adicionar o plano agora.',
          statusCode: statusCode,
        );
    }
  }

  ReadyPlansException _favoriteException(int statusCode) {
    if (statusCode == 401) {
      return const ReadyPlansException(
        'Autenticação necessária para sincronizar favoritos.',
        statusCode: 401,
      );
    }
    if (statusCode == 404) {
      return const ReadyPlansException(
        'Plano pronto não encontrado.',
        statusCode: 404,
      );
    }
    return ReadyPlansException(
      'Não foi possível sincronizar favoritos.',
      statusCode: statusCode,
    );
  }

  Map<String, String> _authorizationHeaders(String bearerToken) {
    final token = bearerToken.trim();
    if (token.isEmpty) {
      throw const ReadyPlansException(
        'Autenticação necessária para sincronizar favoritos.',
        statusCode: 401,
      );
    }
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  String _newIdempotencyKey() {
    return 'ready_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 31)}';
  }

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[ReadyPlansService] $message');
  }
}
