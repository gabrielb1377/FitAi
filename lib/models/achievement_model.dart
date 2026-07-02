class AchievementModel {
  final String id;
  final String nome;
  final String descricao;
  final String icone;
  final String categoria;
  final bool desbloqueada;
  final DateTime? data;

  const AchievementModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.categoria,
    this.desbloqueada = false,
    this.data,
  });

  AchievementModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? icone,
    String? categoria,
    bool? desbloqueada,
    DateTime? data,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      icone: icone ?? this.icone,
      categoria: categoria ?? this.categoria,
      desbloqueada: desbloqueada ?? this.desbloqueada,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nome": nome,
      "descricao": descricao,
      "icone": icone,
      "categoria": categoria,
      "desbloqueada": desbloqueada,
      "data": data?.toIso8601String(),
    };
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json["id"]?.toString() ?? "",
      nome: json["nome"]?.toString() ?? "Conquista",
      descricao: json["descricao"]?.toString() ?? "",
      icone: json["icone"]?.toString() ?? "emoji_events",
      categoria: json["categoria"]?.toString() ?? "Geral",
      desbloqueada: json["desbloqueada"] == true,
      data: DateTime.tryParse(json["data"]?.toString() ?? ""),
    );
  }
}
