import '../models/agenda_treino_override_model.dart';
import '../models/corrida_model.dart';
import '../models/historico_treino_model.dart';
import '../models/treino_model.dart';
import 'storage_service.dart';
import 'streak_service.dart';
import 'treino_service.dart';

enum AgendaTreinoStatus {
  programado,
  concluido,
  pendente,
  corrida,
  descanso,
  pulado,
  reagendado,
}

class AgendaTreinosService {
  const AgendaTreinosService();

  Future<AgendaTreinosMes> carregarMes(DateTime mes) async {
    final planos = await _carregarPlanos();
    final historico = await StorageService.carregarHistoricoTreinos();
    final corridas = await StorageService.carregarCorridas();
    final overrides = await StorageService.carregarAgendaTreinoOverrides();
    final dias = <AgendaDiaTreino>[];
    final inicio = DateTime(mes.year, mes.month);
    final totalDias = DateTime(mes.year, mes.month + 1, 0).day;
    final overridePorData = {for (final item in overrides) item.data: item};

    for (var dia = 1; dia <= totalDias; dia++) {
      final data = DateTime(mes.year, mes.month, dia);
      dias.add(
        _montarDia(
          data: data,
          planos: planos,
          historico: historico,
          corridas: corridas,
          override: overridePorData[_chaveData(data)],
        ),
      );
    }

    final streak = const StreakService().calcularStreak(historico);
    final resumo = AgendaResumoTreinos(
      sequenciaAtual: streak.atual,
      maiorSequencia: streak.melhor,
      treinosMes: dias
          .where((dia) => dia.status == AgendaTreinoStatus.concluido)
          .length,
      diasPerdidos: dias
          .where(
            (dia) =>
                dia.status == AgendaTreinoStatus.pendente ||
                dia.status == AgendaTreinoStatus.pulado,
          )
          .length,
    );

    return AgendaTreinosMes(
      mes: inicio,
      dias: dias,
      resumo: resumo,
      sugestao: _coachSugestao(dias),
    );
  }

  Future<void> marcarDescanso(AgendaDiaTreino dia) async {
    await _salvarOverride(dia, status: 'descanso');
  }

  Future<void> pularTreino(AgendaDiaTreino dia) async {
    await _salvarOverride(dia, status: 'pulado');
  }

  Future<void> moverTreino(AgendaDiaTreino dia, DateTime destino) async {
    final destinoKey = _chaveData(destino);
    final origemKey = _chaveData(dia.data);
    final agora = DateTime.now();

    await StorageService.salvarAgendaTreinoOverride(
      AgendaTreinoOverrideModel(
        id: 'agenda_${origemKey}_${dia.planoId}_${dia.diaOrdem}',
        data: origemKey,
        status: 'reagendado',
        planoId: dia.planoId,
        planoNome: dia.planoNome,
        diaCodigo: dia.diaCodigo,
        diaNome: dia.diaNome,
        diaOrdem: dia.diaOrdem,
        dataDestino: destinoKey,
        atualizadoEm: agora,
      ),
    );

    await StorageService.salvarAgendaTreinoOverride(
      AgendaTreinoOverrideModel(
        id: 'agenda_${destinoKey}_${dia.planoId}_${dia.diaOrdem}',
        data: destinoKey,
        status: 'programado',
        planoId: dia.planoId,
        planoNome: dia.planoNome,
        diaCodigo: dia.diaCodigo,
        diaNome: dia.diaNome,
        diaOrdem: dia.diaOrdem,
        dataOrigem: origemKey,
        atualizadoEm: agora,
      ),
    );
  }

  Future<List<TreinoModel>> _carregarPlanos() async {
    final emMemoria = TreinoService.instance.treinos;
    final salvos = await StorageService.carregarTreinos();
    final porId = <String, TreinoModel>{};

    for (final treino in [...salvos, ...emMemoria]) {
      if (treino.isPlanoPrincipal) porId[treino.id] = treino;
    }

    return porId.values.toList()
      ..sort((a, b) => a.dataCriacao.compareTo(b.dataCriacao));
  }

  AgendaDiaTreino _montarDia({
    required DateTime data,
    required List<TreinoModel> planos,
    required List<HistoricoTreinoModel> historico,
    required List<CorridaModel> corridas,
    required AgendaTreinoOverrideModel? override,
  }) {
    final hoje = _somenteData(DateTime.now());
    final dataKey = _chaveData(data);
    final temCorrida = corridas.any(
      (corrida) => _chaveCorrida(corrida) == dataKey,
    );
    final concluido = historico.any(
      (item) => _chaveData(item.dataHora) == dataKey,
    );

    if (override != null) {
      final manual = _diaManual(data, override, planos, temCorrida);
      if (manual != null) {
        return manual.copyWith(
          status: concluido ? AgendaTreinoStatus.concluido : manual.status,
        );
      }
    }

    final natural = _diaNatural(data, planos, temCorrida);

    if (natural == null) {
      return AgendaDiaTreino(
        data: data,
        status: temCorrida
            ? AgendaTreinoStatus.corrida
            : AgendaTreinoStatus.descanso,
        temCorrida: temCorrida,
      );
    }

    if (concluido) {
      return natural.copyWith(status: AgendaTreinoStatus.concluido);
    }

    if (_somenteData(data).isBefore(hoje)) {
      return natural.copyWith(status: AgendaTreinoStatus.pendente);
    }

    return natural;
  }

  AgendaDiaTreino? _diaManual(
    DateTime data,
    AgendaTreinoOverrideModel override,
    List<TreinoModel> planos,
    bool temCorrida,
  ) {
    if (override.status == 'descanso') {
      return AgendaDiaTreino(
        data: data,
        status: AgendaTreinoStatus.descanso,
        temCorrida: temCorrida,
      );
    }

    if (override.status == 'pulado') {
      return _fromOverride(data, override, planos, AgendaTreinoStatus.pulado);
    }

    if (override.status == 'reagendado') {
      return _fromOverride(
        data,
        override,
        planos,
        AgendaTreinoStatus.reagendado,
      );
    }

    if (override.status == 'programado') {
      return _fromOverride(
        data,
        override,
        planos,
        AgendaTreinoStatus.programado,
      );
    }

    return null;
  }

  AgendaDiaTreino _fromOverride(
    DateTime data,
    AgendaTreinoOverrideModel override,
    List<TreinoModel> planos,
    AgendaTreinoStatus status,
  ) {
    final plano = planos
        .where((item) => item.id == override.planoId)
        .firstOrNull;
    final dia = plano == null
        ? null
        : _diasPlano(
            plano,
          ).where((item) => item.ordem == override.diaOrdem).firstOrNull;

    return AgendaDiaTreino(
      data: data,
      status: status,
      planoId: override.planoId,
      planoNome: override.planoNome,
      diaCodigo: override.diaCodigo,
      diaNome: override.diaNome,
      diaOrdem: override.diaOrdem,
      quantidadeExercicios: _quantidadeExercicios(plano, dia),
      tempoPrevisto: plano?.tempoEstimado ?? 0,
      temCorrida: false,
    );
  }

  AgendaDiaTreino? _diaNatural(
    DateTime data,
    List<TreinoModel> planos,
    bool temCorrida,
  ) {
    if (planos.isEmpty) return null;

    final plano = planos.first;
    final dias = _diasPlano(plano);
    if (dias.isEmpty) return null;

    final diasSemana = _diasSemana(
      plano.diasPorSemana > 0 ? plano.diasPorSemana : dias.length,
    );
    final indiceSemana = diasSemana.indexOf(data.weekday);
    if (indiceSemana < 0) return null;

    final dia = dias[indiceSemana % dias.length];

    return AgendaDiaTreino(
      data: data,
      status: AgendaTreinoStatus.programado,
      planoId: plano.id,
      planoNome: plano.nome,
      diaCodigo: dia.codigo,
      diaNome: dia.nome,
      diaOrdem: dia.ordem,
      quantidadeExercicios: _quantidadeExercicios(plano, dia),
      tempoPrevisto: plano.tempoEstimado,
      temCorrida: temCorrida,
    );
  }

  List<TreinoDiaModel> _diasPlano(TreinoModel plano) {
    if (plano.planoDias.isNotEmpty) {
      return [...plano.planoDias]..sort((a, b) => a.ordem.compareTo(b.ordem));
    }

    return [
      TreinoDiaModel(
        codigo: plano.diaPlano.trim().isEmpty ? 'A' : plano.diaPlano,
        nome: plano.grupoDia.trim().isEmpty ? plano.nome : plano.grupoDia,
        ordem: plano.ordemDia <= 0 ? 1 : plano.ordemDia,
        exercicioIds: plano.exercicios
            .map((exercicio) => exercicio.id)
            .toList(),
      ),
    ];
  }

  int _quantidadeExercicios(TreinoModel? plano, TreinoDiaModel? dia) {
    if (plano == null) return 0;
    if (dia == null || dia.exercicioIds.isEmpty) return plano.exercicios.length;
    return plano.exercicios
        .where((exercicio) => dia.exercicioIds.contains(exercicio.id))
        .length;
  }

  List<int> _diasSemana(int diasPorSemana) {
    const base = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ];

    return base.take(diasPorSemana.clamp(1, 6)).toList();
  }

  AgendaCoachSugestao? _coachSugestao(List<AgendaDiaTreino> dias) {
    final hoje = _somenteData(DateTime.now());
    final atrasados =
        dias
            .where((dia) => dia.status == AgendaTreinoStatus.pendente)
            .where((dia) => _somenteData(dia.data).isBefore(hoje))
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));

    if (atrasados.isEmpty) return null;

    final dia = atrasados.first;
    return AgendaCoachSugestao(
      dia: dia,
      destino: hoje.add(const Duration(days: 1)),
      mensagem:
          'Seu treino de ${dia.grupoMuscular} ficou pendente. Deseja mover para amanhã?',
    );
  }

  Future<void> _salvarOverride(
    AgendaDiaTreino dia, {
    required String status,
  }) async {
    final dataKey = _chaveData(dia.data);
    await StorageService.salvarAgendaTreinoOverride(
      AgendaTreinoOverrideModel(
        id: 'agenda_${dataKey}_${dia.planoId}_${dia.diaOrdem}',
        data: dataKey,
        status: status,
        planoId: dia.planoId,
        planoNome: dia.planoNome,
        diaCodigo: dia.diaCodigo,
        diaNome: dia.diaNome,
        diaOrdem: dia.diaOrdem,
        atualizadoEm: DateTime.now(),
      ),
    );
  }

  String _chaveCorrida(CorridaModel corrida) {
    final data = DateTime.tryParse(corrida.data);
    if (data != null) return _chaveData(data);
    return corrida.data.length >= 10
        ? corrida.data.substring(0, 10)
        : corrida.data;
  }

  String _chaveData(DateTime data) {
    final local = data.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  DateTime _somenteData(DateTime data) {
    final local = data.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

class AgendaTreinosMes {
  final DateTime mes;
  final List<AgendaDiaTreino> dias;
  final AgendaResumoTreinos resumo;
  final AgendaCoachSugestao? sugestao;

  const AgendaTreinosMes({
    required this.mes,
    required this.dias,
    required this.resumo,
    required this.sugestao,
  });
}

class AgendaDiaTreino {
  final DateTime data;
  final AgendaTreinoStatus status;
  final String planoId;
  final String planoNome;
  final String diaCodigo;
  final String diaNome;
  final int diaOrdem;
  final int quantidadeExercicios;
  final int tempoPrevisto;
  final bool temCorrida;

  const AgendaDiaTreino({
    required this.data,
    required this.status,
    this.planoId = '',
    this.planoNome = '',
    this.diaCodigo = '',
    this.diaNome = '',
    this.diaOrdem = 0,
    this.quantidadeExercicios = 0,
    this.tempoPrevisto = 0,
    this.temCorrida = false,
  });

  String get grupoMuscular {
    if (diaNome.trim().isNotEmpty) return diaNome;
    if (planoNome.trim().isNotEmpty) return planoNome;
    return 'Descanso';
  }

  String get statusLabel {
    return switch (status) {
      AgendaTreinoStatus.programado => 'Treino programado',
      AgendaTreinoStatus.concluido => 'Treino concluído',
      AgendaTreinoStatus.pendente => 'Treino pendente',
      AgendaTreinoStatus.corrida => 'Corrida',
      AgendaTreinoStatus.descanso => 'Descanso',
      AgendaTreinoStatus.pulado => 'Treino pulado',
      AgendaTreinoStatus.reagendado => 'Reagendado',
    };
  }

  bool get temTreino => planoId.trim().isNotEmpty;

  AgendaDiaTreino copyWith({AgendaTreinoStatus? status, bool? temCorrida}) {
    return AgendaDiaTreino(
      data: data,
      status: status ?? this.status,
      planoId: planoId,
      planoNome: planoNome,
      diaCodigo: diaCodigo,
      diaNome: diaNome,
      diaOrdem: diaOrdem,
      quantidadeExercicios: quantidadeExercicios,
      tempoPrevisto: tempoPrevisto,
      temCorrida: temCorrida ?? this.temCorrida,
    );
  }
}

class AgendaResumoTreinos {
  final int sequenciaAtual;
  final int maiorSequencia;
  final int treinosMes;
  final int diasPerdidos;

  const AgendaResumoTreinos({
    required this.sequenciaAtual,
    required this.maiorSequencia,
    required this.treinosMes,
    required this.diasPerdidos,
  });
}

class AgendaCoachSugestao {
  final AgendaDiaTreino dia;
  final DateTime destino;
  final String mensagem;

  const AgendaCoachSugestao({
    required this.dia,
    required this.destino,
    required this.mensagem,
  });
}
