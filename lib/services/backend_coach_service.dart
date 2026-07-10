import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/coach_insight_model.dart';
import 'metas_service.dart';
import 'network_service.dart';
import 'storage_service.dart';

class BackendCoachException implements Exception {
  final String message;

  const BackendCoachException(this.message);

  @override
  String toString() => 'BackendCoachException: $message';
}

class BackendCoachService {
  BackendCoachService({NetworkService? network})
    : _network = network ?? NetworkService();

  final NetworkService _network;

  Future<List<CoachInsightModel>> gerarInsights({
    String tipo = 'geral',
    String? exercicioId,
    int periodoDias = 30,
    bool forceRefresh = false,
    String? bearerToken,
  }) async {
    try {
      final payload = {
        'tipo': tipo,
        'exercicioId': exercicioId,
        'periodoDias': periodoDias,
        'forceRefresh': forceRefresh,
        'contextoLocal': await _montarContextoLocal(),
      };
      final headers = <String, String>{};

      if (bearerToken != null && bearerToken.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${bearerToken.trim()}';
      }

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

  Future<Map<String, dynamic>> _montarContextoLocal() async {
    final perfil = await StorageService.carregarPerfilUsuario();
    final treinos = await StorageService.carregarTreinos();
    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final recordes = await StorageService.carregarRecordes();
    final metas = await const MetasService().carregarMetas();
    final corridas = await StorageService.carregarCorridas();

    return {
      'perfil': perfil,
      'planos': treinos.map((treino) => treino.toJson()).toList(),
      'historicoTreinos': historicoTreinos
          .map((treino) => treino.toJson())
          .toList(),
      'historicoExercicios': historicoSeries
          .map((serie) => serie.toJson())
          .toList(),
      'recordes': recordes.map((recorde) => recorde.toJson()).toList(),
      'metas': metas.metas.map((meta) => meta.toJson()).toList(),
      'corridas': corridas.map((corrida) => corrida.toJson()).toList(),
    };
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
}
