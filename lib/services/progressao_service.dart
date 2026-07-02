import '../models/exercicio_model.dart';
import '../models/historico_serie_treino_model.dart';
import 'storage_service.dart';

enum TipoProgressao { inicial, progressao, manutencao, deload }

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

class ProgressaoService {
  const ProgressaoService();

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
