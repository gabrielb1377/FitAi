import '../models/exercicio_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/progresso_exercicio_model.dart';
import 'storage_service.dart';

enum TipoProgressao { inicial, progressao, manutencao, deload }

enum IndicadorProgressao { evolucao, queda, estavel }

class UltimaExecucaoExercicio {
  final double peso;
  final int repeticoes;
  final int series;
  final int menorRepeticoes;
  final int maiorRepeticoes;
  final DateTime dataHora;

  const UltimaExecucaoExercicio({
    required this.peso,
    required this.repeticoes,
    required this.series,
    required this.menorRepeticoes,
    required this.maiorRepeticoes,
    required this.dataHora,
  });
}

class ProgressaoSugestao {
  final UltimaExecucaoExercicio? ultimaExecucao;
  final double cargaSugerida;
  final int repeticoesMin;
  final int repeticoesMax;
  final TipoProgressao tipo;
  final String motivo;

  const ProgressaoSugestao({
    required this.ultimaExecucao,
    required this.cargaSugerida,
    required this.repeticoesMin,
    required this.repeticoesMax,
    required this.tipo,
    required this.motivo,
  });

  bool get temHistorico => ultimaExecucao != null;
}

class SerieCargaExercicio {
  final String id;
  final String nomeExercicio;
  final double peso;
  final int series;
  final int repeticoes;
  final DateTime data;

  const SerieCargaExercicio({
    required this.id,
    required this.nomeExercicio,
    required this.peso,
    required this.series,
    required this.repeticoes,
    required this.data,
  });

  double get volume => peso * repeticoes * series;

  String get cargaFormatada {
    if (peso <= 0) return "Peso livre";
    return "${_formatarNumero(peso)} kg";
  }

  String get resumoSeries {
    final serieTexto = series <= 1 ? "1 serie" : "$series series";
    return "$serieTexto x $repeticoes reps";
  }

  static String _formatarNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toStringAsFixed(1).replaceAll(".", ",");
  }
}

class ResumoCargaExercicio {
  final String nomeExercicio;
  final List<SerieCargaExercicio> execucoes;

  const ResumoCargaExercicio({
    required this.nomeExercicio,
    required this.execucoes,
  });

  bool get temHistorico => execucoes.isNotEmpty;

  SerieCargaExercicio? get ultimaExecucao {
    if (execucoes.isEmpty) return null;
    return execucoes.first;
  }

  SerieCargaExercicio? get melhorCarga {
    if (execucoes.isEmpty) return null;

    final ordenadas = [...execucoes]
      ..sort((a, b) {
        final pesoCompare = b.peso.compareTo(a.peso);
        if (pesoCompare != 0) return pesoCompare;
        final repsCompare = b.repeticoes.compareTo(a.repeticoes);
        if (repsCompare != 0) return repsCompare;
        return b.volume.compareTo(a.volume);
      });

    return ordenadas.first;
  }

  SerieCargaExercicio? get melhorVolume {
    if (execucoes.isEmpty) return null;

    final ordenadas = [...execucoes]
      ..sort((a, b) {
        final volumeCompare = b.volume.compareTo(a.volume);
        if (volumeCompare != 0) return volumeCompare;
        return b.peso.compareTo(a.peso);
      });

    return ordenadas.first;
  }

  List<SerieCargaExercicio> get recentes {
    return execucoes.take(6).toList();
  }

  double get evolucaoCargaPercentual {
    return _evolucaoPercentual((item) => item.peso);
  }

  double get evolucaoVolumePercentual {
    return _evolucaoPercentual((item) => item.volume);
  }

  double get melhorCargaPercentual {
    final melhor = melhorCarga?.peso ?? 0;
    if (melhor <= 0) return 0;
    final ultima = ultimaExecucao?.peso ?? 0;
    return (ultima / melhor).clamp(0.0, 1.0).toDouble();
  }

  double get melhorVolumePercentual {
    final melhor = melhorVolume?.volume ?? 0;
    if (melhor <= 0) return 0;
    final ultima = ultimaExecucao?.volume ?? 0;
    return (ultima / melhor).clamp(0.0, 1.0).toDouble();
  }

  double _evolucaoPercentual(double Function(SerieCargaExercicio item) valor) {
    if (execucoes.length < 2) return 0;

    final ordenadas = [...execucoes]..sort((a, b) => a.data.compareTo(b.data));
    final primeiro = valor(ordenadas.first);
    final ultimo = valor(ordenadas.last);

    if (primeiro <= 0 && ultimo <= 0) return 0;
    if (primeiro <= 0) return 100;

    return ((ultimo - primeiro) / primeiro) * 100;
  }
}

class ProgressaoInteligenteResumo {
  final ResumoCargaExercicio resumoCarga;
  final ProgressaoSugestao sugestao;
  final double cargaMedia;
  final double volumeMedio;
  final IndicadorProgressao indicador;
  final String recomendacao;

  const ProgressaoInteligenteResumo({
    required this.resumoCarga,
    required this.sugestao,
    required this.cargaMedia,
    required this.volumeMedio,
    required this.indicador,
    required this.recomendacao,
  });

  bool get temHistorico => resumoCarga.temHistorico;

  bool get temSugestao => sugestao.cargaSugerida > 0;

  SerieCargaExercicio? get ultimaExecucao => resumoCarga.ultimaExecucao;

  SerieCargaExercicio? get melhorExecucao {
    final melhorVolume = resumoCarga.melhorVolume;
    final melhorCarga = resumoCarga.melhorCarga;

    if (melhorVolume == null) return melhorCarga;
    if (melhorCarga == null) return melhorVolume;

    return melhorVolume.volume >= melhorCarga.volume
        ? melhorVolume
        : melhorCarga;
  }

  List<SerieCargaExercicio> get ultimasCinco {
    return resumoCarga.execucoes.take(5).toList(growable: false);
  }

  String get indicadorSimbolo {
    switch (indicador) {
      case IndicadorProgressao.evolucao:
        return "↑";
      case IndicadorProgressao.queda:
        return "↓";
      case IndicadorProgressao.estavel:
        return "→";
    }
  }

  String get indicadorTexto {
    switch (indicador) {
      case IndicadorProgressao.evolucao:
        return "evolucao";
      case IndicadorProgressao.queda:
        return "queda";
      case IndicadorProgressao.estavel:
        return "estavel";
    }
  }

  String get cargaSugeridaInput {
    if (!temSugestao) return "";
    return _formatarNumero(sugestao.cargaSugerida);
  }

  String get cargaSugeridaTexto {
    if (!temSugestao) return "Sem carga sugerida";
    return "${_formatarNumero(sugestao.cargaSugerida)} kg";
  }

  String get repsSugeridasTexto {
    return "${sugestao.repeticoesMin}-${sugestao.repeticoesMax} reps";
  }

  String get ultimaExecucaoTexto {
    final ultima = ultimaExecucao;
    if (ultima == null) return "Sem historico";
    return "${ultima.cargaFormatada} • ${ultima.repeticoes} reps";
  }

  String get melhorExecucaoTexto {
    final melhor = melhorExecucao;
    if (melhor == null) return "Sem historico";
    return "${melhor.cargaFormatada} • ${_formatarPeso(melhor.volume)}";
  }

  String get cargaMediaTexto {
    if (!temHistorico) return "-";
    return "${_formatarNumero(cargaMedia)} kg";
  }

  String get volumeMedioTexto {
    if (!temHistorico) return "-";
    return _formatarPeso(volumeMedio);
  }

  static String _formatarPeso(double valor) {
    if (valor <= 0) return "0 kg";
    if (valor >= 1000) return "${_formatarNumero(valor / 1000)} t";
    return "${_formatarNumero(valor)} kg";
  }

  static String _formatarNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toStringAsFixed(1).replaceAll(".", ",");
  }
}

class ProgressaoService {
  const ProgressaoService();

  Future<ProgressaoInteligenteResumo> carregarProgressaoInteligente({
    required ExercicioModel exercicio,
    int metaRepeticoes = 10,
  }) async {
    final resumo = await carregarResumoCarga(exercicio: exercicio);
    final sugestao = await calcularSugestao(
      exercicio: exercicio,
      metaRepeticoes: metaRepeticoes,
    );
    final indicador = _calcularIndicador(resumo.execucoes);

    return ProgressaoInteligenteResumo(
      resumoCarga: resumo,
      sugestao: sugestao,
      cargaMedia: _media(resumo.execucoes.map((item) => item.peso)),
      volumeMedio: _media(resumo.execucoes.map((item) => item.volume)),
      indicador: indicador,
      recomendacao: _recomendacao(sugestao),
    );
  }

  Future<ResumoCargaExercicio> carregarResumoCarga({
    required ExercicioModel exercicio,
    int limite = 30,
  }) async {
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final progressos = await StorageService.carregarHistoricoExercicio(
      exercicio.nome,
    );
    final registros = <SerieCargaExercicio>[];

    for (final serie in historicoSeries) {
      if (!_seriePertenceAoExercicio(serie, exercicio)) continue;

      registros.add(
        SerieCargaExercicio(
          id: serie.id,
          nomeExercicio: serie.nomeExercicio,
          peso: serie.peso,
          series: 1,
          repeticoes: serie.repeticoes,
          data: serie.dataHora,
        ),
      );
    }

    for (final progresso in progressos) {
      registros.add(_registroDeProgresso(progresso));
    }

    final unicos = _removerDuplicados(registros)
      ..sort((a, b) => b.data.compareTo(a.data));

    return ResumoCargaExercicio(
      nomeExercicio: exercicio.nome,
      execucoes: unicos.take(limite).toList(),
    );
  }

  Future<ProgressaoSugestao> calcularSugestao({
    required ExercicioModel exercicio,
    int metaRepeticoes = 10,
  }) async {
    final historico = await StorageService.carregarHistoricoSeriesTreino();
    final seriesExercicio = historico.where((serie) {
      if (exercicio.id.trim().isNotEmpty &&
          serie.exercicioId.trim() == exercicio.id.trim()) {
        return true;
      }

      return _normalizar(serie.nomeExercicio) == _normalizar(exercicio.nome);
    }).toList();

    if (seriesExercicio.isEmpty) {
      return _semHistorico(metaRepeticoes);
    }

    final ultimaSessao = _ultimaSessao(seriesExercicio);
    if (ultimaSessao.isEmpty) return _semHistorico(metaRepeticoes);

    final ultimaExecucao = _resumirUltimaExecucao(ultimaSessao);
    final meta = _metaSegura(metaRepeticoes);
    final repsMin = (meta - 2).clamp(1, meta).toInt();

    final menorReps = ultimaExecucao.menorRepeticoes;
    final mediaReps =
        ultimaSessao.fold<int>(0, (total, serie) => total + serie.repeticoes) /
        ultimaSessao.length;

    if (menorReps >= meta) {
      final percentual = mediaReps >= meta + 2 ? 0.05 : 0.025;
      return ProgressaoSugestao(
        ultimaExecucao: ultimaExecucao,
        cargaSugerida: _arredondarCarga(ultimaExecucao.peso * (1 + percentual)),
        repeticoesMin: repsMin,
        repeticoesMax: meta,
        tipo: TipoProgressao.progressao,
        motivo: "Todas as series bateram a meta.",
      );
    }

    if (menorReps < (meta * 0.7).round()) {
      final percentual = menorReps <= (meta * 0.5).round() ? 0.05 : 0.025;
      return ProgressaoSugestao(
        ultimaExecucao: ultimaExecucao,
        cargaSugerida: _arredondarCarga(ultimaExecucao.peso * (1 - percentual)),
        repeticoesMin: repsMin,
        repeticoesMax: meta,
        tipo: TipoProgressao.deload,
        motivo: "A execucao anterior ficou bem abaixo da meta.",
      );
    }

    return ProgressaoSugestao(
      ultimaExecucao: ultimaExecucao,
      cargaSugerida: _arredondarCarga(ultimaExecucao.peso),
      repeticoesMin: repsMin,
      repeticoesMax: meta,
      tipo: TipoProgressao.manutencao,
      motivo: "Mantenha a carga e consolide a faixa de repeticoes.",
    );
  }

  ProgressaoSugestao _semHistorico(int metaRepeticoes) {
    final meta = _metaSegura(metaRepeticoes);

    return ProgressaoSugestao(
      ultimaExecucao: null,
      cargaSugerida: 0,
      repeticoesMin: (meta - 2).clamp(1, meta).toInt(),
      repeticoesMax: meta,
      tipo: TipoProgressao.inicial,
      motivo: "Primeira referencia deste exercicio.",
    );
  }

  List<HistoricoSerieTreinoModel> _ultimaSessao(
    List<HistoricoSerieTreinoModel> series,
  ) {
    final ordenadas = [...series]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final ultima = ordenadas.first;

    if (ultima.sessaoTreinoId.trim().isNotEmpty) {
      return ordenadas
          .where((serie) => serie.sessaoTreinoId == ultima.sessaoTreinoId)
          .toList()
        ..sort((a, b) => a.serieNumero.compareTo(b.serieNumero));
    }

    final inicioJanela = ultima.dataHora.subtract(const Duration(minutes: 30));
    final fimJanela = ultima.dataHora.add(const Duration(minutes: 2));

    return ordenadas.where((serie) {
      return !serie.dataHora.isBefore(inicioJanela) &&
          !serie.dataHora.isAfter(fimJanela);
    }).toList()..sort((a, b) => a.serieNumero.compareTo(b.serieNumero));
  }

  UltimaExecucaoExercicio _resumirUltimaExecucao(
    List<HistoricoSerieTreinoModel> series,
  ) {
    final referencia = [...series]
      ..sort((a, b) {
        final pesoCompare = b.peso.compareTo(a.peso);
        if (pesoCompare != 0) return pesoCompare;
        return b.repeticoes.compareTo(a.repeticoes);
      });
    final reps = series.map((serie) => serie.repeticoes).toList();
    reps.sort();

    return UltimaExecucaoExercicio(
      peso: referencia.first.peso,
      repeticoes: referencia.first.repeticoes,
      series: series.length,
      menorRepeticoes: reps.first,
      maiorRepeticoes: reps.last,
      dataHora: series
          .map((serie) => serie.dataHora)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  int _metaSegura(int metaRepeticoes) {
    if (metaRepeticoes <= 0) return 10;
    if (metaRepeticoes > 999) return 999;
    return metaRepeticoes;
  }

  double _arredondarCarga(double valor) {
    if (valor <= 0) return 0;
    return (valor * 2).round() / 2;
  }

  bool _seriePertenceAoExercicio(
    HistoricoSerieTreinoModel serie,
    ExercicioModel exercicio,
  ) {
    if (exercicio.id.trim().isNotEmpty &&
        serie.exercicioId.trim() == exercicio.id.trim()) {
      return true;
    }

    return _normalizar(serie.nomeExercicio) == _normalizar(exercicio.nome);
  }

  SerieCargaExercicio _registroDeProgresso(ProgressoExercicioModel progresso) {
    return SerieCargaExercicio(
      id: progresso.id,
      nomeExercicio: progresso.nomeExercicio,
      peso: progresso.peso,
      series: progresso.series <= 0 ? 1 : progresso.series,
      repeticoes: progresso.repeticoes,
      data: progresso.data,
    );
  }

  List<SerieCargaExercicio> _removerDuplicados(
    List<SerieCargaExercicio> registros,
  ) {
    final chaves = <String>{};
    final unicos = <SerieCargaExercicio>[];

    for (final registro in registros) {
      final chave = [
        _normalizar(registro.nomeExercicio),
        registro.data.toIso8601String(),
        registro.peso.toStringAsFixed(2),
        registro.series,
        registro.repeticoes,
      ].join("|");

      if (chaves.add(chave)) {
        unicos.add(registro);
      }
    }

    return unicos;
  }

  IndicadorProgressao _calcularIndicador(List<SerieCargaExercicio> execucoes) {
    if (execucoes.length < 2) return IndicadorProgressao.estavel;

    final recentes = execucoes.take(5).toList();
    final atual = recentes.first.volume > 0
        ? recentes.first.volume
        : recentes.first.peso;
    final anterior = recentes.last.volume > 0
        ? recentes.last.volume
        : recentes.last.peso;

    if (anterior <= 0) return IndicadorProgressao.estavel;

    final variacao = ((atual - anterior) / anterior) * 100;
    if (variacao > 2) return IndicadorProgressao.evolucao;
    if (variacao < -2) return IndicadorProgressao.queda;
    return IndicadorProgressao.estavel;
  }

  double _media(Iterable<double> valores) {
    final lista = valores.where((valor) => valor > 0).toList();
    if (lista.isEmpty) return 0;

    return lista.reduce((a, b) => a + b) / lista.length;
  }

  String _recomendacao(ProgressaoSugestao sugestao) {
    if (!sugestao.temHistorico) {
      return "Registre a primeira execucao para liberar recomendacoes precisas.";
    }

    final carga = SerieCargaExercicio._formatarNumero(sugestao.cargaSugerida);
    final faixa = "${sugestao.repeticoesMin}-${sugestao.repeticoesMax}";

    switch (sugestao.tipo) {
      case TipoProgressao.progressao:
        return "Aumente aproximadamente 2,5-5%. Tente ${carga}kg para $faixa repeticoes.";
      case TipoProgressao.deload:
        return "Reduza aproximadamente 5% e priorize tecnica. Tente ${carga}kg para $faixa repeticoes.";
      case TipoProgressao.manutencao:
        return "Repita a carga atual e consolide a execucao em $faixa repeticoes.";
      case TipoProgressao.inicial:
        return "Escolha uma carga confortavel e registre suas series.";
    }
  }

  String _normalizar(String texto) {
    var valor = texto.toLowerCase().trim();
    final substituicoes = {
      "á": "a",
      "à": "a",
      "â": "a",
      "ã": "a",
      "ä": "a",
      "é": "e",
      "ê": "e",
      "è": "e",
      "ë": "e",
      "í": "i",
      "ì": "i",
      "î": "i",
      "ï": "i",
      "ó": "o",
      "ò": "o",
      "ô": "o",
      "õ": "o",
      "ö": "o",
      "ú": "u",
      "ù": "u",
      "û": "u",
      "ü": "u",
      "ç": "c",
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }
}
