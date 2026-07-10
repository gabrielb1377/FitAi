import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/coach_insight_model.dart';
import '../models/exercicio_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import 'backend_coach_service.dart';
import 'metas_service.dart';
import 'storage_service.dart';

class CoachInsightService {
  const CoachInsightService();

  Future<List<CoachInsightModel>> gerarInsightsGerais() async {
    try {
      final backendInsights = await BackendCoachService().gerarInsights();
      if (backendInsights.isNotEmpty) {
        return backendInsights;
      }
    } catch (error) {
      _debugLog('Backend indisponivel. Usando Coach local: $error');
    }

    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();

    return analisarHistorico(
      historicoTreinos: historicoTreinos,
      historicoSeries: historicoSeries,
    );
  }

  Future<List<CoachInsightModel>> gerarInsightsExercicio(
    ExercicioModel exercicio,
  ) async {
    try {
      final backendInsights = await BackendCoachService().gerarInsights(
        tipo: 'exercicio',
        exercicioId: exercicio.id.trim().isEmpty
            ? exercicio.nome
            : exercicio.id,
      );
      if (backendInsights.isNotEmpty) {
        return backendInsights.take(5).toList();
      }
    } catch (error) {
      _debugLog('Backend indisponivel para exercicio. Usando local: $error');
    }

    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final series = _seriesDoExercicio(historicoSeries, exercicio);
    final insights = <CoachInsightModel>[
      ..._insightsExercicio(exercicio, series),
      ..._insightsRecuperacaoExercicio(exercicio, historicoTreinos, series),
    ];

    return _semDuplicar(insights).take(5).toList();
  }

  Future<List<CoachInsightModel>> gerarInsightsPorTipo(String tipo) async {
    try {
      final backendInsights = await BackendCoachService().gerarInsights(
        tipo: tipo,
      );
      if (backendInsights.isNotEmpty) {
        return backendInsights;
      }
    } catch (error) {
      _debugLog('Backend indisponivel para $tipo. Usando local: $error');
    }

    if (tipo == 'metas') {
      return _insightsMetasLocais();
    }

    if (tipo == 'corrida') {
      return _insightsCorridaLocais();
    }

    final gerais = await gerarInsightsGerais();
    return _filtrarPorTipo(gerais, tipo).take(8).toList();
  }

  List<CoachInsightModel> analisarHistorico({
    required List<HistoricoTreinoModel> historicoTreinos,
    required List<HistoricoSerieTreinoModel> historicoSeries,
  }) {
    if (historicoTreinos.isEmpty && historicoSeries.isEmpty) {
      return const [
        CoachInsightModel(
          id: 'coach_inicio',
          titulo: 'Base em construcao',
          descricao:
              'Finalize um treino e registre cargas para o FitIA aprender seu padrao.',
          prioridade: CoachInsightPrioridade.media,
          categoria: CoachInsightCategoria.sugestoes,
          icone: 'auto_awesome',
        ),
      ];
    }

    final agora = DateTime.now();
    final inicioSemana = _inicioSemana(agora);
    final inicioSemanaAnterior = inicioSemana.subtract(const Duration(days: 7));
    final fimSemana = inicioSemana.add(const Duration(days: 7));
    final seriesSemana = _seriesEntre(historicoSeries, inicioSemana, fimSemana);
    final seriesSemanaAnterior = _seriesEntre(
      historicoSeries,
      inicioSemanaAnterior,
      inicioSemana,
    );
    final treinosSemana = _treinosEntre(
      historicoTreinos,
      inicioSemana,
      fimSemana,
    );
    final treinosSemanaAnterior = _treinosEntre(
      historicoTreinos,
      inicioSemanaAnterior,
      inicioSemana,
    );
    final volumeSemana = _volumeTotal(treinosSemana, seriesSemana);
    final volumeAnterior = _volumeTotal(
      treinosSemanaAnterior,
      seriesSemanaAnterior,
    );
    final insights = <CoachInsightModel>[
      ..._insightsFrequencia(historicoTreinos, treinosSemana),
      ..._insightsVolume(volumeSemana, volumeAnterior),
      ..._insightsRecordes(historicoTreinos, historicoSeries),
      ..._insightsProgressaoGeral(historicoSeries),
      ..._insightsEquilibrioMuscular(historicoTreinos, historicoSeries),
      ..._insightsDescanso(historicoSeries),
    ];

    if (insights.isEmpty) {
      insights.add(
        const CoachInsightModel(
          id: 'coach_neutro',
          titulo: 'Padrao estavel',
          descricao:
              'Seus dados estao consistentes. Continue registrando cargas e descanso.',
          prioridade: CoachInsightPrioridade.baixa,
          categoria: CoachInsightCategoria.sugestoes,
          icone: 'tips',
        ),
      );
    }

    return _semDuplicar(insights).take(8).toList();
  }

  Future<List<CoachInsightModel>> _insightsMetasLocais() async {
    final resumo = await const MetasService().carregarMetas();

    return resumo.dicasCoach.take(3).map((dica) {
      return CoachInsightModel(
        id: 'meta_${_normalizar(dica)}',
        titulo: 'Dica para metas',
        descricao: dica,
        acao: 'Escolha uma meta pequena para avancar hoje.',
        prioridade: CoachInsightPrioridade.media,
        categoria: CoachInsightCategoria.sugestoes,
        icone: 'flag',
      );
    }).toList();
  }

  Future<List<CoachInsightModel>> _insightsCorridaLocais() async {
    final corridas = await StorageService.carregarCorridas();

    if (corridas.isEmpty) {
      return const [
        CoachInsightModel(
          id: 'corrida_sem_historico',
          titulo: 'Primeira corrida',
          descricao:
              'Registre uma corrida para receber analises de ritmo e distancia.',
          acao: 'Comece com uma corrida leve e salve o resultado.',
          prioridade: CoachInsightPrioridade.baixa,
          categoria: CoachInsightCategoria.sugestoes,
          icone: 'directions_run',
        ),
      ];
    }

    final distancia = corridas.fold<double>(
      0,
      (total, corrida) => total + corrida.distancia,
    );

    return [
      CoachInsightModel(
        id: 'corrida_distancia_local',
        titulo: 'Historico de corrida',
        descricao:
            'Voce tem ${corridas.length} corrida(s) salvas e ${distancia.toStringAsFixed(1)} km acumulados.',
        acao: 'Mantenha progressao gradual de distancia ou ritmo.',
        prioridade: CoachInsightPrioridade.baixa,
        categoria: CoachInsightCategoria.sugestoes,
        icone: 'directions_run',
      ),
    ];
  }

  List<CoachInsightModel> _filtrarPorTipo(
    List<CoachInsightModel> insights,
    String tipo,
  ) {
    switch (tipo) {
      case 'progressao':
        return insights.where((insight) {
          return insight.categoria == CoachInsightCategoria.progressao ||
              insight.categoria == CoachInsightCategoria.evolucao ||
              insight.categoria == CoachInsightCategoria.recordes;
        }).toList();
      case 'recuperacao':
        return insights
            .where(
              (insight) =>
                  insight.categoria == CoachInsightCategoria.recuperacao,
            )
            .toList();
      case 'frequencia':
        return insights
            .where(
              (insight) =>
                  insight.categoria == CoachInsightCategoria.frequencia,
            )
            .toList();
      default:
        return insights;
    }
  }

  List<CoachInsightModel> _insightsExercicio(
    ExercicioModel exercicio,
    List<HistoricoSerieTreinoModel> series,
  ) {
    if (series.isEmpty) {
      return [
        CoachInsightModel(
          id: 'exercicio_sem_historico_${_normalizar(exercicio.nome)}',
          titulo: 'Primeira referencia',
          descricao:
              'Ainda nao ha execucoes registradas para ${exercicio.nome}. Registre peso e repeticoes para receber progresso real.',
          prioridade: CoachInsightPrioridade.media,
          categoria: CoachInsightCategoria.sugestoes,
          icone: 'tips',
          exercicioId: exercicio.id,
          nomeExercicio: exercicio.nome,
        ),
      ];
    }

    final ordenadas = [...series]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final ultima = ordenadas.first;
    final anterior = ordenadas.length > 1 ? ordenadas[1] : null;
    final melhorCarga = ordenadas.map((s) => s.peso).reduce(math.max);
    final melhorVolume = ordenadas.map((s) => s.volume).reduce(math.max);
    final mediaReps =
        ordenadas.fold<int>(0, (total, s) => total + s.repeticoes) /
        ordenadas.length;
    final insights = <CoachInsightModel>[];

    if (anterior != null && anterior.peso > 0 && ultima.peso > anterior.peso) {
      final variacao = ((ultima.peso - anterior.peso) / anterior.peso) * 100;
      insights.add(
        CoachInsightModel(
          id: 'carga_${_normalizar(exercicio.nome)}',
          titulo: 'Carga aumentou',
          descricao:
              'Carga aumentou ${variacao.toStringAsFixed(0)}% em ${exercicio.nome}.',
          prioridade: CoachInsightPrioridade.alta,
          categoria: CoachInsightCategoria.evolucao,
          icone: 'trending_up',
          exercicioId: exercicio.id,
          nomeExercicio: exercicio.nome,
        ),
      );
    }

    if (ultima.peso >= melhorCarga && ordenadas.length > 1) {
      insights.add(
        CoachInsightModel(
          id: 'recorde_carga_${_normalizar(exercicio.nome)}',
          titulo: 'Recorde de carga',
          descricao:
              'Sua melhor carga neste exercicio e ${_formatarPeso(melhorCarga)}.',
          prioridade: CoachInsightPrioridade.alta,
          categoria: CoachInsightCategoria.recordes,
          icone: 'emoji_events',
          exercicioId: exercicio.id,
          nomeExercicio: exercicio.nome,
        ),
      );
    }

    final ultimasTres = ordenadas.take(3).toList().reversed.toList();
    if (ultimasTres.length == 3 &&
        ultimasTres.last.peso > ultimasTres.first.peso &&
        ultimasTres[1].peso >= ultimasTres.first.peso) {
      insights.add(
        CoachInsightModel(
          id: 'tres_melhoras_${_normalizar(exercicio.nome)}',
          titulo: 'Sequencia de melhora',
          descricao: 'Os ultimos 3 registros indicam melhora progressiva.',
          prioridade: CoachInsightPrioridade.media,
          categoria: CoachInsightCategoria.evolucao,
          icone: 'timeline',
          exercicioId: exercicio.id,
          nomeExercicio: exercicio.nome,
        ),
      );
    }

    final sugestao = _sugestaoProximaCarga(ultima);
    insights.add(
      CoachInsightModel(
        id: 'sugestao_${_normalizar(exercicio.nome)}',
        titulo: 'Sugestao de proxima serie',
        descricao: sugestao,
        prioridade: CoachInsightPrioridade.media,
        categoria: CoachInsightCategoria.progressao,
        icone: 'fitness_center',
        exercicioId: exercicio.id,
        nomeExercicio: exercicio.nome,
      ),
    );

    insights.add(
      CoachInsightModel(
        id: 'resumo_${_normalizar(exercicio.nome)}',
        titulo: 'Resumo do exercicio',
        descricao:
            '${ordenadas.length} series registradas, media de ${mediaReps.toStringAsFixed(1)} reps e melhor volume de ${_formatarPeso(melhorVolume)}.',
        prioridade: CoachInsightPrioridade.baixa,
        categoria: CoachInsightCategoria.sugestoes,
        icone: 'analytics',
        exercicioId: exercicio.id,
        nomeExercicio: exercicio.nome,
      ),
    );

    return insights;
  }

  List<CoachInsightModel> _insightsRecuperacaoExercicio(
    ExercicioModel exercicio,
    List<HistoricoTreinoModel> historicoTreinos,
    List<HistoricoSerieTreinoModel> series,
  ) {
    final ultimaData = series.isNotEmpty
        ? series.map((s) => s.dataHora).reduce((a, b) => a.isAfter(b) ? a : b)
        : _ultimaDataPorTexto(historicoTreinos, exercicio.categoria);
    if (ultimaData == null) return const [];

    final dias = _somenteData(
      DateTime.now(),
    ).difference(_somenteData(ultimaData)).inDays;
    if (dias < 7) return const [];

    return [
      CoachInsightModel(
        id: 'dias_sem_${_normalizar(exercicio.nome)}',
        titulo: 'Recuperacao longa',
        descricao:
            'Voce nao registra ${exercicio.nome} ha $dias dias. Retome com carga controlada.',
        prioridade: CoachInsightPrioridade.media,
        categoria: CoachInsightCategoria.recuperacao,
        icone: 'warning',
        exercicioId: exercicio.id,
        nomeExercicio: exercicio.nome,
      ),
    ];
  }

  List<CoachInsightModel> _insightsFrequencia(
    List<HistoricoTreinoModel> historico,
    List<HistoricoTreinoModel> semana,
  ) {
    final insights = <CoachInsightModel>[];
    final ultima = historico.isEmpty
        ? null
        : historico
              .map((h) => h.dataHora)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    final diasSemTreinar = ultima == null
        ? null
        : _somenteData(DateTime.now()).difference(_somenteData(ultima)).inDays;

    if (diasSemTreinar != null && diasSemTreinar >= 4) {
      insights.add(
        CoachInsightModel(
          id: 'dias_sem_treinar',
          titulo: 'Retomar consistencia',
          descricao:
              'Voce esta ha $diasSemTreinar dias sem finalizar treino. Um treino leve ja reativa a rotina.',
          prioridade: CoachInsightPrioridade.alta,
          categoria: CoachInsightCategoria.frequencia,
          icone: 'calendar',
        ),
      );
    }

    if (semana.length >= 3) {
      insights.add(
        CoachInsightModel(
          id: 'frequencia_semana',
          titulo: 'Frequencia forte',
          descricao: 'Voce treinou ${semana.length} vezes esta semana.',
          prioridade: CoachInsightPrioridade.media,
          categoria: CoachInsightCategoria.frequencia,
          icone: 'local_fire_department',
        ),
      );
    }

    return insights;
  }

  List<CoachInsightModel> _insightsVolume(double atual, double anterior) {
    if (anterior <= 0 && atual <= 0) return const [];
    if (anterior <= 0) {
      return [
        CoachInsightModel(
          id: 'volume_inicial',
          titulo: 'Volume semanal registrado',
          descricao:
              'Seu volume desta semana chegou a ${_formatarPeso(atual)}.',
          prioridade: CoachInsightPrioridade.baixa,
          categoria: CoachInsightCategoria.evolucao,
          icone: 'bar_chart',
        ),
      ];
    }

    final variacao = ((atual - anterior) / anterior) * 100;
    if (variacao.abs() < 8) return const [];

    return [
      CoachInsightModel(
        id: 'volume_semanal',
        titulo: variacao >= 0 ? 'Volume semanal subiu' : 'Volume semanal caiu',
        descricao:
            'Seu volume semanal ${variacao >= 0 ? 'aumentou' : 'caiu'} ${variacao.abs().toStringAsFixed(0)}%.',
        prioridade: variacao >= 0
            ? CoachInsightPrioridade.media
            : CoachInsightPrioridade.alta,
        categoria: variacao >= 0
            ? CoachInsightCategoria.evolucao
            : CoachInsightCategoria.recuperacao,
        icone: variacao >= 0 ? 'trending_up' : 'trending_down',
      ),
    ];
  }

  List<CoachInsightModel> _insightsRecordes(
    List<HistoricoTreinoModel> historicoTreinos,
    List<HistoricoSerieTreinoModel> historicoSeries,
  ) {
    final recentes = historicoTreinos
        .where((treino) {
          return DateTime.now().difference(treino.dataHora).inDays <= 14;
        })
        .fold<int>(0, (total, treino) => total + treino.recordesBatidos);
    final insights = <CoachInsightModel>[];

    if (recentes > 0) {
      insights.add(
        CoachInsightModel(
          id: 'recordes_recentes',
          titulo: 'Novos recordes',
          descricao:
              'Voce bateu $recentes recorde${recentes == 1 ? '' : 's'} recentemente.',
          prioridade: CoachInsightPrioridade.alta,
          categoria: CoachInsightCategoria.recordes,
          icone: 'emoji_events',
        ),
      );
    }

    final melhor = historicoSeries.where((s) => s.peso > 0).toList()
      ..sort((a, b) => b.peso.compareTo(a.peso));
    if (melhor.isNotEmpty) {
      insights.add(
        CoachInsightModel(
          id: 'maior_carga_global',
          titulo: 'Melhor carga registrada',
          descricao:
              '${melhor.first.nomeExercicio}: ${_formatarPeso(melhor.first.peso)} x ${melhor.first.repeticoes} reps.',
          prioridade: CoachInsightPrioridade.media,
          categoria: CoachInsightCategoria.recordes,
          icone: 'military_tech',
          exercicioId: melhor.first.exercicioId,
          nomeExercicio: melhor.first.nomeExercicio,
        ),
      );
    }

    return insights;
  }

  List<CoachInsightModel> _insightsProgressaoGeral(
    List<HistoricoSerieTreinoModel> historico,
  ) {
    final porExercicio = <String, List<HistoricoSerieTreinoModel>>{};
    for (final serie in historico) {
      porExercicio
          .putIfAbsent(_normalizar(serie.nomeExercicio), () => [])
          .add(serie);
    }

    for (final series in porExercicio.values) {
      series.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    }

    final recentes =
        porExercicio.values.where((series) => series.length >= 2).toList()
          ..sort((a, b) => b.first.dataHora.compareTo(a.first.dataHora));

    if (recentes.isEmpty) return const [];

    final series = recentes.first;
    final atual = series.first;
    final anterior = series[1];
    if (anterior.peso <= 0 || atual.peso <= anterior.peso) return const [];

    final variacao = ((atual.peso - anterior.peso) / anterior.peso) * 100;
    return [
      CoachInsightModel(
        id: 'progressao_recente_${_normalizar(atual.nomeExercicio)}',
        titulo: 'Progressao recente',
        descricao:
            '${atual.nomeExercicio} subiu ${variacao.toStringAsFixed(0)}% em relacao ao registro anterior.',
        prioridade: CoachInsightPrioridade.media,
        categoria: CoachInsightCategoria.progressao,
        icone: 'trending_up',
        exercicioId: atual.exercicioId,
        nomeExercicio: atual.nomeExercicio,
      ),
    ];
  }

  List<CoachInsightModel> _insightsEquilibrioMuscular(
    List<HistoricoTreinoModel> historicoTreinos,
    List<HistoricoSerieTreinoModel> historicoSeries,
  ) {
    final contagem = {for (final grupo in _grupos.keys) grupo: 0.0};
    for (final serie in historicoSeries) {
      final grupo = _grupoPorTexto(serie.nomeExercicio);
      if (grupo != null) {
        contagem[grupo] = (contagem[grupo] ?? 0) + serie.volume;
      }
    }
    for (final treino in historicoTreinos) {
      final grupo = _grupoPorTexto('${treino.nomeTreino} ${treino.objetivo}');
      if (grupo != null) {
        contagem[grupo] = (contagem[grupo] ?? 0) + treino.exerciciosConcluidos;
      }
    }

    final peito = contagem['Peito'] ?? 0;
    final costas = contagem['Costas'] ?? 0;
    final pernas = contagem['Pernas'] ?? 0;
    final insights = <CoachInsightModel>[];

    if (peito > 0 && costas > 0 && peito > costas * 1.8) {
      insights.add(
        const CoachInsightModel(
          id: 'peito_costas_desbalanceado',
          titulo: 'Equilibrio muscular',
          descricao:
              'Voce esta treinando peito muito mais que costas. Considere equilibrar puxadas e remadas.',
          prioridade: CoachInsightPrioridade.media,
          categoria: CoachInsightCategoria.sugestoes,
          icone: 'balance',
        ),
      );
    }

    if (pernas <= 0 && historicoTreinos.isNotEmpty) {
      insights.add(
        const CoachInsightModel(
          id: 'pernas_ausentes',
          titulo: 'Pernas fora da semana',
          descricao:
              'Nao ha registros claros de pernas. Um treino leve de pernas ajuda a manter equilibrio.',
          prioridade: CoachInsightPrioridade.alta,
          categoria: CoachInsightCategoria.recuperacao,
          icone: 'warning',
        ),
      );
    }

    return insights;
  }

  List<CoachInsightModel> _insightsDescanso(
    List<HistoricoSerieTreinoModel> historico,
  ) {
    final comDescanso = historico.where((s) => s.descansoSegundos > 0).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    if (comDescanso.length < 6) return const [];

    final recentes = comDescanso.take(3).toList();
    final anteriores = comDescanso.skip(3).take(3).toList();
    final mediaRecente = _mediaDescanso(recentes);
    final mediaAnterior = _mediaDescanso(anteriores);
    if (mediaAnterior <= 0 || mediaRecente >= mediaAnterior - 10) {
      return const [];
    }

    return [
      CoachInsightModel(
        id: 'descanso_menor',
        titulo: 'Descanso mais curto',
        descricao:
            'Seu descanso medio diminuiu de ${mediaAnterior.round()}s para ${mediaRecente.round()}s. Monitore a qualidade das repeticoes.',
        prioridade: CoachInsightPrioridade.media,
        categoria: CoachInsightCategoria.recuperacao,
        icone: 'timer',
      ),
    ];
  }

  List<HistoricoSerieTreinoModel> _seriesDoExercicio(
    List<HistoricoSerieTreinoModel> historico,
    ExercicioModel exercicio,
  ) {
    final id = exercicio.id.trim();
    final nome = _normalizar(exercicio.nome);
    final series = historico.where((serie) {
      return (id.isNotEmpty && serie.exercicioId.trim() == id) ||
          _normalizar(serie.nomeExercicio) == nome;
    }).toList();
    series.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return series;
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

  double _volumeTotal(
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

  DateTime? _ultimaDataPorTexto(
    List<HistoricoTreinoModel> historico,
    String texto,
  ) {
    final busca = _normalizar(texto);
    final matches = historico.where((treino) {
      return _normalizar(
        '${treino.nomeTreino} ${treino.objetivo}',
      ).contains(busca);
    }).toList();
    if (matches.isEmpty) return null;
    return matches
        .map((h) => h.dataHora)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String _sugestaoProximaCarga(HistoricoSerieTreinoModel ultima) {
    if (ultima.peso <= 0) {
      return 'Registre carga na proxima serie para gerar uma sugestao precisa.';
    }
    if (ultima.repeticoes > 10) {
      return 'Considere aumentar para ${_formatarPeso(ultima.peso + 2.5)} mantendo 8-10 reps.';
    }
    if (ultima.repeticoes < 6) {
      return 'Repita ou reduza para ${_formatarPeso(math.max(0, ultima.peso - 2.5))}.';
    }
    return 'Mantenha ${_formatarPeso(ultima.peso)} e tente consolidar a faixa de reps.';
  }

  double _mediaDescanso(List<HistoricoSerieTreinoModel> series) {
    if (series.isEmpty) return 0;
    return series.fold<int>(
          0,
          (total, serie) => total + serie.descansoSegundos,
        ) /
        series.length;
  }

  String? _grupoPorTexto(String texto) {
    final valor = _normalizar(texto);
    for (final entrada in _grupos.entries) {
      if (entrada.value.any((keyword) => valor.contains(keyword))) {
        return entrada.key;
      }
    }
    return null;
  }

  List<CoachInsightModel> _semDuplicar(List<CoachInsightModel> insights) {
    final vistos = <String>{};
    final filtrados = <CoachInsightModel>[];

    for (final insight in insights) {
      final chave = '${insight.titulo}|${insight.descricao}';
      if (vistos.add(chave)) filtrados.add(insight);
    }

    filtrados.sort((a, b) {
      final prioridade =
          _pesoPrioridade(b.prioridade) - _pesoPrioridade(a.prioridade);
      if (prioridade != 0) return prioridade;
      return a.titulo.compareTo(b.titulo);
    });
    return filtrados;
  }

  int _pesoPrioridade(CoachInsightPrioridade prioridade) {
    switch (prioridade) {
      case CoachInsightPrioridade.alta:
        return 3;
      case CoachInsightPrioridade.media:
        return 2;
      case CoachInsightPrioridade.baixa:
        return 1;
    }
  }

  DateTime _inicioSemana(DateTime data) {
    final base = _somenteData(data.toLocal());
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  DateTime _somenteData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  String _formatarPeso(double peso) {
    final texto = peso == peso.roundToDouble()
        ? peso.round().toString()
        : peso.toStringAsFixed(1).replaceAll('.', ',');
    return '$texto kg';
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

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }
    return valor;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[CoachInsightService] $message');
    }
  }
}

const _grupos = {
  'Peito': ['peito', 'peitoral', 'supino', 'crucifixo', 'flexao', 'crossover'],
  'Costas': ['costas', 'dorso', 'remada', 'puxada', 'barra', 'terra'],
  'Pernas': ['perna', 'agachamento', 'leg', 'cadeira', 'panturrilha', 'coxa'],
  'Ombros': ['ombro', 'deltoide', 'desenvolvimento', 'elevacao'],
  'Bracos': ['biceps', 'triceps', 'rosca', 'curl', 'frances'],
  'Abdomen': ['abdomen', 'abdominal', 'prancha', 'core'],
  'Gluteos': ['gluteo', 'gluteos', 'hip thrust'],
};
