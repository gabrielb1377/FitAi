enum FitaiNotificationCategoria {
  treinos,
  corridas,
  metas,
  recordes,
  coach,
  agenda,
  evolucao,
}

class FitaiNotificationModel {
  final String id;
  final String titulo;
  final String descricao;
  final FitaiNotificationCategoria categoria;
  final String icone;
  final DateTime data;
  final bool lida;
  final String acao;

  const FitaiNotificationModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.icone,
    required this.data,
    this.lida = false,
    this.acao = '',
  });

  FitaiNotificationModel copyWith({
    String? id,
    String? titulo,
    String? descricao,
    FitaiNotificationCategoria? categoria,
    String? icone,
    DateTime? data,
    bool? lida,
    String? acao,
  }) {
    return FitaiNotificationModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      icone: icone ?? this.icone,
      data: data ?? this.data,
      lida: lida ?? this.lida,
      acao: acao ?? this.acao,
    );
  }

  String get categoriaLabel {
    switch (categoria) {
      case FitaiNotificationCategoria.treinos:
        return 'Treinos';
      case FitaiNotificationCategoria.corridas:
        return 'Corridas';
      case FitaiNotificationCategoria.metas:
        return 'Metas';
      case FitaiNotificationCategoria.recordes:
        return 'Recordes';
      case FitaiNotificationCategoria.coach:
        return 'Coach FitIA';
      case FitaiNotificationCategoria.agenda:
        return 'Agenda';
      case FitaiNotificationCategoria.evolucao:
        return 'Evolucao';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria.name,
      'icone': icone,
      'data': data.toIso8601String(),
      'lida': lida,
      'acao': acao,
    };
  }

  factory FitaiNotificationModel.fromJson(Map<String, dynamic> json) {
    return FitaiNotificationModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Notificacao',
      descricao: json['descricao']?.toString() ?? '',
      categoria: _categoriaFromJson(json['categoria']),
      icone: json['icone']?.toString() ?? 'notifications',
      data:
          DateTime.tryParse(json['data']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lida: json['lida'] == true,
      acao: json['acao']?.toString() ?? '',
    );
  }

  static FitaiNotificationCategoria _categoriaFromJson(dynamic value) {
    final texto = value?.toString() ?? '';
    for (final categoria in FitaiNotificationCategoria.values) {
      if (categoria.name == texto) return categoria;
    }
    return FitaiNotificationCategoria.coach;
  }
}
