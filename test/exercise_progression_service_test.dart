import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai/models/exercicio_model.dart';
import 'package:fitai/models/exercise_history_model.dart';
import 'package:fitai/models/exercise_progression_model.dart';
import 'package:fitai/models/historico_serie_treino_model.dart';
import 'package:fitai/services/exercise_progression_service.dart';

void main() {
  const service = ExerciseProgressionService();
  final exercise = ExercicioModel(
    id: 'supino_reto',
    nome: 'Supino reto',
    categoria: 'Peito',
    descricao: '',
    comoExecutar: '',
    cuidados: '',
    musculos: const ['Peito'],
    equipamentos: const ['barra'],
    locais: const ['academia'],
    dificuldade: 'intermediario',
    objetivo: 'hipertrofia',
    imagem: '',
    video: '',
    tags: const [],
    caloriasHora: 0,
  );

  ExerciseExecution session(int reps, {double weight = 80, int day = 1}) {
    final date = DateTime(2026, 7, day);
    final sets = List.generate(
      3,
      (index) => HistoricoSerieTreinoModel(
        id: '$day-$index',
        treinoId: 'treino',
        sessaoTreinoId: 'sessao_$day',
        nomeTreino: 'Treino',
        exercicioId: exercise.id,
        exerciseKey: 'id:${exercise.id}',
        nomeExercicio: exercise.nome,
        serieNumero: index + 1,
        peso: weight,
        repeticoes: reps,
        dataHora: date,
      ),
    );
    return ExerciseExecution(
      id: 'sessao_$day',
      exerciseId: exercise.id,
      exerciseKey: 'id:${exercise.id}',
      exerciseName: exercise.nome,
      workoutId: 'treino',
      workoutName: 'Treino',
      date: date,
      sets: sets,
    );
  }

  const config = ExerciseProgressionConfig(
    sets: 3,
    repRange: '6-12',
    restSeconds: 90,
    goal: 'hipertrofia',
    level: 'intermediario',
  );

  test('aumenta somente a carga no topo da faixa em duas sessoes', () {
    final result = service.calculate(
      exercise: exercise,
      config: config,
      executions: [session(12, day: 2), session(12)],
    );

    expect(result.action, ExerciseProgressionAction.increaseWeight);
    expect(result.suggestedWeight, greaterThan(80));
    expect(result.suggestedSets, 3);
  });

  test('aumenta repeticoes para desempenho consistente na faixa', () {
    final result = service.calculate(
      exercise: exercise,
      config: config,
      executions: [session(10)],
    );

    expect(result.action, ExerciseProgressionAction.increaseReps);
    expect(result.suggestedWeight, 80);
  });

  test('reduz carga depois de duas sessoes abaixo da faixa', () {
    final result = service.calculate(
      exercise: exercise,
      config: config,
      executions: [session(4, day: 2), session(4)],
    );

    expect(result.action, ExerciseProgressionAction.reduceWeight);
    expect(result.suggestedWeight, lessThan(80));
    expect(result.suggestedRestSeconds, greaterThanOrEqualTo(60));
  });

  test('faz deload apos tres sessoes abaixo da faixa', () {
    final result = service.calculate(
      exercise: exercise,
      config: config,
      executions: [session(4, day: 3), session(4, day: 2), session(4)],
    );

    expect(result.action, ExerciseProgressionAction.deload);
    expect(result.suggestedSets, 2);
  });

  test('nao cria recomendacao acionavel sem historico', () {
    final result = service.calculate(
      exercise: exercise,
      config: config,
      executions: const [],
    );

    expect(result.action, ExerciseProgressionAction.insufficientData);
    expect(result.isActionable, isFalse);
  });

  test('salva aceite para a proxima ocorrencia sem alterar o plano', () async {
    SharedPreferences.setMockInitialValues({});
    final suggestion = service.calculate(
      exercise: exercise,
      config: config,
      executions: [session(10)],
    );

    await service.accept(suggestion);
    final restored = await service.loadAccepted(exercise);

    expect(restored?.exerciseKey, suggestion.exerciseKey);
    expect(restored?.suggestedWeight, suggestion.suggestedWeight);

    await service.accept(suggestion, forNextOccurrence: false);
    expect(await service.loadAccepted(exercise), isNull);
  });

  test('le codigos de acao do contrato do backend', () {
    final model = ExerciseProgressionModel.fromJson({
      'exerciseId': exercise.id,
      'exerciseKey': 'id:${exercise.id}',
      'exerciseName': exercise.nome,
      'action': 'increase_weight',
    });

    expect(model.action, ExerciseProgressionAction.increaseWeight);
    expect(model.toJson()['action'], 'increase_weight');
  });
}
