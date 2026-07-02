import '../models/achievement_model.dart';
import '../models/corrida_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import '../models/passos_diarios_model.dart';
import 'storage_service.dart';
import 'streak_service.dart';

class AchievementEvaluation {
  final List<AchievementModel> conquistas;
  final List<AchievementModel> novas;

  const AchievementEvaluation({required this.conquistas, required this.novas});
}

class _AchievementRule {
  final AchievementModel conquista;
  final bool Function(_AchievementMetrics metrics) desbloqueia;

  const _AchievementRule({required this.conquista, required this.desbloqueia});
}

class _AchievementMetrics {
  final int totalTreinos;
  final int totalSeries;
  final double volumeTotal;
  final int melhorSequencia;
  final int tempoTotalSegundos;
  final int totalRecordes;
  final int totalCorridas;
  final double distanciaCorridaTotal;
  final double maiorDistanciaCorrida;
  final int totalPassos;
  final int recordePassosDia;
  final int melhorSequenciaMetaPassos;

  const _AchievementMetrics({
    required this.totalTreinos,
    required this.totalSeries,
    required this.volumeTotal,
    required this.melhorSequencia,
    required this.tempoTotalSegundos,
    required this.totalRecordes,
    required this.totalCorridas,
    required this.distanciaCorridaTotal,
    required this.maiorDistanciaCorrida,
    required this.totalPassos,
    required this.recordePassosDia,
    required this.melhorSequenciaMetaPassos,
  });
}

class AchievementService {
  const AchievementService();

  Future<List<AchievementModel>> carregarConquistas() async {
    final resultado = await avaliarConquistas();
    return resultado.conquistas;
  }

  Future<AchievementEvaluation> avaliarConquistas() async {
    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final corridas = await StorageService.carregarCorridas();
    final distanciaCorridaSalva = await StorageService.carregarDistanciaTotal();
    final totalCorridasSalvo = await StorageService.carregarTotalCorridas();
    final historicoPassos = await StorageService.carregarHistoricoPassos();
    final passosAtuais = await StorageService.carregarPassos();
    final metasPassos = await StorageService.carregarMetasPassos();
    final salvas = await StorageService.carregarConquistasSalvas();
    final salvasPorId = {
      for (final conquista in salvas) conquista.id: conquista,
    };
    final metrics = _calcularMetricas(
      historicoTreinos,
      historicoSeries,
      corridas,
      distanciaCorridaSalva,
      totalCorridasSalvo,
      historicoPassos,
      passosAtuais,
      metasPassos['diaria'] ?? 10000,
    );
    final agora = DateTime.now();
    final novas = <AchievementModel>[];
    final atualizadas = <AchievementModel>[];

    for (final regra in _regras) {
      final salva = salvasPorId[regra.conquista.id];
      final jaDesbloqueada = salva?.desbloqueada == true;
      final deveDesbloquear = regra.desbloqueia(metrics);

      if (jaDesbloqueada) {
        atualizadas.add(
          regra.conquista.copyWith(desbloqueada: true, data: salva?.data),
        );
        continue;
      }

      if (deveDesbloquear) {
        final desbloqueada = regra.conquista.copyWith(
          desbloqueada: true,
          data: agora,
        );
        atualizadas.add(desbloqueada);
        novas.add(desbloqueada);
      } else {
        atualizadas.add(regra.conquista);
      }
    }

    if (novas.isNotEmpty || _precisaSalvar(salvas, atualizadas)) {
      await StorageService.salvarConquistas(atualizadas);
    }

    return AchievementEvaluation(conquistas: atualizadas, novas: novas);
  }

  _AchievementMetrics _calcularMetricas(
    List<HistoricoTreinoModel> treinos,
    List<HistoricoSerieTreinoModel> series,
    List<CorridaModel> corridas,
    double distanciaCorridaSalva,
    int totalCorridasSalvo,
    List<PassosDiariosModel> historicoPassos,
    int passosAtuais,
    int metaPassosDiaria,
  ) {
    final streak = const StreakService().calcularStreak(treinos);
    final seriesResumo = treinos.fold<int>(
      0,
      (total, treino) => total + treino.seriesConcluidas,
    );
    final volumeSeries = series.fold<double>(
      0,
      (total, serie) => total + serie.volume,
    );
    final volumeResumo = treinos.fold<double>(
      0,
      (total, treino) => total + treino.volumeTotal,
    );
    final distanciaCorridas = corridas.fold<double>(
      0,
      (total, corrida) => total + corrida.distancia,
    );
    final maiorDistanciaCorrida = corridas.fold<double>(
      0,
      (maior, corrida) => corrida.distancia > maior ? corrida.distancia : maior,
    );
    final historicoPassosAtualizado = _historicoPassosComHoje(
      historicoPassos,
      passosAtuais,
      metaPassosDiaria,
    );
    final totalPassos = historicoPassosAtualizado.fold<int>(
      0,
      (total, registro) => total + registro.passos,
    );
    final recordePassosDia = historicoPassosAtualizado.fold<int>(
      0,
      (maior, registro) => registro.passos > maior ? registro.passos : maior,
    );

    return _AchievementMetrics(
      totalTreinos: treinos.length,
      totalSeries: series.isNotEmpty ? series.length : seriesResumo,
      volumeTotal: volumeSeries > 0 ? volumeSeries : volumeResumo,
      melhorSequencia: streak.melhor,
      tempoTotalSegundos: treinos.fold<int>(
        0,
        (total, treino) => total + treino.tempoSegundos,
      ),
      totalRecordes: treinos.fold<int>(
        0,
        (total, treino) => total + treino.recordesBatidos,
      ),
      totalCorridas: corridas.length > totalCorridasSalvo
          ? corridas.length
          : totalCorridasSalvo,
      distanciaCorridaTotal: distanciaCorridas > distanciaCorridaSalva
          ? distanciaCorridas
          : distanciaCorridaSalva,
      maiorDistanciaCorrida: maiorDistanciaCorrida,
      totalPassos: totalPassos,
      recordePassosDia: recordePassosDia,
      melhorSequenciaMetaPassos: _melhorSequenciaMetas(
        historicoPassosAtualizado,
      ),
    );
  }

  List<PassosDiariosModel> _historicoPassosComHoje(
    List<PassosDiariosModel> historico,
    int passosAtuais,
    int metaPassosDiaria,
  ) {
    final porData = {for (final registro in historico) registro.data: registro};
    final hoje = DateTime.now();
    final chaveHoje = _formatarDataChave(hoje);

    porData.putIfAbsent(
      chaveHoje,
      () => PassosDiariosModel(
        data: chaveHoje,
        passos: passosAtuais,
        metaDiaria: metaPassosDiaria,
        distanciaKm: passosAtuais * 0.000762,
        calorias: passosAtuais * 0.04,
        tempoAtivoMinutos: (passosAtuais / 100).round(),
      ),
    );

    return porData.values.toList();
  }

  int _melhorSequenciaMetas(List<PassosDiariosModel> historico) {
    final datasAtingidas =
        historico
            .where((registro) => registro.metaAtingida)
            .map((registro) => DateTime.tryParse(registro.data))
            .whereType<DateTime>()
            .map((data) => DateTime(data.year, data.month, data.day))
            .toList()
          ..sort();

    if (datasAtingidas.isEmpty) return 0;

    var melhor = 1;
    var atual = 1;

    for (var i = 1; i < datasAtingidas.length; i++) {
      final diferenca = datasAtingidas[i]
          .difference(datasAtingidas[i - 1])
          .inDays;

      if (diferenca == 1) {
        atual++;
      } else if (diferenca > 1) {
        atual = 1;
      }

      if (atual > melhor) melhor = atual;
    }

    return melhor;
  }

  String _formatarDataChave(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '${data.year}-$mes-$dia';
  }

  bool _precisaSalvar(
    List<AchievementModel> salvas,
    List<AchievementModel> atualizadas,
  ) {
    if (salvas.length != atualizadas.length) return true;

    final salvasPorId = {
      for (final conquista in salvas) conquista.id: conquista,
    };

    for (final conquista in atualizadas) {
      final salva = salvasPorId[conquista.id];
      if (salva == null) return true;
      if (salva.desbloqueada != conquista.desbloqueada) return true;
      if (salva.data?.toIso8601String() != conquista.data?.toIso8601String()) {
        return true;
      }
    }

    return false;
  }

  static List<_AchievementRule> get _regras {
    return [
      _treinos(
        "treino_001",
        "Primeiro treino",
        "Finalize seu primeiro treino.",
        1,
      ),
      _treinos("treino_010", "10 treinos", "Finalize 10 treinos.", 10),
      _treinos("treino_050", "50 treinos", "Finalize 50 treinos.", 50),
      _treinos("treino_100", "100 treinos", "Finalize 100 treinos.", 100),
      _treinos("treino_250", "250 treinos", "Finalize 250 treinos.", 250),
      _series("series_100", "100 séries", "Conclua 100 séries.", 100),
      _series("series_500", "500 séries", "Conclua 500 séries.", 500),
      _series("series_1000", "1000 séries", "Conclua 1000 séries.", 1000),
      _volume(
        "volume_001t",
        "1 tonelada movimentada",
        "Movimente 1.000 kg em volume total.",
        1000,
      ),
      _volume(
        "volume_010t",
        "10 toneladas",
        "Movimente 10.000 kg em volume total.",
        10000,
      ),
      _volume(
        "volume_100t",
        "100 toneladas",
        "Movimente 100.000 kg em volume total.",
        100000,
      ),
      _streak(
        "streak_003",
        "3 dias seguidos",
        "Treine por 3 dias seguidos.",
        3,
      ),
      _streak("streak_007", "7 dias", "Treine por 7 dias seguidos.", 7),
      _streak("streak_015", "15 dias", "Treine por 15 dias seguidos.", 15),
      _streak("streak_030", "30 dias", "Treine por 30 dias seguidos.", 30),
      _tempo(
        "tempo_010h",
        "10 horas treinadas",
        "Acumule 10 horas de treino.",
        10,
      ),
      _tempo("tempo_050h", "50 horas", "Acumule 50 horas de treino.", 50),
      _tempo("tempo_100h", "100 horas", "Acumule 100 horas de treino.", 100),
      _recordes(
        "pr_001",
        "Primeiro PR",
        "Bata seu primeiro recorde pessoal.",
        1,
      ),
      _recordes("pr_010", "10 PRs", "Bata 10 recordes pessoais.", 10),
      _recordes("pr_050", "50 PRs", "Bata 50 recordes pessoais.", 50),
      _corridaQuantidade(
        "corrida_001",
        "Primeira corrida",
        "Finalize sua primeira corrida.",
        1,
      ),
      _corridaUnica(
        "corrida_5k",
        "5 km em uma corrida",
        "Complete pelo menos 5 km em uma unica corrida.",
        5,
      ),
      _corridaUnica(
        "corrida_10k",
        "10 km em uma corrida",
        "Complete pelo menos 10 km em uma unica corrida.",
        10,
      ),
      _corridaAcumulada(
        "corrida_50k_total",
        "50 km acumulados",
        "Acumule 50 km em corridas.",
        50,
      ),
      _corridaAcumulada(
        "corrida_100k_total",
        "100 km acumulados",
        "Acumule 100 km em corridas.",
        100,
      ),
      _corridaQuantidade(
        "corrida_010",
        "10 corridas concluidas",
        "Finalize 10 corridas.",
        10,
      ),
      _passosDia(
        "passos_10000_dia",
        "10.000 passos em um dia",
        "Alcance 10.000 passos em um dia.",
        10000,
      ),
      _passosDia(
        "passos_20000_dia",
        "20.000 passos em um dia",
        "Alcance 20.000 passos em um dia.",
        20000,
      ),
      _passosAcumulados(
        "passos_100000_total",
        "100.000 passos acumulados",
        "Acumule 100.000 passos.",
        100000,
      ),
      _passosAcumulados(
        "passos_1000000_total",
        "1 milhao de passos acumulados",
        "Acumule 1.000.000 de passos.",
        1000000,
      ),
      _passosSequencia(
        "passos_meta_007",
        "7 dias batendo a meta",
        "Bata sua meta diaria de passos por 7 dias.",
        7,
      ),
      _passosSequencia(
        "passos_meta_030",
        "30 dias batendo a meta",
        "Bata sua meta diaria de passos por 30 dias.",
        30,
      ),
    ];
  }

  static _AchievementRule _treinos(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "fitness_center",
        categoria: "Treinos",
      ),
      desbloqueia: (metrics) => metrics.totalTreinos >= alvo,
    );
  }

  static _AchievementRule _series(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "format_list_numbered",
        categoria: "Exercícios",
      ),
      desbloqueia: (metrics) => metrics.totalSeries >= alvo,
    );
  }

  static _AchievementRule _volume(
    String id,
    String nome,
    String descricao,
    double alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "monitor_weight",
        categoria: "Volume",
      ),
      desbloqueia: (metrics) => metrics.volumeTotal >= alvo,
    );
  }

  static _AchievementRule _streak(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "local_fire_department",
        categoria: "Sequência",
      ),
      desbloqueia: (metrics) => metrics.melhorSequencia >= alvo,
    );
  }

  static _AchievementRule _tempo(
    String id,
    String nome,
    String descricao,
    int horas,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "timer",
        categoria: "Tempo",
      ),
      desbloqueia: (metrics) => metrics.tempoTotalSegundos >= horas * 3600,
    );
  }

  static _AchievementRule _recordes(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "emoji_events",
        categoria: "Recordes",
      ),
      desbloqueia: (metrics) => metrics.totalRecordes >= alvo,
    );
  }

  static _AchievementRule _corridaQuantidade(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "directions_run",
        categoria: "Corrida",
      ),
      desbloqueia: (metrics) => metrics.totalCorridas >= alvo,
    );
  }

  static _AchievementRule _corridaUnica(
    String id,
    String nome,
    String descricao,
    double alvoKm,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "directions_run",
        categoria: "Corrida",
      ),
      desbloqueia: (metrics) => metrics.maiorDistanciaCorrida >= alvoKm,
    );
  }

  static _AchievementRule _corridaAcumulada(
    String id,
    String nome,
    String descricao,
    double alvoKm,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "route",
        categoria: "Corrida",
      ),
      desbloqueia: (metrics) => metrics.distanciaCorridaTotal >= alvoKm,
    );
  }

  static _AchievementRule _passosDia(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "directions_walk",
        categoria: "Passos",
      ),
      desbloqueia: (metrics) => metrics.recordePassosDia >= alvo,
    );
  }

  static _AchievementRule _passosAcumulados(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "directions_walk",
        categoria: "Passos",
      ),
      desbloqueia: (metrics) => metrics.totalPassos >= alvo,
    );
  }

  static _AchievementRule _passosSequencia(
    String id,
    String nome,
    String descricao,
    int alvo,
  ) {
    return _AchievementRule(
      conquista: AchievementModel(
        id: id,
        nome: nome,
        descricao: descricao,
        icone: "local_fire_department",
        categoria: "Passos",
      ),
      desbloqueia: (metrics) => metrics.melhorSequenciaMetaPassos >= alvo,
    );
  }
}
