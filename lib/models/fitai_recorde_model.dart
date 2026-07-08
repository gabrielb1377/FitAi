class FitaiRecordeCategoria {
  static const treinos = 'treinos';
  static const corridas = 'corridas';
  static const sequencia = 'sequencia';
  static const volume = 'volume';

  static const todas = [treinos, corridas, sequencia, volume];

  static String label(String categoria) {
    switch (categoria) {
      case corridas:
        return 'Corridas';
      case sequencia:
        return 'Sequencia';
      case volume:
        return 'Volume';
      case treinos:
      default:
        return 'Treinos';
    }
  }
}

class FitaiRecordeModel {
  final String id;
  final String titulo;
  final String descricao;
  final String categoria;
  final double valor;
  final String unidade;
  final DateTime data;
  final String? exercicioNome;
  final String? treinoNome;

  const FitaiRecordeModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.valor,
    required this.unidade,
    required this.data,
    this.exercicioNome,
    this.treinoNome,
  });

  String get categoriaLabel => FitaiRecordeCategoria.label(categoria);

  String get valorFormatado {
    final valorInteiro = valor % 1 == 0;
    final texto = valorInteiro
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);
    return '$texto $unidade'.trim();
  }

  FitaiRecordeModel copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? categoria,
    double? valor,
    String? unidade,
    DateTime? data,
    String? exercicioNome,
    String? treinoNome,
  }) {
    return FitaiRecordeModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      valor: valor ?? this.valor,
      unidade: unidade ?? this.unidade,
      data: data ?? this.data,
      exercicioNome: exercicioNome ?? this.exercicioNome,
      treinoNome: treinoNome ?? this.treinoNome,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'valor': valor,
      'unidade': unidade,
      'data': data.toIso8601String(),
      'exercicioNome': exercicioNome,
      'treinoNome': treinoNome,
    };
  }

  factory FitaiRecordeModel.fromJson(Map<String, dynamic> json) {
    return FitaiRecordeModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Recorde',
      descricao: json['descricao']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? FitaiRecordeCategoria.treinos,
      valor: _doubleFromJson(json['valor']),
      unidade: json['unidade']?.toString() ?? '',
      data:
          DateTime.tryParse(json['data']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      exercicioNome: _nullableString(json['exercicioNome']),
      treinoNome: _nullableString(json['treinoNome']),
    );
  }

  static String? _nullableString(dynamic value) {
    final texto = value?.toString().trim() ?? '';
    return texto.isEmpty ? null : texto;
  }

  static double _doubleFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}
