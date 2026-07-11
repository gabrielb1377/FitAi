import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/models/fitai_memory_model.dart';
import 'package:fitai/models/ready_plan_model.dart';
import 'package:fitai/services/ready_plan_recommendation_reason_service.dart';

void main() {
  test('gera motivos locais sem inventar preferências', () {
    const plan = ReadyPlanModel(
      id: 'plan-1',
      name: 'Upper Lower',
      goal: 'Hipertrofia',
      level: 'Intermediário',
      daysPerWeek: 4,
      location: 'Academia',
      equipment: ['halteres'],
    );
    const memory = FitAIMemoryModel(
      objetivo: 'Hipertrofia',
      nivelExperiencia: 'Intermediário',
      diasDisponiveis: ['Segunda', 'Terça', 'Quinta', 'Sexta'],
      localTreino: 'Academia',
      equipamentos: ['halteres'],
    );

    final result = const ReadyPlanRecommendationReasonService().evaluate(
      plan,
      memory,
    );

    expect(result.score, 13);
    expect(result.reasons, hasLength(4));
    expect(result.reasons.first, contains('objetivo'));
  });
}
