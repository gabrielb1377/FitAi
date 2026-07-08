import '../models/achievement_model.dart';
import '../models/corrida_model.dart';
import '../models/fitai_notification_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import '../models/passos_diarios_model.dart';
import '../models/treino_model.dart';
import 'agenda_treinos_service.dart';
import 'storage_service.dart';
import 'treino_do_dia_service.dart';
import 'treino_service.dart';

class NotificationService {
  const NotificationService();

  Future<List<FitaiNotificationModel>> carregarNotificacoes({
    bool sincronizar = true,
  }) async {
    if (sincronizar) {
      await sincronizarNotificacoes();
    }

    return StorageService.carregarNotificacoes();
  }

  Future<int> contarNaoLidas() async {
    final notificacoes = await carregarNotificacoes();
    return notificacoes.where((item) => !item.lida).length;
  }

  Future<void> marcarComoLida(String id) {
    return StorageService.marcarNotificacaoLida(id);
  }

  Future<void> marcarTodasComoLidas() {
    return StorageService.marcarTodasNotificacoesLidas();
  }

  Future<void> excluir(String id) {
    return StorageService.excluirNotificacao(id);
  }

  Future<void> sincronizarNotificacoes() async {
    final salvas = await StorageService.carregarNotificacoes();
    final automaticas = await _gerarAutomaticas();
    final porId = {for (final item in salvas) item.id: item};

    for (final notificacao in automaticas) {
      final existente = porId[notificacao.id];
      porId[notificacao.id] = notificacao.copyWith(
        lida: existente?.lida ?? notificacao.lida,
      );
    }

    final atualizadas = porId.values.toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    await StorageService.salvarNotificacoes(atualizadas.take(80).toList());
  }

  Future<List<FitaiNotificationModel>> _gerarAutomaticas() async {
    final agora = DateTime.now();
    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final corridas = await StorageService.carregarCorridas();
    final conquistas = await StorageService.carregarConquistasSalvas();
    final passos = await StorageService.carregarPassos();
    final metas = await StorageService.carregarMetasPassos();
    final historicoPassos = await StorageService.carregarHistoricoPassos();
    final treinos = await _carregarTreinos();
    final notificacoes = <FitaiNotificationModel>[
      ..._notificacoesTreinoHoje(treinos, historicoTreinos, agora),
      ...await _notificacoesAgenda(agora),
      ..._notificacoesFrequencia(historicoTreinos, agora),
      ..._notificacoesRecordes(historicoTreinos, historicoSeries, agora),
      ..._notificacoesCorridas(corridas, agora),
      ..._notificacoesMetas(passos, metas, historicoPassos, agora),
      ..._notificacoesConquistas(conquistas, agora),
      ..._notificacoesEvolucao(historicoTreinos, historicoSeries, agora),
    ];

    return notificacoes;
  }

  Future<List<TreinoModel>> _carregarTreinos() async {
    final salvos = await StorageService.carregarTreinos();
    final emMemoria = TreinoService.instance.treinos;
    final porId = <String, TreinoModel>{};

    for (final treino in [...salvos, ...emMemoria]) {
      if (treino.isPlanoPrincipal) porId[treino.id] = treino;
    }

    return porId.values.toList();
  }

  List<FitaiNotificationModel> _notificacoesTreinoHoje(
    List<TreinoModel> treinos,
    List<HistoricoTreinoModel> historico,
    DateTime agora,
  ) {
    final selecao = const TreinoDoDiaService().selecionarTreinoDoDiaDetalhado(
      treinos,
      historico,
    );
    final treino = selecao.treino;

    if (treino == null ||
        selecao.treinoConcluidoHoje ||
        selecao.diaDeDescanso) {
      return const [];
    }

    final grupo = treino.grupoDia.trim().isNotEmpty
        ? treino.grupoDia
        : treino.nome;

    return [
      FitaiNotificationModel(
        id: 'treino_hoje_${_chaveData(agora)}',
        titulo: 'Hoje e dia de treino',
        descricao: 'Hoje e dia de $grupo. Toque para iniciar.',
        categoria: FitaiNotificationCategoria.treinos,
        icone: 'fitness_center',
        data: agora,
        acao: 'treino:${treino.id}',
      ),
    ];
  }

  Future<List<FitaiNotificationModel>> _notificacoesAgenda(
    DateTime agora,
  ) async {
    final mes = await const AgendaTreinosService().carregarMes(agora);
    final pendentes = mes.dias.where((dia) {
      return dia.status == AgendaTreinoStatus.pendente ||
          dia.status == AgendaTreinoStatus.pulado;
    }).toList();

    if (pendentes.isEmpty) return const [];

    final dia = pendentes.first;
    final nome = dia.diaNome.trim().isEmpty ? 'treino' : dia.diaNome;

    return [
      FitaiNotificationModel(
        id: 'agenda_pendente_${_chaveData(dia.data)}',
        titulo: 'Treino pendente',
        descricao: 'Seu treino de $nome ficou pendente. Deseja reorganizar?',
        categoria: FitaiNotificationCategoria.agenda,
        icone: 'calendar_month',
        data: agora,
        acao: 'agenda',
      ),
    ];
  }

  List<FitaiNotificationModel> _notificacoesFrequencia(
    List<HistoricoTreinoModel> historico,
    DateTime agora,
  ) {
    if (historico.isEmpty) return const [];

    final ultima = historico
        .map((item) => item.dataHora)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final dias = _somenteData(agora).difference(_somenteData(ultima)).inDays;

    if (dias < 4) return const [];

    return [
      FitaiNotificationModel(
        id: 'coach_dias_sem_treino_${_chaveData(agora)}',
        titulo: 'Retomar consistencia',
        descricao: 'Voce esta ha $dias dias sem treinar.',
        categoria: FitaiNotificationCategoria.coach,
        icone: 'psychology',
        data: agora,
        acao: 'evolucao',
      ),
    ];
  }

  List<FitaiNotificationModel> _notificacoesRecordes(
    List<HistoricoTreinoModel> historicoTreinos,
    List<HistoricoSerieTreinoModel> historicoSeries,
    DateTime agora,
  ) {
    final recentes = historicoTreinos
        .where((treino) {
          return agora.difference(treino.dataHora).inDays <= 7;
        })
        .fold<int>(0, (total, treino) => total + treino.recordesBatidos);

    if (recentes > 0) {
      return [
        FitaiNotificationModel(
          id: 'recordes_semana_${_chaveSemana(agora)}',
          titulo: 'Novo recorde pessoal',
          descricao:
              'Voce bateu $recentes recorde${recentes == 1 ? '' : 's'} recentemente.',
          categoria: FitaiNotificationCategoria.recordes,
          icone: 'emoji_events',
          data: agora,
          acao: 'evolucao',
        ),
      ];
    }

    final melhor = historicoSeries.where((serie) => serie.peso > 0).toList()
      ..sort((a, b) => b.peso.compareTo(a.peso));

    if (melhor.isEmpty) return const [];

    return [
      FitaiNotificationModel(
        id: 'recorde_melhor_carga_${_chaveSemana(agora)}',
        titulo: 'Melhor carga registrada',
        descricao:
            '${melhor.first.nomeExercicio}: ${_formatarPeso(melhor.first.peso)}.',
        categoria: FitaiNotificationCategoria.recordes,
        icone: 'military_tech',
        data: melhor.first.dataHora,
        acao: 'evolucao',
      ),
    ];
  }

  List<FitaiNotificationModel> _notificacoesCorridas(
    List<CorridaModel> corridas,
    DateTime agora,
  ) {
    if (corridas.isEmpty) {
      return [
        FitaiNotificationModel(
          id: 'corrida_primeira',
          titulo: 'Primeira corrida',
          descricao: 'Finalize uma corrida para liberar insights de ritmo.',
          categoria: FitaiNotificationCategoria.corridas,
          icone: 'directions_run',
          data: agora,
          acao: 'corrida',
        ),
      ];
    }

    final ordenadas = [...corridas]
      ..sort((a, b) {
        final dataA = DateTime.tryParse(a.data) ?? DateTime(0);
        final dataB = DateTime.tryParse(b.data) ?? DateTime(0);
        return dataB.compareTo(dataA);
      });
    final ultimaData = DateTime.tryParse(ordenadas.first.data);
    if (ultimaData == null) return const [];

    final dias = _somenteData(
      agora,
    ).difference(_somenteData(ultimaData)).inDays;
    if (dias < 4) return const [];

    return [
      FitaiNotificationModel(
        id: 'corrida_dias_${_chaveData(agora)}',
        titulo: 'Corrida em pausa',
        descricao: 'Voce esta ha $dias dias sem correr.',
        categoria: FitaiNotificationCategoria.corridas,
        icone: 'directions_run',
        data: agora,
        acao: 'corrida',
      ),
    ];
  }

  List<FitaiNotificationModel> _notificacoesMetas(
    int passosHoje,
    Map<String, int> metas,
    List<PassosDiariosModel> historicoPassos,
    DateTime agora,
  ) {
    final diaria = metas['diaria'] ?? 10000;
    final semanal = metas['semanal'] ?? 70000;
    final passosSemana = historicoPassos.fold<int>(0, (total, item) {
      final data = DateTime.tryParse(item.data);
      if (data == null || data.isBefore(_inicioSemana(agora))) return total;
      return total + item.passos;
    });
    final notificacoes = <FitaiNotificationModel>[];

    if (passosHoje >= diaria) {
      notificacoes.add(
        FitaiNotificationModel(
          id: 'meta_diaria_${_chaveData(agora)}',
          titulo: 'Meta diaria concluida',
          descricao: 'Voce bateu sua meta diaria de passos.',
          categoria: FitaiNotificationCategoria.metas,
          icone: 'flag',
          data: agora,
          acao: 'perfil',
        ),
      );
    }

    if (semanal > 0 && passosSemana >= semanal) {
      notificacoes.add(
        FitaiNotificationModel(
          id: 'meta_semanal_${_chaveSemana(agora)}',
          titulo: 'Meta semanal concluida',
          descricao: 'Sua meta semanal de passos foi concluida.',
          categoria: FitaiNotificationCategoria.metas,
          icone: 'workspace_premium',
          data: agora,
          acao: 'perfil',
        ),
      );
    }

    return notificacoes;
  }

  List<FitaiNotificationModel> _notificacoesConquistas(
    List<AchievementModel> conquistas,
    DateTime agora,
  ) {
    final recentes = conquistas.where((conquista) {
      final data = conquista.data;
      return conquista.desbloqueada &&
          data != null &&
          agora.difference(data).inDays <= 7;
    }).toList();

    if (recentes.isEmpty) return const [];

    recentes.sort(
      (a, b) => (b.data ?? DateTime(0)).compareTo(a.data ?? DateTime(0)),
    );
    final conquista = recentes.first;

    return [
      FitaiNotificationModel(
        id: 'conquista_${conquista.id}',
        titulo: 'Nova conquista desbloqueada',
        descricao: conquista.nome,
        categoria: FitaiNotificationCategoria.recordes,
        icone: conquista.icone,
        data: conquista.data ?? agora,
        acao: 'perfil',
      ),
    ];
  }

  List<FitaiNotificationModel> _notificacoesEvolucao(
    List<HistoricoTreinoModel> historicoTreinos,
    List<HistoricoSerieTreinoModel> historicoSeries,
    DateTime agora,
  ) {
    final inicioSemana = _inicioSemana(agora);
    final inicioAnterior = inicioSemana.subtract(const Duration(days: 7));
    final volumeAtual = _volumeEntre(
      historicoTreinos,
      historicoSeries,
      inicioSemana,
      agora,
    );
    final volumeAnterior = _volumeEntre(
      historicoTreinos,
      historicoSeries,
      inicioAnterior,
      inicioSemana,
    );

    if (volumeAnterior <= 0) return const [];

    final variacao = ((volumeAtual - volumeAnterior) / volumeAnterior) * 100;
    if (variacao.abs() < 8) return const [];

    return [
      FitaiNotificationModel(
        id: 'volume_${_chaveSemana(agora)}',
        titulo: variacao >= 0 ? 'Volume em alta' : 'Volume em queda',
        descricao:
            'Voce ${variacao >= 0 ? 'aumentou' : 'reduziu'} o volume em ${variacao.abs().toStringAsFixed(0)}%.',
        categoria: FitaiNotificationCategoria.evolucao,
        icone: variacao >= 0 ? 'trending_up' : 'trending_down',
        data: agora,
        acao: 'evolucao',
      ),
    ];
  }

  double _volumeEntre(
    List<HistoricoTreinoModel> treinos,
    List<HistoricoSerieTreinoModel> series,
    DateTime inicio,
    DateTime fim,
  ) {
    final volumeSeries = series
        .where((serie) {
          final data = serie.dataHora;
          return !data.isBefore(inicio) && data.isBefore(fim);
        })
        .fold<double>(0, (total, serie) => total + serie.volume);

    if (volumeSeries > 0) return volumeSeries;

    return treinos
        .where((treino) {
          final data = treino.dataHora;
          return !data.isBefore(inicio) && data.isBefore(fim);
        })
        .fold<double>(0, (total, treino) => total + treino.volumeTotal);
  }

  DateTime _inicioSemana(DateTime data) {
    final base = _somenteData(data);
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  DateTime _somenteData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  String _chaveData(DateTime data) {
    final local = data.toLocal();
    return '${local.year}${local.month.toString().padLeft(2, '0')}${local.day.toString().padLeft(2, '0')}';
  }

  String _chaveSemana(DateTime data) {
    final inicio = _inicioSemana(data);
    return _chaveData(inicio);
  }

  String _formatarPeso(double peso) {
    final valor = peso == peso.roundToDouble()
        ? peso.round().toString()
        : peso.toStringAsFixed(1).replaceAll('.', ',');
    return '$valor kg';
  }
}
