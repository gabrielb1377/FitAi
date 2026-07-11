import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/models/ready_plan_model.dart';
import 'package:fitai/services/ready_plan_mapper.dart';

void main() {
  test('parses the current backend ready plan contract', () {
    final plan = ReadyPlanModel.fromJson({
      'id': 'plan-1',
      'nome': 'ABC Classico',
      'descricao': 'Plano fixo para academia.',
      'capa': '/images/ready-plans/abc-classico.jpg',
      'categoria': 'ABC',
      'nivel': 'Iniciante',
      'objetivo': 'Hipertrofia',
      'divisao': 'ABC',
      'diasPorSemana': 3,
      'tempoEstimado': 55,
      'dias': [
        {
          'id': 'day-1',
          'nome': 'Dia A',
          'titulo': 'Peito + Triceps',
          'diaSemana': 'Segunda',
          'grupoMuscular': 'Peito + Triceps',
          'ordem': 1,
          'exercicios': [
            {
              'id': 'exercise-1',
              'nome': 'Supino reto com barra',
              'series': 3,
              'repeticoes': '10-12',
              'descanso': 75,
              'ordem': 1,
            },
          ],
        },
      ],
    });

    expect(plan.name, 'ABC Classico');
    expect(plan.location, 'Academia');
    expect(plan.tags, contains('ABC'));
    expect(plan.days.single.exercises.single.sets, 3);
    expect(plan.days.single.exercises.single.reps, '10-12');
    expect(plan.days.single.exercises.single.restSeconds, 75);

    final treino = ReadyPlanMapper.toTreino(
      plan,
      workoutId: 'workout-1',
      source: 'ready_plan_offline',
    );
    expect(treino.readyPlanId, 'plan-1');
    expect(treino.planoDias.single.exercicioIds, hasLength(1));
    expect(treino.exercicios.single.repeticoes, '10-12');
    expect(treino.origem, 'ready_plan_offline');
  });
}
