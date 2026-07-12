import 'dart:convert';

import 'package:fitai/core/exercises/exercise_identity.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/historico_serie_treino_model.dart';
import 'package:fitai/models/progresso_exercicio_model.dart';
import 'package:fitai/services/exercise_history_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = ExerciseHistoryService();

  test('normaliza acentos, hifens, underscores e espacos', () {
    expect(
      ExerciseIdentity.normalizeName('  Supino-Reto__Com  Halteres '),
      'supino reto com halteres',
    );
  });

  test('carrega por id e preserva sessoes diferentes', () async {
    final first = _series(
      id: 'set-1',
      sessionId: 'session-1',
      setNumber: 1,
      date: DateTime(2026, 7, 10, 10),
    );
    final second = _series(
      id: 'set-2',
      sessionId: 'session-1',
      setNumber: 2,
      date: DateTime(2026, 7, 10, 10, 2),
    );
    final latest = _series(
      id: 'set-3',
      sessionId: 'session-2',
      setNumber: 1,
      date: DateTime(2026, 7, 11, 10),
      weight: 30,
    );
    final duplicate = _series(
      id: 'set-duplicate',
      sessionId: 'session-1',
      setNumber: 1,
      date: DateTime(2026, 7, 10, 10),
    );
    SharedPreferences.setMockInitialValues({
      'historicoSeriesTreino': [
        jsonEncode(first.toJson()),
        jsonEncode(second.toJson()),
        jsonEncode(latest.toJson()),
        jsonEncode(duplicate.toJson()),
      ],
    });

    final history = await service.loadExerciseHistory(_exercise());

    expect(history.executions, hasLength(2));
    expect(history.executions.first.id, 'session-2');
    expect(history.executions.last.sets, hasLength(2));
    expect(history.stats.totalSessions, 2);
    expect(history.stats.bestLoadSet?.peso, 30);
  });

  test(
    'usa progresso antigo por nome normalizado quando nao ha series',
    () async {
      final legacy = ProgressoExercicioModel(
        id: 'legacy-1',
        nomeExercicio: 'Supino-Reto',
        peso: 24,
        series: 1,
        repeticoes: 10,
        observacao: 'Treino antigo',
        data: DateTime(2026, 6, 1, 9),
      );
      SharedPreferences.setMockInitialValues({
        'progressosExercicios': [jsonEncode(legacy.toJson())],
      });

      final history = await service.loadExerciseHistory(
        _exercise(id: 'novo-id', name: 'Supino Reto'),
      );

      expect(history.executions, hasLength(1));
      expect(history.executions.single.bestSet?.peso, 24);
      expect(history.executions.single.workoutName, 'Treino antigo');
    },
  );

  test('nao duplica a mesma serie ao salvar novamente', () async {
    SharedPreferences.setMockInitialValues({});
    final entry = _series(
      id: 'set-idempotent',
      sessionId: 'session-idempotent',
      setNumber: 1,
      date: DateTime(2026, 7, 12, 8),
    );

    await StorageService.salvarHistoricoSerieTreino(entry);
    await StorageService.salvarHistoricoSerieTreino(entry);

    final saved = await StorageService.carregarHistoricoSeriesTreino();
    expect(saved, hasLength(1));
  });

  test('retorna vazio somente sem execucoes locais ou legadas', () async {
    SharedPreferences.setMockInitialValues({});

    final history = await service.loadExerciseHistory(_exercise());

    expect(history.executions, isEmpty);
    expect(history.stats.totalSessions, 0);
  });
}

ExercicioModel _exercise({
  String id = 'supino-reto',
  String name = 'Supino Reto',
}) {
  return ExercicioModel.fromJson({'id': id, 'nome': name});
}

HistoricoSerieTreinoModel _series({
  required String id,
  required String sessionId,
  required int setNumber,
  required DateTime date,
  double weight = 20,
}) {
  return HistoricoSerieTreinoModel(
    id: id,
    treinoId: 'workout-1',
    sessaoTreinoId: sessionId,
    nomeTreino: 'Peito A',
    exercicioId: 'supino-reto',
    nomeExercicio: 'Supino Reto',
    serieNumero: setNumber,
    peso: weight,
    repeticoes: 10,
    dataHora: date,
  );
}
