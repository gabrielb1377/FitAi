import '../data/exercicios/exercicios.dart';
import '../models/exercicio_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import 'storage_service.dart';
import 'streak_service.dart';

enum InsightTipo { positivo, alerta, neutro }

class InsightEvolucao {
  final String titulo;
  final String descricao;
  final InsightTipo tipo;
  final String icone;

  const InsightEvolucao({
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.icone,
  });
}

class InsightsService {
  const InsightsService();

  Future<List<InsightEvolucao>> gerarInsights() async {
    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();

    return analisarHistorico(
      historicoTreinos: historicoTreinos,
      historicoSeries: historicoSeries,
    );
  }

  List<InsightEvolucao> analisarHistorico({
    required List<HistoricoTreinoModel> historicoTreinos,
    required List<HistoricoSerieTreinoModel> historicoSeries,
  }) {
    if (historicoTreinos.length < 2 && historicoSeries.length < 4) {
      return const [];
    }

    final agora = DateTime.now();
    final inicioSemanaAtual = _inicioSemana(agora);
    final inicioSemanaAnterior = inicioSemanaAtual.subtract(
      const Duration(days: 7),
    );
    final fimSemanaAtual = inicioSemanaAtual.add(const Duration(days: 7));
    final treinosSemana = _treinosEntre(
      historicoTreinos,
      inicioSemanaAtual,
      fimSemanaAtual,
    );
    final treinosSemanaAnterior = _treinosEntre(
      historicoTreinos,
      inicioSemanaAnterior,
      inicioSemanaAtual,
    );
    final seriesSemana = _seriesEntre(
      historicoSeries,
      inicioSemanaAtual,
      fimSemanaAtual,
    );
    final seriesSemanaAnterior = _seriesEntre(
      historicoSeries,
      inicioSemanaAnterior,
      inicioSemanaAtual,
    );
    final volumeSemana = _volumeDaSemana(treinosSemana, seriesSemana);
    final volumeSemanaAnterior = _volumeDaSemana(
      treinosSemanaAnterior,
      seriesSemanaAnterior,
    );
    final totalTempo = historicoTreinos.fold<int>(
      0,
      (total, treino) => total + treino.tempoSegundos,
    );
    final recordesRecentes = _recordesRecentes(historicoTreinos, agora);
    final streak = const StreakService().calcularStreak(historicoTreinos);
    final gruposSemana = _contarGruposMusculares(seriesSemana);
    final insights = <InsightEvolucao>[];

    insights.add(_insightFrequencia(treinosSemana.length));

    final insightVolume = _insightVolume(volumeSemana, volumeSemanaAnterior);
    if (insightVolume != null) insights.add(insightVolume);

    final insightSeries = _insightSeries(seriesSemana, treinosSemana);
    if (insightSeries != null) insights.add(insightSeries);

    if (recordesRecentes > 0) {
      insights.add(
        InsightEvolucao(
          titulo: 'Recordes em alta',
          descricao:
              'Voce bateu $recordesRecentes recorde${recordesRecentes == 1 ? '' : 's'} pessoal${recordesRecentes == 1 ? '' : 'is'} recentemente.',
          tipo: InsightTipo.positivo,
          icone: 'pr',
        ),
      );
    }

    final insightStreak = _insightStreak(streak);
    if (insightStreak != null) insights.add(insightStreak);

    final insightGrupoMaisTreinado = _insightGrupoMaisTreinado(gruposSemana);
    if (insightGrupoMaisTreinado != null) {
      insights.add(insightGrupoMaisTreinado);
    }

    final insightGrupoPoucoTreinado = _insightGrupoPoucoTreinado(gruposSemana);
    if (insightGrupoPoucoTreinado != null) {
      insights.add(insightGrupoPoucoTreinado);
    }

    if (totalTempo > 0 && insights.length < 6) {
      insights.add(
        InsightEvolucao(
          titulo: 'Tempo acumulado',
          descricao:
              'Voce ja acumulou ${_formatarDuracao(totalTempo)} de treino no FitIA.',
          tipo: InsightTipo.neutro,
          icone: 'timer',
        ),
      );
    }

    return insights.take(6).toList();
  }

  InsightEvolucao _insightFrequencia(int treinosSemana) {
    if (treinosSemana <= 0) {
      return const InsightEvolucao(
        titulo: 'Semana ainda zerada',
        descricao:
            'Voce ainda nao treinou esta semana. Um treino curto ja recoloca o ritmo em movimento.',
        tipo: InsightTipo.alerta,
        icone: 'calendar',
      );
    }

    if (treinosSemana >= 3) {
      return InsightEvolucao(
        titulo: 'Consistencia forte',
        descricao:
            'Voce treinou $treinosSemana vezes esta semana. Mantenha a consistencia.',
        tipo: InsightTipo.positivo,
        icone: 'calendar',
      );
    }

    return InsightEvolucao(
      titulo: 'Ritmo da semana',
      descricao:
          'Voce treinou $treinosSemana vez${treinosSemana == 1 ? '' : 'es'} esta semana. Mais uma sessao ajuda a consolidar o habito.',
      tipo: InsightTipo.neutro,
      icone: 'calendar',
    );
  }

  InsightEvolucao? _insightVolume(double atual, double anterior) {
    if (atual <= 0 && anterior <= 0) return null;

    if (anterior <= 0) {
      return InsightEvolucao(
        titulo: 'Volume registrado',
        descricao:
            'Seu volume desta semana ja chegou a ${_formatarPeso(atual)}.',
        tipo: InsightTipo.positivo,
        icone: 'volume',
      );
    }

    final variacao = ((atual - anterior) / anterior) * 100;

    if (variacao >= 5) {
      return InsightEvolucao(
        titulo: 'Volume subindo',
        descricao:
            'Seu volume aumentou ${variacao.abs().toStringAsFixed(0)}% em relacao a semana passada.',
        tipo: InsightTipo.positivo,
        icone: 'volume',
      );
    }

    if (variacao <= -5) {
      return InsightEvolucao(
        titulo: 'Volume em queda',
        descricao:
            'Seu volume caiu ${variacao.abs().toStringAsFixed(0)}% em relacao a semana passada. Ajuste a carga ou a frequencia com calma.',
        tipo: InsightTipo.alerta,
        icone: 'volume',
      );
    }

    return const InsightEvolucao(
      titulo: 'Volume estavel',
      descricao:
          'Seu volume esta parecido com o da semana passada. Boa base para progredir sem pressa.',
      tipo: InsightTipo.neutro,
      icone: 'volume',
    );
  }

  InsightEvolucao? _insightSeries(
    List<HistoricoSerieTreinoModel> seriesSemana,
    List<HistoricoTreinoModel> treinosSemana,
  ) {
    final totalSeries = seriesSemana.isNotEmpty
        ? seriesSemana.length
        : treinosSemana.fold<int>(
            0,
            (total, treino) => total + treino.seriesConcluidas,
          );

    if (totalSeries <= 0) return null;

    if (totalSeries >= 24) {
      return InsightEvolucao(
        titulo: 'Boa densidade',
        descricao:
            'Voce concluiu $totalSeries series nesta semana. A base de trabalho esta consistente.',
        tipo: InsightTipo.positivo,
        icone: 'series',
      );
    }

    return InsightEvolucao(
      titulo: 'Series da semana',
      descricao:
          'Voce concluiu $totalSeries series nesta semana. Use isso como referencia para evoluir aos poucos.',
      tipo: InsightTipo.neutro,
      icone: 'series',
    );
  }

  InsightEvolucao? _insightStreak(StreakResumo streak) {
    if (streak.atual >= 3) {
      return InsightEvolucao(
        titulo: 'Sequencia ativa',
        descricao:
            'Voce esta em uma sequencia de ${streak.atual} dias treinando.',
        tipo: InsightTipo.positivo,
        icone: 'streak',
      );
    }

    if (streak.atual == 0) {
      return const InsightEvolucao(
        titulo: 'Retome a sequencia',
        descricao:
            'Sua sequencia atual esta em 0 dias. Um treino leve hoje ja conta.',
        tipo: InsightTipo.alerta,
        icone: 'streak',
      );
    }

    return null;
  }

  InsightEvolucao? _insightGrupoMaisTreinado(Map<String, int> gruposSemana) {
    final ativos = gruposSemana.entries.where((item) => item.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (ativos.isEmpty) return null;

    return InsightEvolucao(
      titulo: 'Grupo em destaque',
      descricao: '${ativos.first.key} foi o grupo mais treinado esta semana.',
      tipo: InsightTipo.neutro,
      icone: 'muscle',
    );
  }

  InsightEvolucao? _insightGrupoPoucoTreinado(Map<String, int> gruposSemana) {
    if (gruposSemana.values.every((valor) => valor == 0)) return null;

    for (final grupo in _gruposMuscularesBase) {
      if ((gruposSemana[grupo] ?? 0) == 0) {
        return InsightEvolucao(
          titulo: 'Ponto de atencao',
          descricao:
              'Voce ainda nao treinou $grupo esta semana. Considere equilibrar a ficha se fizer sentido para seu objetivo.',
          tipo: InsightTipo.alerta,
          icone: 'alert',
        );
      }
    }

    return null;
  }

  int _recordesRecentes(
    List<HistoricoTreinoModel> historicoTreinos,
    DateTime agora,
  ) {
    final inicio = _somenteData(agora).subtract(const Duration(days: 14));

    return historicoTreinos
        .where((treino) {
          final data = _somenteData(treino.dataHora);
          return !data.isBefore(inicio);
        })
        .fold<int>(0, (total, treino) => total + treino.recordesBatidos);
  }

  List<HistoricoTreinoModel> _treinosEntre(
    List<HistoricoTreinoModel> historico,
    DateTime inicio,
    DateTime fim,
  ) {
    return historico.where((treino) {
      final data = _somenteData(treino.dataHora);
      return !data.isBefore(inicio) && data.isBefore(fim);
    }).toList();
  }

  List<HistoricoSerieTreinoModel> _seriesEntre(
    List<HistoricoSerieTreinoModel> historico,
    DateTime inicio,
    DateTime fim,
  ) {
    return historico.where((serie) {
      final data = _somenteData(serie.dataHora);
      return !data.isBefore(inicio) && data.isBefore(fim);
    }).toList();
  }

  double _volumeDaSemana(
    List<HistoricoTreinoModel> treinos,
    List<HistoricoSerieTreinoModel> series,
  ) {
    final volumeSeries = series.fold<double>(
      0,
      (total, serie) => total + serie.volume,
    );

    if (volumeSeries > 0) return volumeSeries;

    return treinos.fold<double>(
      0,
      (total, treino) => total + treino.volumeTotal,
    );
  }

  Map<String, int> _contarGruposMusculares(
    List<HistoricoSerieTreinoModel> series,
  ) {
    final contagem = <String, int>{
      for (final grupo in _gruposMuscularesBase) grupo: 0,
    };

    if (series.isEmpty) return contagem;

    final exerciciosPorId = <String, ExercicioModel>{};
    final exerciciosPorNome = <String, ExercicioModel>{};

    for (final exercicio in bancoExercicios) {
      exerciciosPorId[exercicio.id] = exercicio;
      exerciciosPorNome[_normalizar(exercicio.nome)] = exercicio;
    }

    for (final serie in series) {
      final exercicio =
          exerciciosPorId[serie.exercicioId] ??
          exerciciosPorNome[_normalizar(serie.nomeExercicio)];
      final textos = <String>[
        serie.nomeExercicio,
        if (exercicio != null) ...[
          exercicio.categoria,
          ...exercicio.musculos,
          ...exercicio.musculosSecundarios,
          ...exercicio.tags,
        ],
      ];

      for (final grupo in _gruposMuscularesBase) {
        if (textos.any((texto) => _combinaGrupo(grupo, texto))) {
          contagem[grupo] = (contagem[grupo] ?? 0) + 1;
        }
      }
    }

    return contagem;
  }

  bool _combinaGrupo(String grupo, String texto) {
    final alvo = _normalizar(grupo);
    final valor = _normalizar(texto);

    if (valor.contains(alvo)) return true;

    switch (alvo) {
      case 'peito':
        return valor.contains('peitoral');
      case 'costas':
        return valor.contains('dorso') ||
            valor.contains('latissimo') ||
            valor.contains('romboide');
      case 'pernas':
        return valor.contains('perna') ||
            valor.contains('quadriceps') ||
            valor.contains('isquiotib') ||
            valor.contains('coxa') ||
            valor.contains('panturrilha');
      case 'ombros':
        return valor.contains('ombro') || valor.contains('deltoide');
      case 'biceps':
        return valor.contains('biceps');
      case 'triceps':
        return valor.contains('triceps');
      case 'gluteos':
        return valor.contains('glute');
      case 'abdomen':
        return valor.contains('abdomen') ||
            valor.contains('abdominal') ||
            valor.contains('core');
    }

    return false;
  }

  DateTime _inicioSemana(DateTime data) {
    final dia = _somenteData(data);
    return dia.subtract(Duration(days: dia.weekday - DateTime.monday));
  }

  DateTime _somenteData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  String _formatarPeso(double peso) {
    if (peso >= 1000) {
      return '${_formatarNumero(peso / 1000)} t';
    }

    return '${_formatarNumero(peso)} kg';
  }

  String _formatarNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _formatarDuracao(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;

    if (horas <= 0) return '${minutos}min';
    if (minutos <= 0) return '${horas}h';

    return '${horas}h ${minutos}min';
  }

  String _normalizar(String texto) {
    var valor = texto.toLowerCase().trim();
    const substituicoes = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    substituicoes.forEach((origem, destino) {
      valor = valor.replaceAll(origem, destino);
    });

    return valor;
  }
}

const _gruposMuscularesBase = [
  'Peito',
  'Costas',
  'Pernas',
  'Ombros',
  'Biceps',
  'Triceps',
  'Gluteos',
  'Abdomen',
];
