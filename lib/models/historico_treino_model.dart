class HistoricoTreinoModel {
  final String id;
  final String nomeTreino;
  final DateTime dataHora;
  final int tempoSegundos;
  final String tempoFormatado;
  final int exerciciosTotais;
  final int exerciciosConcluidos;
  final int xpGanho;
  final int caloriasEstimadas;
  final String objetivo;
  final String nivel;
  final int seriesConcluidas;
  final double volumeTotal;
  final int recordesBatidos;

  const HistoricoTreinoModel({
    required this.id,
    required this.nomeTreino,
    required this.dataHora,
    required this.tempoSegundos,
    required this.tempoFormatado,
    required this.exerciciosTotais,
    required this.exerciciosConcluidos,
    required this.xpGanho,
    required this.caloriasEstimadas,
    required this.objetivo,
    required this.nivel,
    this.seriesConcluidas = 0,
    this.volumeTotal = 0,
    this.recordesBatidos = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nomeTreino": nomeTreino,
      "dataHora": dataHora.toIso8601String(),
      "tempoSegundos": tempoSegundos,
      "tempoFormatado": tempoFormatado,
      "exerciciosTotais": exerciciosTotais,
      "exerciciosConcluidos": exerciciosConcluidos,
      "xpGanho": xpGanho,
      "caloriasEstimadas": caloriasEstimadas,
      "objetivo": objetivo,
      "nivel": nivel,
      "seriesConcluidas": seriesConcluidas,
      "volumeTotal": volumeTotal,
      "recordesBatidos": recordesBatidos,
    };
  }

  factory HistoricoTreinoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoTreinoModel(
      id: json["id"]?.toString() ?? "",
      nomeTreino: json["nomeTreino"]?.toString() ?? "Treino",
      dataHora:
          DateTime.tryParse(json["dataHora"]?.toString() ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
      tempoSegundos: _intFromJson(json["tempoSegundos"]),
      tempoFormatado: json["tempoFormatado"]?.toString() ?? "00:00",
      exerciciosTotais: _intFromJson(json["exerciciosTotais"]),
      exerciciosConcluidos: _intFromJson(json["exerciciosConcluidos"]),
      xpGanho: _intFromJson(json["xpGanho"]),
      caloriasEstimadas: _intFromJson(json["caloriasEstimadas"]),
      objetivo: json["objetivo"]?.toString() ?? "Geral",
      nivel: json["nivel"]?.toString() ?? "Iniciante",
      seriesConcluidas: _intFromJson(json["seriesConcluidas"]),
      volumeTotal: _doubleFromJson(json["volumeTotal"]),
      recordesBatidos: _intFromJson(json["recordesBatidos"]),
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
