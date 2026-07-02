class PassosDiariosModel {
  final String data;
  final int passos;
  final int metaDiaria;
  final double distanciaKm;
  final double calorias;
  final int tempoAtivoMinutos;
  final String origem;

  const PassosDiariosModel({
    required this.data,
    required this.passos,
    required this.metaDiaria,
    required this.distanciaKm,
    required this.calorias,
    required this.tempoAtivoMinutos,
    this.origem = 'estimado',
  });

  bool get metaAtingida => passos >= metaDiaria;

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'passos': passos,
      'metaDiaria': metaDiaria,
      'distanciaKm': distanciaKm,
      'calorias': calorias,
      'tempoAtivoMinutos': tempoAtivoMinutos,
      'origem': origem,
    };
  }

  factory PassosDiariosModel.fromJson(Map<String, dynamic> json) {
    return PassosDiariosModel(
      data: json['data']?.toString() ?? '',
      passos: (json['passos'] as num?)?.toInt() ?? 0,
      metaDiaria: (json['metaDiaria'] as num?)?.toInt() ?? 10000,
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble() ?? 0,
      calorias: (json['calorias'] as num?)?.toDouble() ?? 0,
      tempoAtivoMinutos: (json['tempoAtivoMinutos'] as num?)?.toInt() ?? 0,
      origem: json['origem']?.toString() ?? 'estimado',
    );
  }
}
