class UserContext {
  final String nome;
  final String objetivo;
  final double peso;
  final double altura;
  final int idade;
  final String nivel;
  final List<String> lesoes;
  final List<String> equipamentos;
  final String historicoResumo;
  final String atividadesResumo;

  const UserContext({
    this.nome = '',
    this.objetivo = 'Saude e condicionamento',
    this.peso = 0,
    this.altura = 0,
    this.idade = 0,
    this.nivel = 'Iniciante',
    this.lesoes = const [],
    this.equipamentos = const [],
    this.historicoResumo = '',
    this.atividadesResumo = '',
  });

  bool get temLesoes => lesoes.isNotEmpty;

  bool get temEquipamentos => equipamentos.isNotEmpty;

  UserContext copyWith({
    String? nome,
    String? objetivo,
    double? peso,
    double? altura,
    int? idade,
    String? nivel,
    List<String>? lesoes,
    List<String>? equipamentos,
    String? historicoResumo,
    String? atividadesResumo,
  }) {
    return UserContext(
      nome: nome ?? this.nome,
      objetivo: objetivo ?? this.objetivo,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
      idade: idade ?? this.idade,
      nivel: nivel ?? this.nivel,
      lesoes: lesoes ?? this.lesoes,
      equipamentos: equipamentos ?? this.equipamentos,
      historicoResumo: historicoResumo ?? this.historicoResumo,
      atividadesResumo: atividadesResumo ?? this.atividadesResumo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'objetivo': objetivo,
      'peso': peso,
      'altura': altura,
      'idade': idade,
      'nivel': nivel,
      'lesoes': lesoes,
      'equipamentos': equipamentos,
      'historicoResumo': historicoResumo,
      'atividadesResumo': atividadesResumo,
    };
  }

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      nome: json['nome']?.toString() ?? '',
      objetivo: json['objetivo']?.toString() ?? 'Saude e condicionamento',
      peso: _doubleFromJson(json['peso']),
      altura: _doubleFromJson(json['altura']),
      idade: _intFromJson(json['idade']),
      nivel: json['nivel']?.toString() ?? 'Iniciante',
      lesoes: List<String>.from(json['lesoes'] ?? const []),
      equipamentos: List<String>.from(json['equipamentos'] ?? const []),
      historicoResumo: json['historicoResumo']?.toString() ?? '',
      atividadesResumo: json['atividadesResumo']?.toString() ?? '',
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
    final texto = value?.toString().replaceAll(',', '.') ?? '';
    return double.tryParse(texto) ?? 0;
  }
}
