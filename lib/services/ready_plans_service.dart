import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

class ReadyPlansService {
  ReadyPlansService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ReadyPlanModel>> listPlans() async {
    final json = await _getObject('/ready-plans');
    final plans = _maps(
      json['plans'],
    ).map(ReadyPlanModel.fromJson).where((plan) => plan.id.isNotEmpty).toList();
    _debugLog('Biblioteca recebida com ${plans.length} plano(s).');
    return plans;
  }

  Future<ReadyPlanModel> getPlanDetails(String id) async {
    if (id.trim().isEmpty) {
      throw const ReadyPlansException('Plano inválido.');
    }

    final json = await _getObject('/ready-plans/${Uri.encodeComponent(id)}');
    final planJson = _map(json['plan']);

    if (planJson == null) {
      throw const ReadyPlansException('Detalhes do plano indisponíveis.');
    }

    return ReadyPlanModel.fromJson(planJson);
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

  Future<Map<String, dynamic>> _getObject(String path) async {
    try {
      final response = await _client
          .get(
            ApiConfig.endpoint(path),
            headers: const {'Accept': 'application/json'},
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
