import '../models/exercicio_model.dart';
import '../models/historico_serie_treino_model.dart';
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
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }
}
