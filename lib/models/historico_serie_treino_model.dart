import '../core/exercises/exercise_identity.dart';

class HistoricoSerieTreinoModel {
  final String id;
  final String treinoId;
  final String sessaoTreinoId;
  final String nomeTreino;
  final String exercicioId;
  final String exerciseKey;
  final String nomeExercicio;
  final int serieNumero;
  final double peso;
  final int repeticoes;
  final int series;
  final int descansoSegundos;
  final String? rir;
  final String comentario;
  final bool concluida;
  final DateTime dataHora;

  const HistoricoSerieTreinoModel({
    required this.id,
    required this.treinoId,
    this.sessaoTreinoId = "",
    required this.nomeTreino,
    required this.exercicioId,
    this.exerciseKey = '',
    required this.nomeExercicio,
    required this.serieNumero,
    required this.peso,
    required this.repeticoes,
    this.series = 1,
    this.descansoSegundos = 0,
    this.rir,
    this.comentario = "",
    this.concluida = true,
    required this.dataHora,
  });

  double get volume => peso * repeticoes * (series <= 0 ? 1 : series);

  String get chaveExercicio => ExerciseIdentity.buildExerciseKey(
    exerciseId: exercicioId,
    exerciseKey: exerciseKey,
    exerciseName: nomeExercicio,
  );

  String get deduplicationKey => [
    sessaoTreinoId.trim(),
    chaveExercicio,
    dataHora.toIso8601String(),
    serieNumero,
  ].join('|');

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "treinoId": treinoId,
      "sessaoTreinoId": sessaoTreinoId,
      "nomeTreino": nomeTreino,
      "exercicioId": exercicioId,
      "exerciseKey": chaveExercicio,
      "nomeExercicio": nomeExercicio,
      "serieNumero": serieNumero,
      "peso": peso,
      "repeticoes": repeticoes,
      "series": series,
      "descansoSegundos": descansoSegundos,
      "rir": rir,
      "comentario": comentario,
      "concluida": concluida,
      "volume": volume,
      "dataHora": dataHora.toIso8601String(),
    };
  }

  factory HistoricoSerieTreinoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoSerieTreinoModel(
      id: json["id"]?.toString() ?? "",
      treinoId: json["treinoId"]?.toString() ?? "",
      sessaoTreinoId: json["sessaoTreinoId"]?.toString() ?? "",
      nomeTreino: json["nomeTreino"]?.toString() ?? "Treino",
      exercicioId: json["exercicioId"]?.toString() ?? "",
      exerciseKey: json["exerciseKey"]?.toString() ?? "",
      nomeExercicio: json["nomeExercicio"]?.toString() ?? "Exercicio",
      serieNumero: _intFromJson(json["serieNumero"]),
      peso: _doubleFromJson(json["peso"]),
      repeticoes: _intFromJson(json["repeticoes"]),
      series: _intFromJson(json["series"]) <= 0
          ? 1
          : _intFromJson(json["series"]),
      descansoSegundos: _intFromJson(json["descansoSegundos"]),
      rir: json["rir"]?.toString(),
      comentario: json["comentario"]?.toString() ?? "",
      concluida: json["concluida"] is bool ? json["concluida"] as bool : true,
      dataHora:
          DateTime.tryParse(json["dataHora"]?.toString() ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static double _doubleFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    final texto = value?.toString().replaceAll(",", ".") ?? "";
    return double.tryParse(texto) ?? 0;
  }
}
