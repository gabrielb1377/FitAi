import '../models/fitai_memory_model.dart';
import '../models/ready_plan_model.dart';

class ReadyPlanRecommendation {
  final int score;
  final List<String> reasons;

  const ReadyPlanRecommendation({required this.score, required this.reasons});
}

class ReadyPlanRecommendationReasonService {
  const ReadyPlanRecommendationReasonService();

  ReadyPlanRecommendation evaluate(
    ReadyPlanModel plan,
    FitAIMemoryModel memory,
  ) {
    var score = 0;
    final reasons = <String>[];
    final planText = _normalize(
      [plan.goal, plan.category, plan.split, ...plan.tags].join(' '),
    );

    if (_matches(planText, memory.objetivo)) {
      score += 4;
      reasons.add(
        'Combina com seu objetivo de ${memory.objetivo.toLowerCase()}.',
      );
    }
    if (_matches(_normalize(plan.level), memory.nivelExperiencia)) {
      score += 3;
      reasons.add(
        'Compatível com seu nível ${memory.nivelExperiencia.toLowerCase()}.',
      );
    }
    if (memory.diasDisponiveis.isNotEmpty &&
        plan.daysPerWeek == memory.diasDisponiveis.length) {
      score += 3;
      reasons.add('Ideal para ${plan.daysPerWeek} dias por semana.');
    }
    if (_matches(_normalize(plan.location), memory.localTreino)) {
      score += 2;
      reasons.add('Compatível com seu local de treino.');
    }
    if (plan.allEquipment.isNotEmpty &&
        memory.equipamentos.isNotEmpty &&
        plan.allEquipment.any(
          (item) => memory.equipamentos.any(
            (saved) => _matches(_normalize(item), saved),
          ),
        )) {
      score += 1;
      reasons.add('Usa equipamentos disponíveis no seu treino.');
    }

    if (reasons.isEmpty) {
      reasons.add(
        plan.featured
            ? 'Plano em destaque na biblioteca.'
            : 'Boa opção para começar.',
      );
    }

    return ReadyPlanRecommendation(
      score: score,
      reasons: reasons.take(4).toList(),
    );
  }

  static bool _matches(String source, String value) {
    final target = _normalize(value);
    return target.isNotEmpty && source.contains(target);
  }

  static String _normalize(String value) {
    const source = 'áàãâäéèêëíìîïóòõôöúùûüç';
    const target = 'aaaaaeeeeiiiiooooouuuuc';
    var result = value.toLowerCase().trim();
    for (var index = 0; index < source.length; index += 1) {
      result = result.replaceAll(source[index], target[index]);
    }
    return result;
  }
}
