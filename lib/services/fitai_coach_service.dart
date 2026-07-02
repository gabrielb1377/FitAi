import '../models/corrida_model.dart';
import '../models/historico_treino_model.dart';
import '../models/passos_diarios_model.dart';
import 'storage_service.dart';

enum FitAICoachTipo {
  passos,
  corrida,
  sequencia,
  conquista,
  recuperacao,
  treino,
  geral,
}

class FitAICoachInsight {
  final String titulo;
  final String mensagem;
  final FitAICoachTipo tipo;
  final int prioridade;

  const FitAICoachInsight({
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    this.prioridade = 0,
  });
}

class FitAICoachService {
  const FitAICoachService();

  Future<List<FitAICoachInsight>> gerarInsights({
    int? passosHoje,
    int? metaDiaria,
    int? metaSemanal,
    int? metaMensal,
    List<PassosDiariosModel>? historicoPassos,
    List<CorridaModel>? corridas,
    List<HistoricoTreinoModel>? historicoTreinos,
    double distanciaCorridaAtual = 0,
    int segundosCorridaAtual = 0,
  }) async {
    final metas =
        metaDiaria == null || metaSemanal == null || metaMensal == null
        ? await StorageService.carregarMetasPassos()
        : const <String, int>{};

    final passos = passosHoje ?? await StorageService.carregarPassos();
    final diaria = metaDiaria ?? metas['diaria'] ?? 10000;
    final semanal = metaSemanal ?? metas['semanal'] ?? 70000;
    final mensal = metaMensal ?? metas['mensal'] ?? 300000;
    final historicoPassosBase =
        historicoPassos ?? await StorageService.carregarHistoricoPassos();
    final corridasBase = corridas ?? await StorageService.carregarCorridas();
    final treinosBase =
        historicoTreinos ?? await StorageService.carregarHistoricoTreinos();

    final contexto = _CoachContext(
      passosHoje: passos,
      metaDiaria: diaria,
      metaSemanal: semanal,
      metaMensal: mensal,
      historicoPassos: _historicoPassosComHoje(
        historicoPassosBase,
        passos,
        diaria,
      ),
      corridas: corridasBase,
      historicoTreinos: treinosBase,
      distanciaCorridaAtual: distanciaCorridaAtual,
      segundosCorridaAtual: segundosCorridaAtual,
    );

    final insights = _gerarMensagens(contexto)
      ..sort((a, b) => b.prioridade.compareTo(a.prioridade));

    return _semDuplicar(insights).take(4).toList();
  }

  List<FitAICoachInsight> _gerarMensagens(_CoachContext c) {
    final insights = <FitAICoachInsight>[];
    final faltamPassos = (c.metaDiaria - c.passosHoje).clamp(0, c.metaDiaria);
    final progressoPassos = c.metaDiaria <= 0
        ? 0.0
        : c.passosHoje / c.metaDiaria;
    final diasSemCorrer = c.diasSemCorrer;
    final ultimaCorrida = c.ultimaCorrida;
    final corridaAnterior = c.corridaAnterior;
    final ontem = c.registroOntem;

    void add(
      bool condicao, {
      required String titulo,
      required String mensagem,
      required FitAICoachTipo tipo,
      int prioridade = 0,
    }) {
      if (!condicao) return;
      insights.add(
        FitAICoachInsight(
          titulo: titulo,
          mensagem: mensagem,
          tipo: tipo,
          prioridade: prioridade,
        ),
      );
    }

    add(
      c.passosHoje >= c.metaDiaria,
      titulo: 'Meta diaria concluida',
      mensagem: 'Parabens! Voce bateu sua meta diaria de passos.',
      tipo: FitAICoachTipo.passos,
      prioridade: 90,
    );
    add(
      c.passosHoje < c.metaDiaria,
      titulo: 'Passos restantes',
      mensagem: 'Faltam $faltamPassos passos para sua meta de hoje.',
      tipo: FitAICoachTipo.passos,
      prioridade: 88,
    );
    add(
      progressoPassos >= 0.85 && c.passosHoje < c.metaDiaria,
      titulo: 'Quase la',
      mensagem: 'Voce ja passou de 85% da meta. Uma caminhada curta resolve.',
      tipo: FitAICoachTipo.passos,
      prioridade: 86,
    );
    add(
      progressoPassos >= 0.5 && progressoPassos < 0.85,
      titulo: 'Bom ritmo',
      mensagem: 'Voce ja completou metade da meta diaria.',
      tipo: FitAICoachTipo.passos,
      prioridade: 72,
    );
    add(
      progressoPassos < 0.25,
      titulo: 'Comeco do dia',
      mensagem: 'Um bloco de 10 minutos caminhando ja muda seu progresso.',
      tipo: FitAICoachTipo.passos,
      prioridade: 64,
    );
    add(
      c.passosHoje >= 10000,
      titulo: 'Marca classica',
      mensagem: '10.000 passos no dia: consistencia de atleta.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 82,
    );
    add(
      c.passosHoje >= 20000,
      titulo: 'Dia muito ativo',
      mensagem: '20.000 passos em um dia pedem boa hidratacao e descanso.',
      tipo: FitAICoachTipo.recuperacao,
      prioridade: 92,
    );
    add(
      c.passosHoje > c.mediaPassos7Dias && c.mediaPassos7Dias > 0,
      titulo: 'Acima da media',
      mensagem: 'Seus passos de hoje estao acima da media dos ultimos 7 dias.',
      tipo: FitAICoachTipo.passos,
      prioridade: 73,
    );
    add(
      c.passosHoje < c.mediaPassos7Dias && c.mediaPassos7Dias > 0,
      titulo: 'Abaixo da media',
      mensagem:
          'Hoje esta abaixo da sua media recente. Ainda da tempo de reagir.',
      tipo: FitAICoachTipo.passos,
      prioridade: 67,
    );
    add(
      c.passosSemanaAtual >= c.metaSemanal,
      titulo: 'Meta semanal feita',
      mensagem: 'Voce ja bateu a meta semanal de passos.',
      tipo: FitAICoachTipo.passos,
      prioridade: 84,
    );
    add(
      c.passosSemanaAtual < c.metaSemanal,
      titulo: 'Meta semanal',
      mensagem:
          'Faltam ${(c.metaSemanal - c.passosSemanaAtual).clamp(0, c.metaSemanal)} passos para a meta semanal.',
      tipo: FitAICoachTipo.passos,
      prioridade: 61,
    );
    add(
      c.passosMesAtual >= c.metaMensal,
      titulo: 'Mes consistente',
      mensagem: 'Sua meta mensal de passos ja foi concluida.',
      tipo: FitAICoachTipo.passos,
      prioridade: 79,
    );
    add(
      c.recordePassosDia == c.passosHoje && c.passosHoje > 0,
      titulo: 'Melhor dia de passos',
      mensagem: 'Hoje esta empatado com seu melhor dia de passos registrado.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 78,
    );
    add(
      c.totalPassos >= 100000 && c.totalPassos < 1000000,
      titulo: 'Volume acumulado',
      mensagem: 'Voce ja passou de 100.000 passos acumulados.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 65,
    );
    add(
      c.totalPassos >= 1000000,
      titulo: 'Milhao de passos',
      mensagem: 'Voce chegou ao patamar de 1 milhao de passos acumulados.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 93,
    );

    add(
      c.sequenciaAtualMetas > 0,
      titulo: 'Sequencia ativa',
      mensagem: 'Voce mantem uma sequencia de ${c.sequenciaAtualMetas} dias.',
      tipo: FitAICoachTipo.sequencia,
      prioridade: 80,
    );
    add(
      c.sequenciaAtualMetas >= 7,
      titulo: 'Semana perfeita',
      mensagem: 'Sete dias batendo a meta. Excelente consistencia.',
      tipo: FitAICoachTipo.sequencia,
      prioridade: 91,
    );
    add(
      c.sequenciaAtualMetas >= 30,
      titulo: 'Habito consolidado',
      mensagem: '30 dias batendo meta: isso ja virou identidade.',
      tipo: FitAICoachTipo.sequencia,
      prioridade: 96,
    );
    add(
      c.sequenciaAtualMetas == 6,
      titulo: 'Conquista proxima',
      mensagem: 'Falta apenas 1 dia para completar 7 dias batendo meta.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 87,
    );
    add(
      c.sequenciaAtualMetas == 29,
      titulo: 'Marco grande perto',
      mensagem: 'Falta apenas 1 dia para 30 dias batendo sua meta.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 94,
    );
    add(
      c.sequenciaAtualMetas == 0 && c.passosHoje < c.metaDiaria,
      titulo: 'Sequencia em aberto',
      mensagem: 'Bata a meta hoje para iniciar uma nova sequencia.',
      tipo: FitAICoachTipo.sequencia,
      prioridade: 60,
    );

    add(
      c.corridas.isEmpty,
      titulo: 'Primeira corrida',
      mensagem:
          'Finalize uma corrida para liberar insights de ritmo e distancia.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 76,
    );
    add(
      ultimaCorrida != null,
      titulo: 'Ultima corrida',
      mensagem:
          'Sua ultima corrida teve ${ultimaCorrida?.distancia.toStringAsFixed(2)} km.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 70,
    );
    add(
      ultimaCorrida != null &&
          corridaAnterior != null &&
          ultimaCorrida.distancia > corridaAnterior.distancia,
      titulo: 'Evolucao na corrida',
      mensagem: 'Sua ultima corrida foi mais longa que a anterior.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 85,
    );
    add(
      ultimaCorrida != null &&
          corridaAnterior != null &&
          _ritmo(ultimaCorrida) < _ritmo(corridaAnterior),
      titulo: 'Ritmo melhor',
      mensagem: 'Sua ultima corrida teve ritmo melhor que a anterior.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 86,
    );
    add(
      ultimaCorrida != null &&
          corridaAnterior != null &&
          ultimaCorrida.distancia < corridaAnterior.distancia,
      titulo: 'Corrida mais leve',
      mensagem:
          'Sua ultima corrida foi menor. Pode ter sido um bom dia de recuperacao.',
      tipo: FitAICoachTipo.recuperacao,
      prioridade: 66,
    );
    add(
      diasSemCorrer != null && diasSemCorrer >= 4,
      titulo: 'Voltar a correr',
      mensagem: 'Voce esta ha $diasSemCorrer dias sem correr.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 83,
    );
    add(
      diasSemCorrer != null && diasSemCorrer == 1,
      titulo: 'Corrida recente',
      mensagem: 'Voce correu ontem. Hoje pode ser um bom dia para algo leve.',
      tipo: FitAICoachTipo.recuperacao,
      prioridade: 75,
    );
    add(
      c.distanciaCorridaSemana >= 5,
      titulo: 'Semana em movimento',
      mensagem:
          'Voce ja correu ${c.distanciaCorridaSemana.toStringAsFixed(1)} km nesta semana.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 74,
    );
    add(
      c.distanciaCorridaSemana == 0 && c.corridas.isNotEmpty,
      titulo: 'Semana sem corrida',
      mensagem: 'Ainda nao ha corrida registrada nesta semana.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 69,
    );
    add(
      c.distanciaCorridaTotal >= 45 && c.distanciaCorridaTotal < 50,
      titulo: '50 km chegando',
      mensagem: 'Faltam menos de 5 km para 50 km acumulados em corridas.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 89,
    );
    add(
      c.distanciaCorridaTotal >= 95 && c.distanciaCorridaTotal < 100,
      titulo: '100 km chegando',
      mensagem: 'Faltam menos de 5 km para 100 km acumulados em corridas.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 92,
    );
    add(
      c.corridas.length == 9,
      titulo: 'Conquista proxima',
      mensagem:
          'Falta apenas uma corrida para desbloquear 10 corridas concluidas.',
      tipo: FitAICoachTipo.conquista,
      prioridade: 90,
    );
    add(
      c.maiorCorrida >= 5,
      titulo: 'Base de 5 km',
      mensagem: 'Voce ja tem uma corrida de pelo menos 5 km no historico.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 62,
    );
    add(
      c.maiorCorrida >= 10,
      titulo: '10K desbloqueavel',
      mensagem: 'Voce ja mostrou capacidade para corridas longas.',
      tipo: FitAICoachTipo.corrida,
      prioridade: 63,
    );

    add(
      ontem != null && ontem.passos >= c.metaDiaria * 1.4,
      titulo: 'Recuperacao inteligente',
      mensagem:
          'Ontem voce teve uma atividade intensa. Hoje considere algo leve.',
      tipo: FitAICoachTipo.recuperacao,
      prioridade: 88,
    );
    add(
      ultimaCorrida != null && ultimaCorrida.distancia >= 8,
      titulo: 'Pos-corrida longa',
      mensagem:
          'A ultima corrida foi longa. Priorize mobilidade e sono de qualidade.',
      tipo: FitAICoachTipo.recuperacao,
      prioridade: 81,
    );
    add(
      c.caloriasHoje >= 500,
      titulo: 'Alto gasto hoje',
      mensagem: 'Seu gasto estimado passou de 500 kcal. Hidratacao importa.',
      tipo: FitAICoachTipo.recuperacao,
      prioridade: 77,
    );
    add(
      c.caloriasSemana >= 2000,
      titulo: 'Semana forte',
      mensagem: 'Seu gasto semanal estimado ja passou de 2.000 kcal.',
      tipo: FitAICoachTipo.geral,
      prioridade: 68,
    );
    add(
      c.treinosSemana >= 3,
      titulo: 'Frequencia de treinos',
      mensagem: 'Voce treinou ${c.treinosSemana} vezes nesta semana.',
      tipo: FitAICoachTipo.treino,
      prioridade: 71,
    );
    add(
      c.treinosSemana == 0 && c.historicoTreinos.isNotEmpty,
      titulo: 'Treinos da semana',
      mensagem: 'Ainda nao ha treino finalizado nesta semana.',
      tipo: FitAICoachTipo.treino,
      prioridade: 58,
    );
    add(
      c.diasSemTreinar != null && c.diasSemTreinar! >= 3,
      titulo: 'Retomada de treino',
      mensagem: 'Voce esta ha ${c.diasSemTreinar} dias sem finalizar treino.',
      tipo: FitAICoachTipo.treino,
      prioridade: 59,
    );
    add(
      c.passosHoje >= c.metaDiaria && c.distanciaCorridaSemana > 0,
      titulo: 'Dia completo',
      mensagem:
          'Passos em dia e corrida na semana: boa combinacao de base aerobica.',
      tipo: FitAICoachTipo.geral,
      prioridade: 82,
    );
    add(
      c.passosHoje < 3000 && diasSemCorrer != null && diasSemCorrer >= 5,
      titulo: 'Ativacao leve',
      mensagem: 'Um passeio curto hoje ja ajuda a retomar o ritmo.',
      tipo: FitAICoachTipo.recuperacao,
      prioridade: 66,
    );

    if (insights.isEmpty) {
      insights.add(
        const FitAICoachInsight(
          titulo: 'Consistencia primeiro',
          mensagem:
              'Registre passos e corridas para receber recomendacoes melhores.',
          tipo: FitAICoachTipo.geral,
          prioridade: 1,
        ),
      );
    }

    return insights;
  }

  List<FitAICoachInsight> _semDuplicar(List<FitAICoachInsight> insights) {
    final mensagens = <String>{};
    final filtradas = <FitAICoachInsight>[];

    for (final insight in insights) {
      if (mensagens.add(insight.mensagem)) {
        filtradas.add(insight);
      }
    }

    return filtradas;
  }

  double _ritmo(CorridaModel corrida) {
    if (corrida.distancia <= 0 || corrida.segundos <= 0) {
      return double.infinity;
    }

    return corrida.segundos / corrida.distancia;
  }

  List<PassosDiariosModel> _historicoPassosComHoje(
    List<PassosDiariosModel> historico,
    int passosHoje,
    int metaDiaria,
  ) {
    final porData = {for (final registro in historico) registro.data: registro};
    final hoje = DateTime.now();
    final chaveHoje = _formatarDataChave(hoje);

    porData.putIfAbsent(
      chaveHoje,
      () => PassosDiariosModel(
        data: chaveHoje,
        passos: passosHoje,
        metaDiaria: metaDiaria,
        distanciaKm: passosHoje * 0.000762,
        calorias: passosHoje * 0.04,
        tempoAtivoMinutos: (passosHoje / 100).round(),
      ),
    );

    return porData.values.toList()..sort((a, b) => b.data.compareTo(a.data));
  }

  String _formatarDataChave(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '${data.year}-$mes-$dia';
  }
}

class _CoachContext {
  final int passosHoje;
  final int metaDiaria;
  final int metaSemanal;
  final int metaMensal;
  final List<PassosDiariosModel> historicoPassos;
  final List<CorridaModel> corridas;
  final List<HistoricoTreinoModel> historicoTreinos;
  final double distanciaCorridaAtual;
  final int segundosCorridaAtual;

  const _CoachContext({
    required this.passosHoje,
    required this.metaDiaria,
    required this.metaSemanal,
    required this.metaMensal,
    required this.historicoPassos,
    required this.corridas,
    required this.historicoTreinos,
    required this.distanciaCorridaAtual,
    required this.segundosCorridaAtual,
  });

  DateTime get inicioSemana {
    final hoje = DateTime.now();
    final base = DateTime(hoje.year, hoje.month, hoje.day);
    return base.subtract(Duration(days: base.weekday - 1));
  }

  List<CorridaModel> get corridasOrdenadas {
    return [...corridas]..sort((a, b) {
      final dataA = DateTime.tryParse(a.data) ?? DateTime(0);
      final dataB = DateTime.tryParse(b.data) ?? DateTime(0);
      return dataB.compareTo(dataA);
    });
  }

  CorridaModel? get ultimaCorrida {
    final lista = corridasOrdenadas;
    if (lista.isEmpty) return null;
    return lista.first;
  }

  CorridaModel? get corridaAnterior {
    final lista = corridasOrdenadas;
    if (lista.length < 2) return null;
    return lista[1];
  }

  int? get diasSemCorrer {
    final ultima = ultimaCorrida;
    if (ultima == null) return null;

    final data = DateTime.tryParse(ultima.data);
    if (data == null) return null;

    final hoje = DateTime.now();
    final hojeBase = DateTime(hoje.year, hoje.month, hoje.day);
    final dataBase = DateTime(data.year, data.month, data.day);

    return hojeBase.difference(dataBase).inDays;
  }

  double get distanciaCorridaSemana {
    final fim = inicioSemana.add(const Duration(days: 7));
    final totalSalvo = corridas.fold<double>(0, (total, corrida) {
      final data = DateTime.tryParse(corrida.data);
      if (data == null) return total;

      final dataBase = DateTime(data.year, data.month, data.day);
      final dentro = !dataBase.isBefore(inicioSemana) && dataBase.isBefore(fim);

      return dentro ? total + corrida.distancia : total;
    });

    return totalSalvo + distanciaCorridaAtual;
  }

  double get distanciaCorridaTotal {
    return corridas.fold<double>(
          0,
          (total, corrida) => total + corrida.distancia,
        ) +
        distanciaCorridaAtual;
  }

  double get maiorCorrida {
    final maiorSalva = corridas.fold<double>(
      0,
      (maior, corrida) => corrida.distancia > maior ? corrida.distancia : maior,
    );

    return distanciaCorridaAtual > maiorSalva
        ? distanciaCorridaAtual
        : maiorSalva;
  }

  PassosDiariosModel? get registroOntem {
    final ontem = DateTime.now().subtract(const Duration(days: 1));
    final chave =
        '${ontem.year}-${ontem.month.toString().padLeft(2, '0')}-${ontem.day.toString().padLeft(2, '0')}';

    for (final registro in historicoPassos) {
      if (registro.data == chave) return registro;
    }

    return null;
  }

  int get passosSemanaAtual {
    final fim = inicioSemana.add(const Duration(days: 7));
    return historicoPassos.fold<int>(0, (total, registro) {
      final data = DateTime.tryParse(registro.data);
      if (data == null) return total;

      final dataBase = DateTime(data.year, data.month, data.day);
      final dentro = !dataBase.isBefore(inicioSemana) && dataBase.isBefore(fim);

      return dentro ? total + registro.passos : total;
    });
  }

  int get passosMesAtual {
    final agora = DateTime.now();
    return historicoPassos.fold<int>(0, (total, registro) {
      final data = DateTime.tryParse(registro.data);
      if (data == null) return total;

      return data.year == agora.year && data.month == agora.month
          ? total + registro.passos
          : total;
    });
  }

  int get mediaPassos7Dias {
    final hoje = DateTime.now();
    final inicio = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    ).subtract(const Duration(days: 6));
    final recentes = historicoPassos.where((registro) {
      final data = DateTime.tryParse(registro.data);
      if (data == null) return false;
      final base = DateTime(data.year, data.month, data.day);
      return !base.isBefore(inicio);
    }).toList();

    if (recentes.isEmpty) return 0;

    final total = recentes.fold<int>(0, (soma, item) => soma + item.passos);
    return (total / recentes.length).round();
  }

  int get recordePassosDia {
    return historicoPassos.fold<int>(
      0,
      (maior, registro) => registro.passos > maior ? registro.passos : maior,
    );
  }

  int get totalPassos {
    return historicoPassos.fold<int>(0, (total, item) => total + item.passos);
  }

  int get sequenciaAtualMetas {
    final porData = {
      for (final registro in historicoPassos) registro.data: registro,
    };
    var data = DateTime.now();
    var sequencia = 0;

    while (true) {
      final chave =
          '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      final registro = porData[chave];

      if (registro == null || !registro.metaAtingida) break;

      sequencia++;
      data = data.subtract(const Duration(days: 1));
    }

    return sequencia;
  }

  double get caloriasHoje {
    return passosHoje * 0.04 + distanciaCorridaAtual * 60;
  }

  double get caloriasSemana {
    final fim = inicioSemana.add(const Duration(days: 7));
    final caloriasPassos = historicoPassos.fold<double>(0, (total, registro) {
      final data = DateTime.tryParse(registro.data);
      if (data == null) return total;

      final base = DateTime(data.year, data.month, data.day);
      final dentro = !base.isBefore(inicioSemana) && base.isBefore(fim);

      return dentro ? total + registro.calorias : total;
    });

    return caloriasPassos + distanciaCorridaSemana * 60;
  }

  int get treinosSemana {
    final fim = inicioSemana.add(const Duration(days: 7));

    return historicoTreinos.where((treino) {
      final data = DateTime(
        treino.dataHora.year,
        treino.dataHora.month,
        treino.dataHora.day,
      );

      return !data.isBefore(inicioSemana) && data.isBefore(fim);
    }).length;
  }

  int? get diasSemTreinar {
    if (historicoTreinos.isEmpty) return null;

    final ultimo = historicoTreinos
        .map((treino) => treino.dataHora)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final hoje = DateTime.now();
    final hojeBase = DateTime(hoje.year, hoje.month, hoje.day);
    final ultimoBase = DateTime(ultimo.year, ultimo.month, ultimo.day);

    return hojeBase.difference(ultimoBase).inDays;
  }
}
