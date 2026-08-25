import 'dart:convert';

import 'package:fitai/core/exercises/exercise_identity.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/historico_serie_treino_model.dart';
import 'package:fitai/models/progresso_exercicio_model.dart';
import 'package:fitai/services/exercise_history_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final service = ExerciseHistoryService(
    historyLoader: () async => const PlanWorkoutHistorySnapshot.empty(),
  );

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

  test('prioriza a projecao canonica sobre a estrutura legada', () async {
    SharedPreferences.setMockInitialValues({
      'historicoSeriesTreino': [
        jsonEncode(
          _series(
            id: 'legacy-set',
            sessionId: 'legacy-session',
            setNumber: 1,
            date: DateTime(2026, 7, 9, 10),
          ).toJson(),
        ),
      ],
    });
    final service = ExerciseHistoryService(
      historyLoader: () async => PlanWorkoutHistorySnapshot(
        workouts: [
          WorkoutHistory(
            id: 'canonical-session',
            planId: 'plan-1',
            workoutId: 'workout-1',
            workoutName: 'Peito A',
            startedAt: DateTime(2026, 7, 10, 9),
            finishedAt: DateTime(2026, 7, 10, 10),
            metrics: const WorkoutMetrics.empty(),
            syncStatus: WorkoutSyncStatus.synced,
            exercises: [
              ExerciseHistory(
                exerciseId: 'supino-reto',
                name: 'Supino Reto',
                sets: [
                  CompletedSet(
                    id: 'canonical-set',
                    index: 0,
                    weight: 60,
                    repetitions: 8,
                    completedAt: DateTime(2026, 7, 10, 10),
                    syncStatus: WorkoutSyncStatus.synced,
                  ),
                ],
                volume: 480,
                totalRepetitions: 8,
                completedAt: DateTime(2026, 7, 10, 10),
              ),
            ],
          ),
        ],
        summaries: const [],
        exercisePrs: const [],
        personalRecords: const [],
        timeline: const [],
        calendar: const [],
        streak: const WorkoutStreak(currentDays: 0, longestDays: 0),
      ),
    );

    final history = await service.loadExerciseHistory(_exercise());

    expect(history.executions, hasLength(1));
    expect(history.executions.single.id, 'canonical-session');
    expect(history.executions.single.sets.single.id, 'canonical-set');
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
