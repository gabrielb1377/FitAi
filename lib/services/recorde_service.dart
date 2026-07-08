import '../models/corrida_model.dart';
import '../models/exercicio_model.dart';
import '../models/fitai_recorde_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import 'storage_service.dart';

enum TipoRecorde { carga, repeticoes, volume }

class RecordesExercicio {
  final double maiorCarga;
  final int maiorRepsComMaiorCarga;
  final double maiorVolume;

  const RecordesExercicio({
    required this.maiorCarga,
    required this.maiorRepsComMaiorCarga,
    required this.maiorVolume,
  });
}

class ResultadoRecorde {
  final List<TipoRecorde> tipos;
  final RecordesExercicio? anteriores;
  final bool primeiroRegistro;

  const ResultadoRecorde({
    required this.tipos,
    required this.anteriores,
    required this.primeiroRegistro,
  });

  bool get bateuRecorde => tipos.isNotEmpty;
}

class RecordeService {
  const RecordeService();

  Future<ResultadoRecorde> detectarRecordes({
    required ExercicioModel exercicio,
    required double peso,
    required int repeticoes,
  }) async {
    final historico = await _historicoExercicio(exercicio);

    if (historico.isEmpty) {
      return const ResultadoRecorde(
        tipos: [],
        anteriores: null,
        primeiroRegistro: true,
      );
    }

    final anteriores = calcularRecordes(historico);
    final tipos = <TipoRecorde>[];
    final volume = peso * repeticoes;

    if (peso > anteriores.maiorCarga && peso > 0) {
      tipos.add(TipoRecorde.carga);
    }

    final historicoMesmaCarga = historico.where((serie) {
      return _mesmaCarga(serie.peso, peso);
    }).toList();

    if (historicoMesmaCarga.isNotEmpty) {
      final maiorRepsMesmaCarga = historicoMesmaCarga
          .map((serie) => serie.repeticoes)
          .reduce((a, b) => a > b ? a : b);

      if (repeticoes > maiorRepsMesmaCarga) {
        tipos.add(TipoRecorde.repeticoes);
      }
    }

    if (volume > anteriores.maiorVolume && volume > 0) {
      tipos.add(TipoRecorde.volume);
    }

    return ResultadoRecorde(
      tipos: tipos,
      anteriores: anteriores,
      primeiroRegistro: false,
    );
  }

  RecordesExercicio calcularRecordes(
    List<HistoricoSerieTreinoModel> historico,
  ) {
    var maiorCarga = 0.0;
    var maiorVolume = 0.0;

    for (final serie in historico) {
      if (serie.peso > maiorCarga) maiorCarga = serie.peso;
      if (serie.volume > maiorVolume) maiorVolume = serie.volume;
    }

    final seriesMaiorCarga = historico.where((serie) {
      return _mesmaCarga(serie.peso, maiorCarga);
    }).toList();
    final maiorRepsComMaiorCarga = seriesMaiorCarga.isEmpty
        ? 0
        : seriesMaiorCarga
              .map((serie) => serie.repeticoes)
              .reduce((a, b) => a > b ? a : b);

    return RecordesExercicio(
      maiorCarga: maiorCarga,
      maiorRepsComMaiorCarga: maiorRepsComMaiorCarga,
      maiorVolume: maiorVolume,
    );
  }

  Future<List<FitaiRecordeModel>> carregarRecordes() async {
    await sincronizarRecordesHistoricos();
    return StorageService.carregarRecordes();
  }

  Future<List<FitaiRecordeModel>> carregarRecordesExercicio(
    ExercicioModel exercicio,
  ) async {
    final recordes = await carregarRecordes();
    final nome = _normalizar(exercicio.nome);
    final id = _normalizar(exercicio.id);

    return recordes.where((recorde) {
      final exercicioRecorde = _normalizar(recorde.exercicioNome ?? '');
      final recordeId = _normalizar(recorde.id);

      return exercicioRecorde == nome ||
          (id.isNotEmpty && exercicioRecorde == id) ||
          recordeId.endsWith('_$nome') ||
          (id.isNotEmpty && recordeId.endsWith('_$id'));
    }).toList();
  }

  Future<List<FitaiRecordeModel>> detectarRecordesTreino({
    required HistoricoTreinoModel historico,
    required List<HistoricoSerieTreinoModel> seriesSessao,
  }) async {
    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final candidatos = <FitaiRecordeModel>[
      ..._candidatosSeries(seriesSessao),
      ..._candidatosTreinos([...historicoTreinos, historico]),
    ];

    return _salvarNovosRecordes(candidatos);
  }

  Future<void> sincronizarRecordesHistoricos() async {
    final series = await StorageService.carregarHistoricoSeriesTreino();
    final treinos = await StorageService.carregarHistoricoTreinos();
    final corridas = await StorageService.carregarCorridas();

    final candidatos = <FitaiRecordeModel>[
      ..._candidatosSeries(series),
      ..._candidatosTreinos(treinos),
      ..._candidatosCorridas(corridas),
    ];

    for (final candidato in candidatos) {
      await StorageService.salvarRecordeSeMaior(candidato);
    }
  }

  Future<List<FitaiRecordeModel>> _salvarNovosRecordes(
    List<FitaiRecordeModel> candidatos,
  ) async {
    final novos = <FitaiRecordeModel>[];

    for (final candidato in candidatos) {
      final salvou = await StorageService.salvarRecordeSeMaior(candidato);
      if (salvou) novos.add(candidato);
    }

    return novos;
  }

  List<FitaiRecordeModel> _candidatosSeries(
    List<HistoricoSerieTreinoModel> series,
  ) {
    final grupos = <String, List<HistoricoSerieTreinoModel>>{};

    for (final serie in series) {
      final keyBase = serie.exercicioId.trim().isNotEmpty
          ? serie.exercicioId
          : serie.nomeExercicio;
      final key = _normalizar(keyBase);

      if (key.isEmpty) continue;
      grupos.putIfAbsent(key, () => <HistoricoSerieTreinoModel>[]).add(serie);
    }

    final candidatos = <FitaiRecordeModel>[];

    for (final entry in grupos.entries) {
      final key = entry.key;
      final grupo = entry.value;
      if (grupo.isEmpty) continue;

      final melhorCarga = _melhorSerie(
        grupo,
        (a, b) => a.peso == b.peso
            ? a.repeticoes.compareTo(b.repeticoes)
            : a.peso.compareTo(b.peso),
      );
      final melhorReps = _melhorSerie(
        grupo,
        (a, b) => a.repeticoes == b.repeticoes
            ? a.peso.compareTo(b.peso)
            : a.repeticoes.compareTo(b.repeticoes),
      );
      final melhorVolume = _melhorSerie(
        grupo,
        (a, b) => a.volume.compareTo(b.volume),
      );

      if (melhorCarga.peso > 0) {
        candidatos.add(
          FitaiRecordeModel(
            id: 'exercicio_carga_$key',
            titulo: 'Maior carga',
            descricao:
                'Maior carga registrada em ${melhorCarga.nomeExercicio}.',
            categoria: FitaiRecordeCategoria.treinos,
            valor: melhorCarga.peso,
            unidade: 'kg',
            data: melhorCarga.dataHora,
            exercicioNome: melhorCarga.nomeExercicio,
            treinoNome: melhorCarga.nomeTreino,
          ),
        );
      }

      if (melhorReps.repeticoes > 0) {
        candidatos.add(
          FitaiRecordeModel(
            id: 'exercicio_reps_$key',
            titulo: 'Maior numero de repeticoes',
            descricao:
                'Maior numero de repeticoes em ${melhorReps.nomeExercicio}.',
            categoria: FitaiRecordeCategoria.treinos,
            valor: melhorReps.repeticoes.toDouble(),
            unidade: 'reps',
            data: melhorReps.dataHora,
            exercicioNome: melhorReps.nomeExercicio,
            treinoNome: melhorReps.nomeTreino,
          ),
        );
      }

      if (melhorVolume.volume > 0) {
        candidatos.add(
          FitaiRecordeModel(
            id: 'exercicio_volume_$key',
            titulo: 'Maior volume por exercicio',
            descricao:
                'Maior volume em uma serie de ${melhorVolume.nomeExercicio}.',
            categoria: FitaiRecordeCategoria.volume,
            valor: melhorVolume.volume,
            unidade: 'kg',
            data: melhorVolume.dataHora,
            exercicioNome: melhorVolume.nomeExercicio,
            treinoNome: melhorVolume.nomeTreino,
          ),
        );
      }
    }

    return candidatos;
  }

  List<FitaiRecordeModel> _candidatosTreinos(
    List<HistoricoTreinoModel> treinos,
  ) {
    final candidatos = <FitaiRecordeModel>[];
    final treinosComVolume = treinos.where((treino) => treino.volumeTotal > 0);
    final treinosComTempo = treinos.where((treino) => treino.tempoSegundos > 0);

    if (treinosComVolume.isNotEmpty) {
      final melhorVolume = treinosComVolume.reduce(
        (a, b) => a.volumeTotal >= b.volumeTotal ? a : b,
      );

      candidatos.add(
        FitaiRecordeModel(
          id: 'treino_volume_total',
          titulo: 'Maior volume em um treino',
          descricao: 'Maior volume total movimentado em uma sessao.',
          categoria: FitaiRecordeCategoria.volume,
          valor: melhorVolume.volumeTotal,
          unidade: 'kg',
          data: melhorVolume.dataHora,
          treinoNome: melhorVolume.nomeTreino,
        ),
      );
    }

    if (treinosComTempo.isNotEmpty) {
      final maiorTempo = treinosComTempo.reduce(
        (a, b) => a.tempoSegundos >= b.tempoSegundos ? a : b,
      );

      candidatos.add(
        FitaiRecordeModel(
          id: 'treino_tempo_total',
          titulo: 'Maior tempo treinando',
          descricao: 'Seu treino com maior duracao registrada.',
          categoria: FitaiRecordeCategoria.treinos,
          valor: maiorTempo.tempoSegundos / 60,
          unidade: 'min',
          data: maiorTempo.dataHora,
          treinoNome: maiorTempo.nomeTreino,
        ),
      );
    }

    final sequencia = _maiorSequencia(treinos);
    if (sequencia.dias > 0 && sequencia.data != null) {
      candidatos.add(
        FitaiRecordeModel(
          id: 'treino_maior_sequencia',
          titulo: 'Maior sequencia de treinos',
          descricao: 'Sua maior sequencia de dias com treino concluido.',
          categoria: FitaiRecordeCategoria.sequencia,
          valor: sequencia.dias.toDouble(),
          unidade: 'dias',
          data: sequencia.data!,
        ),
      );
    }

    return candidatos;
  }

  List<FitaiRecordeModel> _candidatosCorridas(List<CorridaModel> corridas) {
    final candidatos = <FitaiRecordeModel>[];
    final corridasComDistancia = corridas.where(
      (corrida) => corrida.distancia > 0,
    );
    final corridasComTempo = corridas.where((corrida) => corrida.segundos > 0);
    final corridasComVelocidade = corridas.where((corrida) {
      return corrida.distancia > 0 && corrida.segundos > 0;
    });

    if (corridasComDistancia.isNotEmpty) {
      final maiorDistancia = corridasComDistancia.reduce(
        (a, b) => a.distancia >= b.distancia ? a : b,
      );

      candidatos.add(
        FitaiRecordeModel(
          id: 'corrida_distancia',
          titulo: 'Maior distancia corrida',
          descricao: 'Sua maior distancia registrada em uma corrida.',
          categoria: FitaiRecordeCategoria.corridas,
          valor: maiorDistancia.distancia,
          unidade: 'km',
          data: _dataCorrida(maiorDistancia),
        ),
      );
    }

    if (corridasComTempo.isNotEmpty) {
      final maiorTempo = corridasComTempo.reduce(
        (a, b) => a.segundos >= b.segundos ? a : b,
      );

      candidatos.add(
        FitaiRecordeModel(
          id: 'corrida_tempo',
          titulo: 'Maior tempo correndo',
          descricao: 'Seu maior tempo continuo em uma corrida.',
          categoria: FitaiRecordeCategoria.corridas,
          valor: maiorTempo.segundos / 60,
          unidade: 'min',
          data: _dataCorrida(maiorTempo),
        ),
      );
    }

    if (corridasComVelocidade.isNotEmpty) {
      final melhorVelocidade = corridasComVelocidade.reduce((a, b) {
        return _velocidadeCorrida(a) >= _velocidadeCorrida(b) ? a : b;
      });

      candidatos.add(
        FitaiRecordeModel(
          id: 'corrida_velocidade',
          titulo: 'Melhor velocidade media',
          descricao: 'Sua melhor velocidade media registrada.',
          categoria: FitaiRecordeCategoria.corridas,
          valor: _velocidadeCorrida(melhorVelocidade),
          unidade: 'km/h',
          data: _dataCorrida(melhorVelocidade),
        ),
      );
    }

    return candidatos;
  }

  HistoricoSerieTreinoModel _melhorSerie(
    List<HistoricoSerieTreinoModel> series,
    int Function(HistoricoSerieTreinoModel a, HistoricoSerieTreinoModel b)
    comparar,
  ) {
    return series.reduce((a, b) => comparar(a, b) >= 0 ? a : b);
  }

  _SequenciaResumo _maiorSequencia(List<HistoricoTreinoModel> treinos) {
    if (treinos.isEmpty) return const _SequenciaResumo(0, null);

    final datas =
        treinos
            .map((treino) {
              final data = treino.dataHora;
              return DateTime(data.year, data.month, data.day);
            })
            .toSet()
            .toList()
          ..sort();

    var atual = 0;
    var maior = 0;
    DateTime? anterior;
    DateTime? dataMaior;

    for (final data in datas) {
      if (anterior == null || data.difference(anterior).inDays == 1) {
        atual++;
      } else {
        atual = 1;
      }

      if (atual > maior) {
        maior = atual;
        dataMaior = data;
      }

      anterior = data;
    }

    return _SequenciaResumo(maior, dataMaior);
  }

  double _velocidadeCorrida(CorridaModel corrida) {
    if (corrida.segundos <= 0) return 0;
    return corrida.distancia / (corrida.segundos / 3600);
  }

  DateTime _dataCorrida(CorridaModel corrida) {
    return DateTime.tryParse(corrida.data) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<List<HistoricoSerieTreinoModel>> _historicoExercicio(
    ExercicioModel exercicio,
  ) async {
    final historico = await StorageService.carregarHistoricoSeriesTreino();

    return historico.where((serie) {
      if (exercicio.id.trim().isNotEmpty &&
          serie.exercicioId.trim() == exercicio.id.trim()) {
        return true;
      }

      return _normalizar(serie.nomeExercicio) == _normalizar(exercicio.nome);
    }).toList();
  }

  bool _mesmaCarga(double a, double b) {
    return (a - b).abs() < 0.01;
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
      "Ã¡": "a",
      "Ã ": "a",
      "Ã¢": "a",
      "Ã£": "a",
      "Ã¤": "a",
      "Ã©": "e",
      "Ãª": "e",
      "Ã¨": "e",
      "Ã«": "e",
      "Ã­": "i",
      "Ã¬": "i",
      "Ã®": "i",
      "Ã¯": "i",
      "Ã³": "o",
      "Ã²": "o",
      "Ã´": "o",
      "Ãµ": "o",
      "Ã¶": "o",
      "Ãº": "u",
      "Ã¹": "u",
      "Ã»": "u",
      "Ã¼": "u",
      "Ã§": "c",
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}

class _SequenciaResumo {
  final int dias;
  final DateTime? data;

  const _SequenciaResumo(this.dias, this.data);
}
