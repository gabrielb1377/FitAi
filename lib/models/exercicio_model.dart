class ExercicioModel {
  final String id;
  final String nome;
  final String categoria;

  final String descricao;
  final String comoExecutar;
  final String cuidados;

  final List<String> musculos;
  final List<String> musculosSecundarios;
  final List<String> equipamentos;
  final List<String> locais;
  final List<String> tags;

  final String dificuldade;
  final String objetivo;
  final int caloriasHora;

  final String imagem;
  final String gifPath;
  final String video;

  final int series;
  final String repeticoes;
  final int descansoSegundos;
  final String rir;
  final String cadencia;
  final String observacoesTreino;

  bool favorito;

  ExercicioModel({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.descricao,
    required this.comoExecutar,
    required this.cuidados,
    required this.musculos,
    this.musculosSecundarios = const [],
    required this.equipamentos,
    required this.locais,
    required this.dificuldade,
    required this.objetivo,
    required this.imagem,
    this.gifPath = "",
    required this.video,
    required this.tags,
    required this.caloriasHora,
    this.series = 0,
    this.repeticoes = "",
    this.descansoSegundos = 0,
    this.rir = "",
    this.cadencia = "",
    this.observacoesTreino = "",
    this.favorito = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nome": nome,
      "categoria": categoria,
      "descricao": descricao,
      "comoExecutar": comoExecutar,
      "cuidados": cuidados,
      "musculos": musculos,
      "musculosSecundarios": musculosSecundarios,
      "equipamentos": equipamentos,
      "locais": locais,
      "dificuldade": dificuldade,
      "objetivo": objetivo,
      "imagem": imagem,
      "gifPath": gifPath,
      "video": video,
      "favorito": favorito,
      "tags": tags,
      "caloriasHora": caloriasHora,
      "series": series,
      "repeticoes": repeticoes,
      "descansoSegundos": descansoSegundos,
      "rir": rir,
      "cadencia": cadencia,
      "observacoesTreino": observacoesTreino,
    };
  }

  factory ExercicioModel.fromJson(Map<String, dynamic> json) {
    return ExercicioModel(
      id: json["id"] ?? "",
      nome: json["nome"] ?? "Exercício",
      categoria: json["categoria"] ?? "Geral",
      descricao: json["descricao"] ?? "",
      comoExecutar: json["comoExecutar"] ?? "",
      cuidados: json["cuidados"] ?? "",
      musculos: List<String>.from(json["musculos"] ?? const []),
      musculosSecundarios: List<String>.from(
        json["musculosSecundarios"] ?? const [],
      ),
      equipamentos: List<String>.from(json["equipamentos"] ?? const []),
      locais: List<String>.from(json["locais"] ?? const []),
      dificuldade: json["dificuldade"] ?? "Iniciante",
      objetivo: json["objetivo"] ?? "Geral",
      imagem: json["imagem"] ?? "",
      gifPath: json["gifPath"] ?? "",
      video: json["video"] ?? "",
      favorito: json["favorito"] ?? false,
      tags: List<String>.from(json["tags"] ?? const []),
      caloriasHora: json["caloriasHora"] ?? 0,
      series: _int(json["series"]),
      repeticoes: json["repeticoes"]?.toString() ?? "",
      descansoSegundos: _int(
        json["descansoSegundos"],
        fallback: _int(json["descanso"]),
      ),
      rir: json["rir"]?.toString() ?? "",
      cadencia: json["cadencia"]?.toString() ?? "",
      observacoesTreino: json["observacoesTreino"]?.toString() ?? "",
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
