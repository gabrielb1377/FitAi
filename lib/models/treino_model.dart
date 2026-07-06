import 'exercicio_model.dart';

class TreinoModel {
  final String id;

  final String nome;

  final String descricao;

  final String objetivo;

  final String nivel;

  final String divisao;

  final int tempoEstimado;

  final int diasPorSemana;

  final String local;

  final List<String> equipamentos;

  final List<String> gruposPrioritarios;

  final List<String> lesoesRestricoes;

  final List<String> exerciciosFavoritos;

  final List<String> exerciciosEvitados;

  final String observacoes;

  final String diaPlano;

  final String grupoDia;

  final int ordemDia;

  final List<TreinoDiaModel> planoDias;

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
    this.diasPorSemana = 1,
    this.local = "",
    this.equipamentos = const [],
    this.gruposPrioritarios = const [],
    this.lesoesRestricoes = const [],
    this.exerciciosFavoritos = const [],
    this.exerciciosEvitados = const [],
    this.observacoes = "",
    this.diaPlano = "",
    this.grupoDia = "",
    this.ordemDia = 0,
    this.planoDias = const [],
    required this.criadoPorIA,
    required this.exercicios,
    required this.dataCriacao,
  });

  bool get isPlanoPrincipal => diaPlano.trim().isEmpty || planoDias.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nome": nome,
      "descricao": descricao,
      "objetivo": objetivo,
      "nivel": nivel,
      "divisao": divisao,
      "tempoEstimado": tempoEstimado,
      "diasPorSemana": diasPorSemana,
      "local": local,
      "equipamentos": equipamentos,
      "gruposPrioritarios": gruposPrioritarios,
      "lesoesRestricoes": lesoesRestricoes,
      "exerciciosFavoritos": exerciciosFavoritos,
      "exerciciosEvitados": exerciciosEvitados,
      "observacoes": observacoes,
      "diaPlano": diaPlano,
      "grupoDia": grupoDia,
      "ordemDia": ordemDia,
      "planoDias": planoDias.map((dia) => dia.toJson()).toList(),
      "criadoPorIA": criadoPorIA,
      "dataCriacao": dataCriacao,
      "exercicios": exercicios.map((e) => e.toJson()).toList(),
    };
  }

  factory TreinoModel.fromJson(Map<String, dynamic> json) {
    return TreinoModel(
      id: json["id"]?.toString() ?? "",
      nome: json["nome"]?.toString() ?? "Treino",
      descricao: json["descricao"]?.toString() ?? "",
      objetivo: json["objetivo"]?.toString() ?? "Hipertrofia",
      nivel: json["nivel"]?.toString() ?? "Iniciante",
      divisao: json["divisao"] ?? "Full Body",
      tempoEstimado: _intFromJson(json["tempoEstimado"], fallback: 45),
      diasPorSemana: _intFromJson(json["diasPorSemana"], fallback: 1),
      local: json["local"]?.toString() ?? "",
      equipamentos: _listFromJson(json["equipamentos"]),
      gruposPrioritarios: _listFromJson(json["gruposPrioritarios"]),
      lesoesRestricoes: _listFromJson(json["lesoesRestricoes"]),
      exerciciosFavoritos: _listFromJson(json["exerciciosFavoritos"]),
      exerciciosEvitados: _listFromJson(json["exerciciosEvitados"]),
      observacoes: json["observacoes"]?.toString() ?? "",
      diaPlano: json["diaPlano"]?.toString() ?? "",
      grupoDia: json["grupoDia"]?.toString() ?? "",
      ordemDia: _intFromJson(json["ordemDia"]),
      planoDias: _diasFromJson(json["planoDias"]),
      criadoPorIA: _boolFromJson(json["criadoPorIA"]),
      dataCriacao: json["dataCriacao"]?.toString() ?? "",
      exercicios: ((json["exercicios"] as List?) ?? [])
          .map((e) => ExercicioModel.fromJson(e))
          .toList(),
    );
  }

  TreinoModel somenteDia(TreinoDiaModel dia) {
    final ids = dia.exercicioIds.toSet();
    final exerciciosDoDia = ids.isEmpty
        ? exercicios
        : exercicios.where((exercicio) {
            return ids.contains(exercicio.id) || ids.contains(exercicio.nome);
          }).toList();

    return TreinoModel(
      id: "${id}_${dia.ordem}",
      nome: dia.codigo.trim().isEmpty
          ? dia.nome
          : "${dia.codigo} - ${dia.nome}",
      descricao: descricao,
      objetivo: objetivo,
      nivel: nivel,
      divisao: divisao,
      tempoEstimado: tempoEstimado,
      diasPorSemana: diasPorSemana,
      local: local,
      equipamentos: equipamentos,
      gruposPrioritarios: gruposPrioritarios,
      lesoesRestricoes: lesoesRestricoes,
      exerciciosFavoritos: exerciciosFavoritos,
      exerciciosEvitados: exerciciosEvitados,
      observacoes: observacoes,
      diaPlano: dia.codigo,
      grupoDia: dia.nome,
      ordemDia: dia.ordem,
      criadoPorIA: criadoPorIA,
      exercicios: exerciciosDoDia,
      dataCriacao: dataCriacao,
    );
  }

  static int _intFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? "") ?? fallback;
  }

  static bool _boolFromJson(dynamic value) {
    if (value is bool) return value;

    return value?.toString().toLowerCase() == "true";
  }

  static List<String> _listFromJson(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  static List<TreinoDiaModel> _diasFromJson(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => TreinoDiaModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class TreinoDiaModel {
  final String codigo;
  final String nome;
  final int ordem;
  final List<String> exercicioIds;

  const TreinoDiaModel({
    required this.codigo,
    required this.nome,
    required this.ordem,
    required this.exercicioIds,
  });

  Map<String, dynamic> toJson() {
    return {
      "codigo": codigo,
      "nome": nome,
      "ordem": ordem,
      "exercicioIds": exercicioIds,
    };
  }

  factory TreinoDiaModel.fromJson(Map<String, dynamic> json) {
    return TreinoDiaModel(
      codigo: json["codigo"]?.toString() ?? "",
      nome: json["nome"]?.toString() ?? "Treino",
      ordem: TreinoModel._intFromJson(json["ordem"]),
      exercicioIds: TreinoModel._listFromJson(json["exercicioIds"]),
    );
  }
}
