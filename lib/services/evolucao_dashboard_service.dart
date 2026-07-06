import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import '../models/progresso_exercicio_model.dart';
import 'storage_service.dart';
import 'streak_service.dart';

class EvolucaoDashboardService {
  const EvolucaoDashboardService();

  Future<EvolucaoDashboardData> carregar() async {
    final historico = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final progressos = await StorageService.carregarProgressos();
    final registros = _registrosCarga(historicoSeries, progressos);
    final semanaAtual = _resumoSemana(historico, registros, DateTime.now());
    final semanaAnterior = _resumoSemana(
      historico,
      registros,
      DateTime.now().subtract(const Duration(days: 7)),
    );
    final streak = const StreakService().calcularStreak(historico);
    final musculos = _musculosTreinados(historico, registros);
    final carga = _cargaResumo(registros);
    final recordes = _recordes(registros);

    return EvolucaoDashboardData(
      historico: historico,
      semanaAtual: semanaAtual,
      semanaAnterior: semanaAnterior,
      carga: carga,
      recordes: recordes,
      frequencia: FrequenciaResumo(
        treinosSemana: semanaAtual.treinos,
        diasConsecutivos: streak.atual,
        maiorSequencia: streak.melhor,
      ),
      musculos: musculos,
      insights: _insights(
        historico: historico,
        registros: registros,
        semanaAtual: semanaAtual,
        semanaAnterior: semanaAnterior,
        musculos: musculos,
        carga: carga,
        streak: streak,
      ),
    );
  }

  List<RegistroCargaResumo> _registrosCarga(
    List<HistoricoSerieTreinoModel> series,
    List<ProgressoExercicioModel> progressos,
  ) {
    final registros = <RegistroCargaResumo>[
      for (final serie in series)
        RegistroCargaResumo(
          nome: serie.nomeExercicio,
          peso: serie.peso,
          repeticoes: serie.repeticoes,
          series: 1,
          data: serie.dataHora,
        ),
      for (final progresso in progressos)
        RegistroCargaResumo(
          nome: progresso.nomeExercicio,
          peso: progresso.peso,
          repeticoes: progresso.repeticoes,
          series: progresso.series <= 0 ? 1 : progresso.series,
          data: progresso.data,
        ),
    ];

    final vistos = <String>{};
    final unicos = <RegistroCargaResumo>[];

    for (final registro in registros) {
      final chave = [
        _normalizar(registro.nome),
        registro.data.toIso8601String(),
        registro.peso.toStringAsFixed(2),
        registro.repeticoes,
        registro.series,
      ].join('|');

      if (vistos.add(chave)) unicos.add(registro);
    }

    unicos.sort((a, b) => b.data.compareTo(a.data));
    return unicos;
  }

  SemanaEvolucaoResumo _resumoSemana(
    List<HistoricoTreinoModel> historico,
    List<RegistroCargaResumo> registros,
    DateTime referencia,
  ) {
    final inicio = _inicioSemana(referencia);
    final fim = inicio.add(const Duration(days: 7));
    final treinos = historico.where((item) {
      final data = _somenteData(item.dataHora.toLocal());
      return !data.isBefore(inicio) && data.isBefore(fim);
    }).toList();
    final series = registros.where((item) {
      final data = _somenteData(item.data.toLocal());
      return !data.isBefore(inicio) && data.isBefore(fim);
    }).toList();
    final volumeSeries = series.fold<double>(
      0,
      (total, item) => total + item.volume,
    );

    return SemanaEvolucaoResumo(
      treinos: treinos.length,
      tempoSegundos: treinos.fold<int>(
        0,
        (total, item) => total + item.tempoSegundos,
      ),
      volume: volumeSeries > 0
          ? volumeSeries
          : treinos.fold<double>(0, (total, item) => total + item.volumeTotal),
      exercicios: treinos.fold<int>(
        0,
        (total, item) => total + item.exerciciosConcluidos,
      ),
    );
  }

  CargaEvolucaoResumo _cargaResumo(List<RegistroCargaResumo> registros) {
    final validos = registros.where((item) => item.peso > 0).toList();
    if (validos.isEmpty) return CargaEvolucaoResumo.vazio();

    final ultimo = validos.first;
    final melhor = [...validos]..sort((a, b) => b.peso.compareTo(a.peso));
    final anteriores = validos.where((item) {
      return _normalizar(item.nome) == _normalizar(ultimo.nome) &&
          item.data.isBefore(ultimo.data);
    }).toList();
    final anterior = anteriores.isEmpty ? null : anteriores.first;
    final diferenca = anterior == null || anterior.peso <= 0
        ? 0.0
        : ((ultimo.peso - anterior.peso) / anterior.peso) * 100;

    return CargaEvolucaoResumo(
      exercicio: ultimo.nome,
      ultimaCarga: ultimo.peso,
      melhorCarga: melhor.first.peso,
      diferencaPercentual: diferenca,
      ultimaAtualizacao: ultimo.data,
      possuiDados: true,
    );
  }

  List<RecordePessoalResumo> _recordes(List<RegistroCargaResumo> registros) {
    const alvos = [
      _RecordeAlvo('Maior Supino', ['supino', 'bench', 'flexao']),
      _RecordeAlvo('Maior Agachamento', ['agachamento', 'squat']),
      _RecordeAlvo('Maior Terra', ['terra', 'deadlift']),
      _RecordeAlvo('Maior Desenvolvimento', ['desenvolvimento', 'press']),
      _RecordeAlvo('Maior Rosca', ['rosca', 'curl', 'biceps']),
    ];

    return [
      for (final alvo in alvos)
        RecordePessoalResumo(
          titulo: alvo.titulo,
          exercicio: _melhorPorKeywords(registros, alvo.keywords)?.nome,
          carga: _melhorPorKeywords(registros, alvo.keywords)?.peso ?? 0,
        ),
    ];
  }

  RegistroCargaResumo? _melhorPorKeywords(
    List<RegistroCargaResumo> registros,
    List<String> keywords,
  ) {
    final matches = registros.where((registro) {
      final nome = _normalizar(registro.nome);
      return keywords.any((keyword) => nome.contains(keyword)) &&
          registro.peso > 0;
    }).toList();

    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.peso.compareTo(a.peso));
    return matches.first;
  }

  List<MusculoTreinadoResumo> _musculosTreinados(
    List<HistoricoTreinoModel> historico,
    List<RegistroCargaResumo> registros,
  ) {
    const grupos = {
      'Peito': ['peito', 'supino', 'crucifixo', 'flexao', 'crossover'],
      'Costas': ['costas', 'remada', 'puxada', 'barra', 'terra'],
      'Pernas': ['perna', 'agachamento', 'leg', 'cadeira', 'panturrilha'],
      'Ombros': ['ombro', 'desenvolvimento', 'elevacao', 'shoulder'],
      'Braços': ['biceps', 'triceps', 'rosca', 'curl', 'frances'],
      'Abdômen': ['abdomen', 'abdominal', 'prancha', 'core'],
    };

    final contagem = {for (final nome in grupos.keys) nome: 0};

    for (final registro in registros) {
      final texto = _normalizar(registro.nome);
      for (final entrada in grupos.entries) {
        if (entrada.value.any((keyword) => texto.contains(keyword))) {
          contagem[entrada.key] =
              (contagem[entrada.key] ?? 0) + registro.series;
        }
      }
    }

    for (final treino in historico) {
      final texto = _normalizar('${treino.nomeTreino} ${treino.objetivo}');
      for (final entrada in grupos.entries) {
        if (entrada.value.any((keyword) => texto.contains(keyword))) {
          contagem[entrada.key] =
              (contagem[entrada.key] ?? 0) + treino.exerciciosConcluidos;
        }
      }
    }

    final maior = contagem.values.fold<int>(0, (a, b) => a > b ? a : b);

    return [
      for (final entrada in contagem.entries)
        MusculoTreinadoResumo(
          nome: entrada.key,
          total: entrada.value,
          percentual: maior == 0 ? 0 : entrada.value / maior,
        ),
    ];
  }

  List<CoachInsightResumo> _insights({
    required List<HistoricoTreinoModel> historico,
    required List<RegistroCargaResumo> registros,
    required SemanaEvolucaoResumo semanaAtual,
    required SemanaEvolucaoResumo semanaAnterior,
    required List<MusculoTreinadoResumo> musculos,
    required CargaEvolucaoResumo carga,
    required StreakResumo streak,
  }) {
    if (historico.isEmpty) {
      return const [
        CoachInsightResumo(
          titulo: 'Primeiro passo',
          descricao: 'Finalize um treino para o FitIA gerar insights reais.',
          tipo: CoachInsightTipo.neutro,
        ),
      ];
    }

    final insights = <CoachInsightResumo>[];
    final variacaoVolume = _variacao(semanaAtual.volume, semanaAnterior.volume);

    if (semanaAnterior.volume > 0 && variacaoVolume.abs() >= 5) {
      insights.add(
        CoachInsightResumo(
          titulo: variacaoVolume >= 0 ? 'Volume em alta' : 'Volume em queda',
          descricao:
              'Seu volume semanal ${variacaoVolume >= 0 ? 'aumentou' : 'caiu'} ${variacaoVolume.abs().toStringAsFixed(0)}%.',
          tipo: variacaoVolume >= 0
              ? CoachInsightTipo.positivo
              : CoachInsightTipo.alerta,
        ),
      );
    }

    final menosTreinado = [...musculos]
      ..sort((a, b) => a.total.compareTo(b.total));
    if (menosTreinado.isNotEmpty && menosTreinado.first.total == 0) {
      insights.add(
        CoachInsightResumo(
          titulo: 'Equilíbrio muscular',
          descricao:
              'Você ainda não registrou ${menosTreinado.first.nome} nos dados recentes.',
          tipo: CoachInsightTipo.alerta,
        ),
      );
    }

    if (carga.possuiDados && carga.diferencaPercentual > 0) {
      insights.add(
        CoachInsightResumo(
          titulo: 'Carga evoluindo',
          descricao:
              '${carga.exercicio} subiu ${carga.diferencaPercentual.toStringAsFixed(0)}% desde a execução anterior.',
          tipo: CoachInsightTipo.positivo,
        ),
      );
    }

    if (streak.atual >= 3) {
      insights.add(
        CoachInsightResumo(
          titulo: 'Consistência forte',
          descricao: 'Você mantém uma sequência de ${streak.atual} dias.',
          tipo: CoachInsightTipo.positivo,
        ),
      );
    }

    if (semanaAtual.treinos >= 3) {
      insights.add(
        CoachInsightResumo(
          titulo: 'Semana ativa',
          descricao:
              'Você treinou ${semanaAtual.treinos} vezes esta semana. Mantenha o ritmo.',
          tipo: CoachInsightTipo.positivo,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const CoachInsightResumo(
          titulo: 'Base em construção',
          descricao:
              'Registre mais cargas e treinos para receber insights mais precisos.',
          tipo: CoachInsightTipo.neutro,
        ),
      );
    }

    return insights.take(4).toList();
  }

  double _variacao(double atual, double anterior) {
    if (anterior <= 0) return atual > 0 ? 100 : 0;
    return ((atual - anterior) / anterior) * 100;
  }

  DateTime _inicioSemana(DateTime data) {
    final local = _somenteData(data.toLocal());
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  DateTime _somenteData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .trim();
  }
}

class EvolucaoDashboardData {
  final List<HistoricoTreinoModel> historico;
  final SemanaEvolucaoResumo semanaAtual;
  final SemanaEvolucaoResumo semanaAnterior;
  final CargaEvolucaoResumo carga;
  final List<RecordePessoalResumo> recordes;
  final FrequenciaResumo frequencia;
  final List<MusculoTreinadoResumo> musculos;
  final List<CoachInsightResumo> insights;

  const EvolucaoDashboardData({
    required this.historico,
    required this.semanaAtual,
    required this.semanaAnterior,
    required this.carga,
    required this.recordes,
    required this.frequencia,
    required this.musculos,
    required this.insights,
  });

  bool get possuiDados => historico.isNotEmpty;
}

class SemanaEvolucaoResumo {
  final int treinos;
  final int tempoSegundos;
  final double volume;
  final int exercicios;

  const SemanaEvolucaoResumo({
    required this.treinos,
    required this.tempoSegundos,
    required this.volume,
    required this.exercicios,
  });
}

class CargaEvolucaoResumo {
  final String exercicio;
  final double ultimaCarga;
  final double melhorCarga;
  final double diferencaPercentual;
  final DateTime ultimaAtualizacao;
  final bool possuiDados;

  const CargaEvolucaoResumo({
    required this.exercicio,
    required this.ultimaCarga,
    required this.melhorCarga,
    required this.diferencaPercentual,
    required this.ultimaAtualizacao,
    required this.possuiDados,
  });

  factory CargaEvolucaoResumo.vazio() {
    return CargaEvolucaoResumo(
      exercicio: 'Sem dados',
      ultimaCarga: 0,
      melhorCarga: 0,
      diferencaPercentual: 0,
      ultimaAtualizacao: DateTime.fromMillisecondsSinceEpoch(0),
      possuiDados: false,
    );
  }
}

class RecordePessoalResumo {
  final String titulo;
  final String? exercicio;
  final double carga;

  const RecordePessoalResumo({
    required this.titulo,
    required this.exercicio,
    required this.carga,
  });
}

class FrequenciaResumo {
  final int treinosSemana;
  final int diasConsecutivos;
  final int maiorSequencia;

  const FrequenciaResumo({
    required this.treinosSemana,
    required this.diasConsecutivos,
    required this.maiorSequencia,
  });
}

class MusculoTreinadoResumo {
  final String nome;
  final int total;
  final double percentual;

  const MusculoTreinadoResumo({
    required this.nome,
    required this.total,
    required this.percentual,
  });
}

class CoachInsightResumo {
  final String titulo;
  final String descricao;
  final CoachInsightTipo tipo;

  const CoachInsightResumo({
    required this.titulo,
    required this.descricao,
    required this.tipo,
  });
}

enum CoachInsightTipo { positivo, alerta, neutro }

class RegistroCargaResumo {
  final String nome;
  final double peso;
  final int repeticoes;
  final int series;
  final DateTime data;

  const RegistroCargaResumo({
    required this.nome,
    required this.peso,
    required this.repeticoes,
    required this.series,
    required this.data,
  });

  double get volume => peso * repeticoes * series;
}

class _RecordeAlvo {
  final String titulo;
  final List<String> keywords;

  const _RecordeAlvo(this.titulo, this.keywords);
}
