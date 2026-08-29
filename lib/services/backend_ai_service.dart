import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api/api_config.dart';
import '../core/exercises/exercise_catalog_binding.dart';
import '../data/exercicios/exercicios.dart';
import '../features/auth/data/auth_service.dart';
import '../models/exercicio_model.dart';
import '../models/treino_model.dart';

class BackendAIException implements Exception {
  final String message;

  const BackendAIException(this.message);

  @override
  String toString() => 'BackendAIException: $message';
}

class BackendAIService {
  BackendAIService({
    http.Client? client,
    AuthService? authService,
    ExerciseCatalogBinder? catalogBinder,
  }) : _client = client ?? http.Client(),
       _authService = authService ?? AuthService(),
       _catalogBinder = catalogBinder ?? ExerciseCatalogBinder(bancoExercicios);

  final http.Client _client;
  final AuthService _authService;
  final ExerciseCatalogBinder _catalogBinder;

  Future<TreinoModel> generateWorkout({
    required String objetivo,
    required String divisao,
    required String nivel,
    required int diasPorSemana,
    required int tempoPorTreino,
    required int minExerciciosPorDia,
    required String local,
    required List<String> equipamentos,
    required List<String> restricoes,
    required List<String> prioridades,
    String observacoes = '',
  }) async {
    final session = await _authService.restoreSession();
    if (session == null) {
      throw const BackendAIException(
        'Entre na sua conta para usar a geracao de treino por IA.',
      );
    }
    final payload = {
      'objetivo': objetivo,
      'divisao': divisao,
      'nivel': nivel,
      'diasPorSemana': diasPorSemana,
      'tempoPorTreino': tempoPorTreino,
      'minExerciciosPorDia': _safeMinExercises(minExerciciosPorDia),
      'local': local,
      'equipamentos': equipamentos,
      'restricoes': restricoes,
      'prioridades': prioridades,
      'observacoes': observacoes,
    };

    _debugLog(
      'Chamando backend FitIA em ${ApiConfig.endpoint('/ai/generate-workout')}',
    );

    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('/ai/generate-workout'),
            headers: _headers(session.token, _newIdempotencyKey()),
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        throw BackendAIException(
          'Backend retornou status ${response.statusCode}.',
        );
      }

      final decoded = _decodeResponse(response.body);
      final treino = _treinoFromBackendJson(decoded, request: payload);

      _validateTreino(
        treino,
        minExerciciosPorDia: _safeMinExercises(minExerciciosPorDia),
      );
      _debugLog(
        'Treino recebido do backend com ${treino.planoDias.length} dias.',
      );

      return treino;
    } on TimeoutException {
      _debugLog('Timeout ao chamar backend FitIA.');
      throw const BackendAIException('Timeout ao chamar backend.');
    } on BackendAIException {
      rethrow;
    } catch (error) {
      _debugLog('Falha ao chamar backend FitIA: $error');
      throw BackendAIException('Falha ao chamar backend: $error');
    }
  }

  Map<String, String> _headers(String bearerToken, String idempotencyKey) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${bearerToken.trim()}',
      'Idempotency-Key': idempotencyKey,
    };
  }

  String _newIdempotencyKey() =>
      'ai-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw const BackendAIException(
        'Resposta do backend nao e um objeto JSON.',
      );
    } on FormatException {
      throw const BackendAIException(
        'Resposta do backend nao e um JSON valido.',
      );
    }
  }

  TreinoModel _treinoFromBackendJson(
    Map<String, dynamic> json, {
    required Map<String, Object> request,
  }) {
    final dias = _listOfMaps(json['dias']);

    if (dias.isEmpty) {
      throw const BackendAIException('Resposta do backend sem dias.');
    }

    final exercicios = <ExercicioModel>[];
    final planoDias = <TreinoDiaModel>[];

    for (var index = 0; index < dias.length; index++) {
      final dia = dias[index];
      final exerciciosDiaJson = _listOfMaps(dia['exercicios']);

      if (exerciciosDiaJson.isEmpty) {
        throw BackendAIException(
          'Resposta do backend sem exercicios no dia ${index + 1}.',
        );
      }

      final idsDoDia = <String>[];

      for (
        var exerciseIndex = 0;
        exerciseIndex < exerciciosDiaJson.length;
        exerciseIndex += 1
      ) {
        final exercicioJson = exerciciosDiaJson[exerciseIndex];
        final exercicio = _exercicioFromBackendJson(
          exercicioJson,
          fallbackItemId:
              '${_string(json['id'], fallback: 'ai')}_${index}_$exerciseIndex',
        );

        exercicios.add(exercicio);
        idsDoDia.add(exercicio.id);
      }

      planoDias.add(
        TreinoDiaModel(
          codigo: _string(dia['nome'], fallback: 'Dia ${index + 1}'),
          nome: _string(dia['titulo'], fallback: 'Treino'),
          ordem: index + 1,
          exercicioIds: idsDoDia,
        ),
      );
    }

    final treino = TreinoModel(
      id: _string(
        json['id'],
        fallback: 'backend_${DateTime.now().microsecondsSinceEpoch}',
      ),
      nome: _string(json['nome'], fallback: 'Treino IA FitIA'),
      descricao: _string(json['descricao']),
      objetivo: _string(
        json['objetivo'],
        fallback: _string(request['objetivo']),
      ),
      nivel: _string(json['nivel'], fallback: _string(request['nivel'])),
      divisao: _string(request['divisao'], fallback: 'Full Body'),
      tempoEstimado: _int(
        json['tempoEstimado'],
        fallback: _int(request['tempoPorTreino'], fallback: 45),
      ),
      diasPorSemana: dias.length,
      local: _string(request['local']),
      equipamentos: _stringList(request['equipamentos']),
      gruposPrioritarios: _stringList(request['prioridades']),
      lesoesRestricoes: _stringList(request['restricoes']),
      observacoes: _string(request['observacoes']),
      criadoPorIA: true,
      exercicios: exercicios,
      planoDias: planoDias,
      dataCriacao: _string(
        json['dataCriacao'],
        fallback: DateTime.now().toIso8601String(),
      ),
    );

    return treino;
  }

  ExercicioModel _exercicioFromBackendJson(
    Map<String, dynamic> json, {
    required String fallbackItemId,
  }) {
    final descanso = _int(json['descanso'], fallback: 90);
    final series = _int(json['series'], fallback: 3);
    final repeticoes = _string(json['repeticoes'], fallback: '8-12');
    final itemId = _string(json['id'], fallback: fallbackItemId);
    final binding = _catalogBinder.bindAi(
      templateItemId: itemId,
      remoteExerciseId: _string(json['exerciseId']),
      canonicalExerciseId: _string(json['canonicalExerciseId']),
      exerciseName: _string(json['nome'], fallback: 'Exercício'),
    );
    if (!binding.isResolved || binding.entry == null) {
      throw BackendAIException(
        'A resposta da IA contém um exercício sem vínculo canônico seguro: '
        '"${_string(json['nome'], fallback: 'Exercício')}".',
      );
    }

    return binding.entry!.exercise.copyWith(
      id: itemId,
      canonicalExerciseId: binding.canonicalExerciseId,
      canonicalName: binding.canonicalName,
      templateItemId: binding.templateItemId,
      remoteExerciseId: binding.remoteExerciseId,
      series: series,
      repeticoes: repeticoes,
      descansoSegundos: descanso,
      observacoesTreino:
          'Séries: $series | Repetições: $repeticoes | Descanso: ${descanso}s',
    );
  }

  void _validateTreino(TreinoModel treino, {required int minExerciciosPorDia}) {
    if (treino.planoDias.isEmpty) {
      throw const BackendAIException('Treino recebido sem dias.');
    }

    if (treino.exercicios.isEmpty) {
      throw const BackendAIException('Treino recebido sem exercicios.');
    }

    for (final dia in treino.planoDias) {
      if (dia.exercicioIds.isEmpty) {
        throw BackendAIException('Dia ${dia.codigo} sem exercicios.');
      }

      if (dia.exercicioIds.length < minExerciciosPorDia) {
        throw BackendAIException(
          'Dia ${dia.codigo} com menos de $minExerciciosPorDia exercicios.',
        );
      }
    }
  }

  int _safeMinExercises(int value) {
    return const [6, 7, 8, 9, 10].contains(value) ? value : 6;
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[BackendAIService] $message');
    }
  }
}
