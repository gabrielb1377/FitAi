import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api/api_config.dart';
import '../models/ready_plan_model.dart';

class ReadyPlansException implements Exception {
  final String message;

  const ReadyPlansException(this.message);

  @override
  String toString() => 'ReadyPlansException: $message';
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
        throw const ReadyPlansException(
          'Não foi possível carregar os planos agora.',
        );
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
      );
    }
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
