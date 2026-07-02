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
  final String video;

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
    required this.video,
    required this.tags,
    required this.caloriasHora,
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
      "video": video,
      "favorito": favorito,
      "tags": tags,
      "caloriasHora": caloriasHora,
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
      musculosSecundarios:
          List<String>.from(json["musculosSecundarios"] ?? const []),
      equipamentos: List<String>.from(json["equipamentos"] ?? const []),
      locais: List<String>.from(json["locais"] ?? const []),
      dificuldade: json["dificuldade"] ?? "Iniciante",
      objetivo: json["objetivo"] ?? "Geral",
      imagem: json["imagem"] ?? "",
      video: json["video"] ?? "",
      favorito: json["favorito"] ?? false,
      tags: List<String>.from(json["tags"] ?? const []),
      caloriasHora: json["caloriasHora"] ?? 0,
    );
  }
}