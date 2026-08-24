import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/coach_insight_model.dart';
import '../features/auth/data/auth_service.dart';
import 'network_service.dart';

class BackendCoachException implements Exception {
  final String message;

  const BackendCoachException(this.message);

  @override
  String toString() => 'BackendCoachException: $message';
}

class BackendCoachService {
  BackendCoachService({NetworkService? network, AuthService? authService})
    : _network = network ?? NetworkService(),
      _authService = authService ?? AuthService();

  final NetworkService _network;
  final AuthService _authService;

  Future<List<CoachInsightModel>> gerarInsights({
    String tipo = 'geral',
    String? exercicioId,
    int periodoDias = 30,
    bool forceRefresh = false,
  }) async {
    try {
      final session = await _authService.restoreSession();
      if (session == null) {
        throw const BackendCoachException(
          'Entre na sua conta para usar o Coach FitIA online.',
        );
      }
      final payload = {
        'tipo': tipo,
        'exercicioId': exercicioId,
        'periodoDias': periodoDias,
        'forceRefresh': forceRefresh,
      };
      final headers = <String, String>{
        'Authorization': 'Bearer ${session.token}',
        'Idempotency-Key': _newIdempotencyKey(),
      };

      final response = await _network.postJson(
        '/coach/insights',
        payload,
        headers: headers,
      );
      final insights = _parseInsights(response);

      if (insights.isEmpty) {
        throw const BackendCoachException('Resposta sem insights.');
      }

      _debugLog('Insights recebidos do backend: ${insights.length}');
      return insights;
    } on TimeoutException catch (error) {
      _debugLog('Timeout ao chamar Coach backend: $error');
      throw const BackendCoachException('Timeout ao chamar o backend.');
    } on BackendCoachException {
      rethrow;
    } catch (error) {
      _debugLog('Backend indisponivel para Coach: $error');
      throw const BackendCoachException('Falha ao chamar o backend.');
    }
  }

  List<CoachInsightModel> _parseInsights(Map<String, dynamic> json) {
    final geradoEm = json['geradoEm']?.toString();
    final rawInsights = json['insights'];

    if (rawInsights is! List) {
      throw const BackendCoachException('Resposta sem lista de insights.');
    }

    return rawInsights
        .whereType<Map>()
        .map(
          (item) => CoachInsightModel.fromJson(
            Map<String, dynamic>.from(item),
            geradoEmFallback: geradoEm,
          ),
        )
        .where((insight) {
          return insight.titulo.trim().isNotEmpty &&
              insight.descricao.trim().isNotEmpty;
        })
        .take(8)
        .toList();
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[BackendCoachService] $message');
    }
  }

  String _newIdempotencyKey() =>
      'coach-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
}
