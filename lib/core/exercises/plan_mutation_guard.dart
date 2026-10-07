import 'dart:convert';
import '../../models/treino_model.dart';

/// Atomic precondition and receipt used inside the existing local plan queue.
class PlanMutationGuard {
  const PlanMutationGuard({
    required this.actionId,
    required this.owner,
    required this.before,
    required this.after,
    required this.assertOwner,
  });
  final String actionId, owner;
  final Map<String, dynamic>? before;
  final Map<String, dynamic> after;
  final void Function() assertOwner;

  void validate(TreinoModel? current, TreinoModel next) {
    assertOwner();
    if (encode(current == null ? null : snapshot(current)) != encode(before) ||
        encode(snapshot(next)) != encode(after)) {
      throw StateError('A ficha mudou. Solicite uma nova sugestao ao Coach.');
    }
  }

  static String encode(Object? value) => jsonEncode(_canonical(value));
  static Object? _canonical(Object? value) {
    if (value is List) return value.map(_canonical).toList();
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    return value;
  }

  static Map<String, dynamic> snapshot(TreinoModel plan) {
    final exercises = [...plan.exercicios]
      ..sort((a, b) => a.id.compareTo(b.id));
    final days = [...plan.planoDias]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    return {
      'id': plan.id,
      'nome': plan.nome,
      'objetivo': plan.objetivo,
      'nivel': plan.nivel,
      'divisao': plan.divisao,
      'diasPorSemana': plan.diasPorSemana,
      'tempoEstimado': plan.tempoEstimado,
      'exercicios': exercises
          .map(
            (e) => {
              'id': e.id,
              'series': e.series,
              'repeticoes': e.repeticoes,
              'descansoSegundos': e.descansoSegundos,
              'rir': e.rir,
              'cadencia': e.cadencia,
              'observacoesTreino': e.observacoesTreino,
            },
          )
          .toList(),
      'planoDias': days
          .map(
            (d) => {
              'codigo': d.codigo,
              'nome': d.nome,
              'ordem': d.ordem,
              'exercicioIds': d.exercicioIds,
            },
          )
          .toList(),
    };
  }
}

/// A durable receipt prevents replay after a crash or a lost remote ACK.
class PlanActionAlreadyApplied implements Exception {
  const PlanActionAlreadyApplied(this.plan);
  final TreinoModel plan;
}
