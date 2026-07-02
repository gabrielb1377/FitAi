class ProgressoExercicioModel {
  final String id;
  final String nomeExercicio;
  final double peso;
  final int series;
  final int repeticoes;
  final int? tempoDescanso;
  final double? rpe;
  final String observacao;
  final DateTime data;

  const ProgressoExercicioModel({
    required this.id,
    required this.nomeExercicio,
    required this.peso,
    required this.series,
    required this.repeticoes,
    this.tempoDescanso,
    this.rpe,
    required this.observacao,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nomeExercicio": nomeExercicio,
      "peso": peso,
      "series": series,
      "repeticoes": repeticoes,
      "tempoDescanso": tempoDescanso,
      "rpe": rpe,
      "observacao": observacao,
      "data": data.toIso8601String(),
    };
  }

  factory ProgressoExercicioModel.fromJson(Map<String, dynamic> json) {
    return ProgressoExercicioModel(
      id: json["id"]?.toString() ?? "",
      nomeExercicio: json["nomeExercicio"]?.toString() ?? "Exercicio",
      peso: _doubleFromJson(json["peso"]),
      series: _intFromJson(json["series"]),
      repeticoes: _intFromJson(json["repeticoes"]),
      tempoDescanso: json["tempoDescanso"] == null
          ? null
          : _intFromJson(json["tempoDescanso"]),
      rpe: json["rpe"] == null ? null : _doubleFromJson(json["rpe"]),
      observacao: json["observacao"]?.toString() ?? "",
      data:
          DateTime.tryParse(json["data"]?.toString() ?? "") ??
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
