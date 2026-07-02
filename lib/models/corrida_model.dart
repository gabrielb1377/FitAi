class CorridaModel {
  final double distancia;
  final int segundos;
  final String data;

  CorridaModel({
    required this.distancia,
    required this.segundos,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'distancia': distancia,
      'segundos': segundos,
      'data': data,
    };
  }

  factory CorridaModel.fromJson(Map<String, dynamic> json) {
    return CorridaModel(
      distancia: json['distancia'],
      segundos: json['segundos'],
      data: json['data'],
    );
  }
}