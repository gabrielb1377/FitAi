class FitAIMemoryModel {
  final String nome;
  final int idade;
  final double peso;
  final double altura;
  final String objetivo;
  final String nivelExperiencia;
  final String localTreino;
  final List<String> equipamentos;
  final List<String> lesoes;
  final List<String> exerciciosFavoritos;
  final List<String> exerciciosEvitados;
  final List<String> diasDisponiveis;
  final int tempoMedioTreino;
  final String horarioPreferido;
  final String observacoes;

  const FitAIMemoryModel({
    this.nome = '',
    this.idade = 0,
    this.peso = 0,
    this.altura = 0,
    this.objetivo = '',
    this.nivelExperiencia = '',
    this.localTreino = '',
    this.equipamentos = const [],
    this.lesoes = const [],
    this.exerciciosFavoritos = const [],
    this.exerciciosEvitados = const [],
    this.diasDisponiveis = const [],
    this.tempoMedioTreino = 0,
    this.horarioPreferido = '',
    this.observacoes = '',
  });

  bool get estaVazia {
    return nome.trim().isEmpty &&
        idade <= 0 &&
        peso <= 0 &&
        altura <= 0 &&
        objetivo.trim().isEmpty &&
        nivelExperiencia.trim().isEmpty &&
        localTreino.trim().isEmpty &&
        equipamentos.isEmpty &&
        lesoes.isEmpty &&
        exerciciosFavoritos.isEmpty &&
        exerciciosEvitados.isEmpty &&
        diasDisponiveis.isEmpty &&
        tempoMedioTreino <= 0 &&
        horarioPreferido.trim().isEmpty &&
        observacoes.trim().isEmpty;
  }

  FitAIMemoryModel copyWith({
    String? nome,
    int? idade,
    double? peso,
    double? altura,
    String? objetivo,
    String? nivelExperiencia,
    String? localTreino,
    List<String>? equipamentos,
    List<String>? lesoes,
    List<String>? exerciciosFavoritos,
    List<String>? exerciciosEvitados,
    List<String>? diasDisponiveis,
    int? tempoMedioTreino,
    String? horarioPreferido,
    String? observacoes,
  }) {
    return FitAIMemoryModel(
      nome: nome ?? this.nome,
      idade: idade ?? this.idade,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
      objetivo: objetivo ?? this.objetivo,
      nivelExperiencia: nivelExperiencia ?? this.nivelExperiencia,
      localTreino: localTreino ?? this.localTreino,
      equipamentos: equipamentos ?? this.equipamentos,
      lesoes: lesoes ?? this.lesoes,
      exerciciosFavoritos: exerciciosFavoritos ?? this.exerciciosFavoritos,
      exerciciosEvitados: exerciciosEvitados ?? this.exerciciosEvitados,
      diasDisponiveis: diasDisponiveis ?? this.diasDisponiveis,
      tempoMedioTreino: tempoMedioTreino ?? this.tempoMedioTreino,
      horarioPreferido: horarioPreferido ?? this.horarioPreferido,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'idade': idade,
      'peso': peso,
      'altura': altura,
      'objetivo': objetivo,
      'nivelExperiencia': nivelExperiencia,
      'localTreino': localTreino,
      'equipamentos': equipamentos,
      'lesoes': lesoes,
      'exerciciosFavoritos': exerciciosFavoritos,
      'exerciciosEvitados': exerciciosEvitados,
      'diasDisponiveis': diasDisponiveis,
      'tempoMedioTreino': tempoMedioTreino,
      'horarioPreferido': horarioPreferido,
      'observacoes': observacoes,
    };
  }

  factory FitAIMemoryModel.fromJson(Map<String, dynamic> json) {
    return FitAIMemoryModel(
      nome: json['nome']?.toString() ?? '',
      idade: _intFromJson(json['idade']),
      peso: _doubleFromJson(json['peso']),
      altura: _doubleFromJson(json['altura']),
      objetivo: json['objetivo']?.toString() ?? '',
      nivelExperiencia: json['nivelExperiencia']?.toString() ?? '',
      localTreino: json['localTreino']?.toString() ?? '',
      equipamentos: _stringListFromJson(json['equipamentos']),
      lesoes: _stringListFromJson(json['lesoes']),
      exerciciosFavoritos: _stringListFromJson(json['exerciciosFavoritos']),
      exerciciosEvitados: _stringListFromJson(json['exerciciosEvitados']),
      diasDisponiveis: _stringListFromJson(json['diasDisponiveis']),
      tempoMedioTreino: _intFromJson(json['tempoMedioTreino']),
      horarioPreferido: json['horarioPreferido']?.toString() ?? '',
      observacoes: json['observacoes']?.toString() ?? '',
    );
  }

  static List<String> _stringListFromJson(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
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
    final texto = value?.toString().replaceAll(',', '.') ?? '';
    return double.tryParse(texto) ?? 0;
  }
}
