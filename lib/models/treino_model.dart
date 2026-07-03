import 'exercicio_model.dart';

class TreinoModel {
  final String id;

  final String nome;

  final String descricao;

  final String objetivo;

  final String nivel;

  final String divisao;

  final int tempoEstimado;

  final bool criadoPorIA;

  final List<ExercicioModel> exercicios;

  final String dataCriacao;

  TreinoModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.objetivo,
    required this.nivel,
    this.divisao = "Full Body",
    required this.tempoEstimado,
    required this.criadoPorIA,
    required this.exercicios,
    required this.dataCriacao,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nome": nome,
      "descricao": descricao,
      "objetivo": objetivo,
      "nivel": nivel,
      "divisao": divisao,
      "tempoEstimado": tempoEstimado,
      "criadoPorIA": criadoPorIA,
      "dataCriacao": dataCriacao,
      "exercicios": exercicios.map((e) => e.toJson()).toList(),
    };
  }

  factory TreinoModel.fromJson(Map<String, dynamic> json) {
    return TreinoModel(
      id: json["id"],
      nome: json["nome"],
      descricao: json["descricao"],
      objetivo: json["objetivo"],
      nivel: json["nivel"],
      divisao: json["divisao"] ?? "Full Body",
      tempoEstimado: json["tempoEstimado"],
      criadoPorIA: json["criadoPorIA"],
      dataCriacao: json["dataCriacao"],
      exercicios: (json["exercicios"] as List)
          .map((e) => ExercicioModel.fromJson(e))
          .toList(),
    );
  }
}
