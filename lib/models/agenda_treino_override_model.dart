class AgendaTreinoOverrideModel {
  final String id;
  final String data;
  final String status;
  final String planoId;
  final String planoNome;
  final String diaCodigo;
  final String diaNome;
  final int diaOrdem;
  final String dataOrigem;
  final String dataDestino;
  final DateTime atualizadoEm;

  const AgendaTreinoOverrideModel({
    required this.id,
    required this.data,
    required this.status,
    this.planoId = '',
    this.planoNome = '',
    this.diaCodigo = '',
    this.diaNome = '',
    this.diaOrdem = 0,
    this.dataOrigem = '',
    this.dataDestino = '',
    required this.atualizadoEm,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'status': status,
      'planoId': planoId,
      'planoNome': planoNome,
      'diaCodigo': diaCodigo,
      'diaNome': diaNome,
      'diaOrdem': diaOrdem,
      'dataOrigem': dataOrigem,
      'dataDestino': dataDestino,
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  factory AgendaTreinoOverrideModel.fromJson(Map<String, dynamic> json) {
    return AgendaTreinoOverrideModel(
      id: json['id']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      planoId: json['planoId']?.toString() ?? '',
      planoNome: json['planoNome']?.toString() ?? '',
      diaCodigo: json['diaCodigo']?.toString() ?? '',
      diaNome: json['diaNome']?.toString() ?? '',
      diaOrdem: _intFromJson(json['diaOrdem']),
      dataOrigem: json['dataOrigem']?.toString() ?? '',
      dataDestino: json['dataDestino']?.toString() ?? '',
      atualizadoEm:
          DateTime.tryParse(json['atualizadoEm']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
