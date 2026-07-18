import '../../../models/treino_model.dart';

class PlanDayData {
  const PlanDayData({
    required this.index,
    required this.code,
    required this.title,
    required this.workout,
  });

  final int index;
  final String code;
  final String title;
  final TreinoModel workout;

  String get label => code.trim().isEmpty ? 'Dia ${index + 1}' : code;
}

List<PlanDayData> buildPlanDays(TreinoModel plan) {
  if (plan.planoDias.isNotEmpty) {
    final sorted = [...plan.planoDias]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    return List.generate(sorted.length, (index) {
      final day = sorted[index];
      return PlanDayData(
        index: index,
        code: day.codigo,
        title: day.nome,
        workout: plan.somenteDia(day),
      );
    });
  }

  final categories = plan.exercicios
      .map((exercise) => exercise.categoria.trim())
      .where((category) => category.isNotEmpty)
      .toSet()
      .take(2)
      .toList(growable: false);
  return [
    PlanDayData(
      index: 0,
      code: plan.diaPlano.trim().isEmpty ? 'Dia 1' : plan.diaPlano,
      title: plan.grupoDia.trim().isNotEmpty
          ? plan.grupoDia
          : categories.isEmpty
          ? plan.nome
          : categories.join(' + '),
      workout: plan,
    ),
  ];
}
