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
  final CoachInsightPrioridade prioridade;
  final CoachInsightCategoria categoria;
  final String icone;
  final String? exercicioId;
  final String? nomeExercicio;

  const CoachInsightModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.categoria,
    required this.icone,
    this.exercicioId,
    this.nomeExercicio,
  });

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
}
