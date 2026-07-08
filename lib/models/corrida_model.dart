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
    return {'distancia': distancia, 'segundos': segundos, 'data': data};
  }

  factory CorridaModel.fromJson(Map<String, dynamic> json) {
    return CorridaModel(
      distancia: _doubleFromJson(json['distancia']),
      segundos: _intFromJson(json['segundos']),
      data: json['data']?.toString() ?? '',
    );
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}
