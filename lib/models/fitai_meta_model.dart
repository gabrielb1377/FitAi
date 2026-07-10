enum FitaiMetaCategoria { treinos, corridas, passos, forca, corpo }

enum FitaiMetaStatus { pendente, emAndamento, concluida, atrasada }

class FitaiMetaModel {
  final String id;
  final String titulo;
  final String descricao;
  final double valorAtual;
  final double valorObjetivo;
  final FitaiMetaCategoria categoria;
  final FitaiMetaStatus status;
  final double progresso;
  final String unidade;
  final String tempoRestante;
  final String estimativa;
  final String coachDica;

  const FitaiMetaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.valorAtual,
    required this.valorObjetivo,
    required this.categoria,
    required this.status,
    required this.progresso,
    required this.unidade,
    required this.tempoRestante,
    required this.estimativa,
    required this.coachDica,
  });

  String get categoriaLabel {
    switch (categoria) {
      case FitaiMetaCategoria.treinos:
        return 'Treinos';
      case FitaiMetaCategoria.corridas:
        return 'Corridas';
      case FitaiMetaCategoria.passos:
        return 'Passos';
      case FitaiMetaCategoria.forca:
        return 'Forca';
      case FitaiMetaCategoria.corpo:
        return 'Corpo';
    }
  }

  String get statusLabel {
    switch (status) {
      case FitaiMetaStatus.pendente:
        return 'Pendente';
      case FitaiMetaStatus.emAndamento:
        return 'Em andamento';
      case FitaiMetaStatus.concluida:
        return 'Concluida';
      case FitaiMetaStatus.atrasada:
        return 'Atrasada';
    }
  }

  String get progressoPercentual {
    return '${(progresso.clamp(0, 1) * 100).round()}%';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'valorAtual': valorAtual,
      'valorObjetivo': valorObjetivo,
      'categoria': categoria.name,
      'status': status.name,
      'progresso': progresso,
      'unidade': unidade,
      'tempoRestante': tempoRestante,
      'estimativa': estimativa,
      'coachDica': coachDica,
    };
  }

  factory FitaiMetaModel.fromJson(Map<String, dynamic> json) {
    return FitaiMetaModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Meta',
      descricao: json['descricao']?.toString() ?? '',
      valorAtual: _doubleFromJson(json['valorAtual']),
      valorObjetivo: _doubleFromJson(json['valorObjetivo']),
      categoria: _categoriaFromJson(json['categoria']),
      status: _statusFromJson(json['status']),
      progresso: _doubleFromJson(json['progresso']),
      unidade: json['unidade']?.toString() ?? '',
      tempoRestante: json['tempoRestante']?.toString() ?? '',
      estimativa: json['estimativa']?.toString() ?? '',
      coachDica: json['coachDica']?.toString() ?? '',
    );
  }

  static FitaiMetaCategoria _categoriaFromJson(dynamic value) {
    final text = value?.toString() ?? '';

    return FitaiMetaCategoria.values.firstWhere(
      (item) => item.name == text,
      orElse: () => FitaiMetaCategoria.treinos,
    );
  }

  static FitaiMetaStatus _statusFromJson(dynamic value) {
    final text = value?.toString() ?? '';

    return FitaiMetaStatus.values.firstWhere(
      (item) => item.name == text,
      orElse: () => FitaiMetaStatus.emAndamento,
    );
  }

  static double _doubleFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}

class FitaiMetasResumo {
  final List<FitaiMetaModel> metas;

  const FitaiMetasResumo({required this.metas});

  int get concluidas {
    return metas
        .where((meta) => meta.status == FitaiMetaStatus.concluida)
        .length;
  }

  int get atrasadas {
    return metas
        .where((meta) => meta.status == FitaiMetaStatus.atrasada)
        .length;
  }

  double get progressoMedio {
    if (metas.isEmpty) return 0;
    final total = metas.fold<double>(0, (soma, meta) => soma + meta.progresso);
    return (total / metas.length).clamp(0, 1).toDouble();
  }

  Map<FitaiMetaCategoria, List<FitaiMetaModel>> get porCategoria {
    final agrupadas = <FitaiMetaCategoria, List<FitaiMetaModel>>{};

    for (final meta in metas) {
      agrupadas.putIfAbsent(meta.categoria, () => []).add(meta);
    }

    return agrupadas;
  }

  List<String> get dicasCoach {
    final dicas = <String>[];

    final quase = metas.where((meta) {
      return meta.status != FitaiMetaStatus.concluida && meta.progresso >= 0.8;
    }).toList();
    if (quase.isNotEmpty) {
      dicas.add(
        'Voce ja completou ${quase.first.progressoPercentual} em ${quase.first.titulo}.',
      );
    }

    final atrasada = metas
        .where((meta) => meta.status == FitaiMetaStatus.atrasada)
        .toList();
    if (atrasada.isNotEmpty) {
      dicas.add('Hoje e um bom dia para recuperar ${atrasada.first.titulo}.');
    }

    if (concluidas > 0) {
      dicas.add(
        '$concluidas meta${concluidas == 1 ? '' : 's'} ja concluida${concluidas == 1 ? '' : 's'}.',
      );
    }

    if (dicas.isEmpty) {
      dicas.add('Mantenha o ritmo: metas pequenas repetidas viram evolucao.');
    }

    return dicas.take(3).toList();
  }
}
