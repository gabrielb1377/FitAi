enum CoachInsightCategoria {
  evolucao,
  progressao,
  recuperacao,
  frequencia,
  recordes,
  sugestoes,
}

enum CoachInsightPrioridade { baixa, media, alta }

class CoachInsightModel {
  final String id;
  final String titulo;
  final String descricao;
  final String acao;
  final CoachInsightPrioridade prioridade;
  final CoachInsightCategoria categoria;
  final String icone;
  final String? exercicioId;
  final String? nomeExercicio;
  final String geradoEm;

  const CoachInsightModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.acao = '',
    required this.prioridade,
    required this.categoria,
    required this.icone,
    this.exercicioId,
    this.nomeExercicio,
    this.geradoEm = '',
  });

  factory CoachInsightModel.fromJson(
    Map<String, dynamic> json, {
    String? geradoEmFallback,
  }) {
    final categoria = _categoriaFromJson(json['categoria']);

    return CoachInsightModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Coach FitIA',
      descricao: json['descricao']?.toString() ?? '',
      acao: json['acao']?.toString() ?? '',
      prioridade: _prioridadeFromJson(json['prioridade']),
      categoria: categoria,
      icone: json['icone']?.toString() ?? _iconePadrao(categoria),
      exercicioId: _nullableString(json['exercicioId']),
      nomeExercicio: _nullableString(json['nomeExercicio']),
      geradoEm: json['geradoEm']?.toString() ?? geradoEmFallback ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'acao': acao,
      'prioridade': prioridade.name,
      'categoria': backendCategoria,
      'icone': icone,
      'exercicioId': exercicioId,
      'nomeExercicio': nomeExercicio,
      'geradoEm': geradoEm,
    };
  }

  String get categoriaLabel {
    switch (categoria) {
      case CoachInsightCategoria.evolucao:
        return 'Evolucao';
      case CoachInsightCategoria.progressao:
        return 'Progressao';
      case CoachInsightCategoria.recuperacao:
        return 'Recuperacao';
      case CoachInsightCategoria.frequencia:
        return 'Frequencia';
      case CoachInsightCategoria.recordes:
        return 'Recordes';
      case CoachInsightCategoria.sugestoes:
        return 'Sugestoes';
    }
  }

  String get prioridadeLabel {
    switch (prioridade) {
      case CoachInsightPrioridade.alta:
        return 'Alta';
      case CoachInsightPrioridade.media:
        return 'Media';
      case CoachInsightPrioridade.baixa:
        return 'Baixa';
    }
  }

  String get backendCategoria {
    switch (categoria) {
      case CoachInsightCategoria.evolucao:
        return 'progressao';
      case CoachInsightCategoria.progressao:
        return 'progressao';
      case CoachInsightCategoria.recuperacao:
        return 'recuperacao';
      case CoachInsightCategoria.frequencia:
        return 'frequencia';
      case CoachInsightCategoria.recordes:
        return 'recorde';
      case CoachInsightCategoria.sugestoes:
        return 'sugestao';
    }
  }

  static CoachInsightCategoria _categoriaFromJson(dynamic value) {
    final text = value?.toString().toLowerCase().trim() ?? '';

    switch (text) {
      case 'evolucao':
        return CoachInsightCategoria.evolucao;
      case 'progressao':
        return CoachInsightCategoria.progressao;
      case 'recuperacao':
        return CoachInsightCategoria.recuperacao;
      case 'frequencia':
        return CoachInsightCategoria.frequencia;
      case 'recorde':
      case 'recordes':
        return CoachInsightCategoria.recordes;
      case 'meta':
      case 'metas':
      case 'corrida':
      case 'corridas':
      case 'equilibrio_muscular':
      case 'sugestao':
      case 'sugestoes':
      default:
        return CoachInsightCategoria.sugestoes;
    }
  }

  static CoachInsightPrioridade _prioridadeFromJson(dynamic value) {
    final text = value?.toString().toLowerCase().trim() ?? '';

    return CoachInsightPrioridade.values.firstWhere(
      (item) => item.name == text,
      orElse: () => CoachInsightPrioridade.media,
    );
  }

  static String _iconePadrao(CoachInsightCategoria categoria) {
    switch (categoria) {
      case CoachInsightCategoria.evolucao:
        return 'trending_up';
      case CoachInsightCategoria.progressao:
        return 'fitness_center';
      case CoachInsightCategoria.recuperacao:
        return 'warning';
      case CoachInsightCategoria.frequencia:
        return 'local_fire_department';
      case CoachInsightCategoria.recordes:
        return 'emoji_events';
      case CoachInsightCategoria.sugestoes:
        return 'tips';
    }
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }
}
