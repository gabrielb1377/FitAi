import 'dart:math' as math;

import '../models/corrida_model.dart';
import '../models/fitai_meta_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import '../models/passos_diarios_model.dart';
import 'storage_service.dart';
import 'streak_service.dart';

class MetasService {
  const MetasService();

  Future<FitaiMetasResumo> carregarMetas() async {
    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final corridas = await StorageService.carregarCorridas();
    final passosHoje = await StorageService.carregarPassos();
    final metasPassos = await StorageService.carregarMetasPassos();
    final historicoPassos = await StorageService.carregarHistoricoPassos();
    final perfil = await StorageService.carregarPerfilUsuario();
    final agora = DateTime.now();

    final metas = <FitaiMetaModel>[
      ..._metasTreinos(historicoTreinos, agora),
      ..._metasCorridas(corridas, agora),
      ..._metasPassos(passosHoje, metasPassos, historicoPassos, agora),
      ..._metasForca(historicoSeries, agora),
      ..._metasCorpo(perfil),
    ];

    return FitaiMetasResumo(metas: metas);
  }

  List<FitaiMetaModel> _metasTreinos(
    List<HistoricoTreinoModel> historico,
    DateTime agora,
  ) {
    final inicioSemana = _inicioSemana(agora);
    final inicioMes = DateTime(agora.year, agora.month);
    final streak = const StreakService().calcularStreak(historico);
    final treinosSemana = historico.where((treino) {
      return !treino.dataHora.isBefore(inicioSemana);
    }).length;
    final treinosMes = historico.where((treino) {
      return !treino.dataHora.isBefore(inicioMes);
    }).length;

    return [
      _meta(
        id: 'treinos_semana',
        titulo: 'Treinos por semana',
        descricao: 'Concluir 3 treinos nesta semana.',
        atual: treinosSemana.toDouble(),
        objetivo: 3,
        categoria: FitaiMetaCategoria.treinos,
        unidade: 'treinos',
        fimPeriodo: _fimSemana(agora),
        inicioPeriodo: inicioSemana,
      ),
      _meta(
        id: 'treinos_mes',
        titulo: 'Treinos por mes',
        descricao: 'Completar 12 sessoes no mes.',
        atual: treinosMes.toDouble(),
        objetivo: 12,
        categoria: FitaiMetaCategoria.treinos,
        unidade: 'treinos',
        fimPeriodo: _fimMes(agora),
        inicioPeriodo: inicioMes,
      ),
      _meta(
        id: 'treinos_streak',
        titulo: 'Dias consecutivos',
        descricao: 'Manter 7 dias de consistencia.',
        atual: streak.atual.toDouble(),
        objetivo: 7,
        categoria: FitaiMetaCategoria.treinos,
        unidade: 'dias',
        fimPeriodo: _fimSemana(agora),
        inicioPeriodo: inicioSemana,
      ),
    ];
  }

  List<FitaiMetaModel> _metasCorridas(
    List<CorridaModel> corridas,
    DateTime agora,
  ) {
    final inicioSemana = _inicioSemana(agora);
    final inicioMes = DateTime(agora.year, agora.month);
    final corridasSemana = corridas.where((corrida) {
      final data = _dataCorrida(corrida);
      return data != null && !data.isBefore(inicioSemana);
    }).toList();
    final corridasMes = corridas.where((corrida) {
      final data = _dataCorrida(corrida);
      return data != null && !data.isBefore(inicioMes);
    }).toList();
    final kmSemana = _distanciaTotal(corridasSemana);
    final kmMes = _distanciaTotal(corridasMes);
    final tempoMesMin =
        corridasMes.fold<int>(0, (total, corrida) => total + corrida.segundos) /
        60;

    return [
      _meta(
        id: 'corrida_km_semana',
        titulo: 'Km por semana',
        descricao: 'Correr 10 km nesta semana.',
        atual: kmSemana,
        objetivo: 10,
        categoria: FitaiMetaCategoria.corridas,
        unidade: 'km',
        fimPeriodo: _fimSemana(agora),
        inicioPeriodo: inicioSemana,
      ),
      _meta(
        id: 'corrida_km_mes',
        titulo: 'Km por mes',
        descricao: 'Acumular 40 km no mes.',
        atual: kmMes,
        objetivo: 40,
        categoria: FitaiMetaCategoria.corridas,
        unidade: 'km',
        fimPeriodo: _fimMes(agora),
        inicioPeriodo: inicioMes,
      ),
      _meta(
        id: 'corrida_tempo_mes',
        titulo: 'Tempo correndo',
        descricao: 'Somar 180 minutos correndo.',
        atual: tempoMesMin,
        objetivo: 180,
        categoria: FitaiMetaCategoria.corridas,
        unidade: 'min',
        fimPeriodo: _fimMes(agora),
        inicioPeriodo: inicioMes,
      ),
      _meta(
        id: 'corrida_quantidade_mes',
        titulo: 'Quantidade de corridas',
        descricao: 'Finalizar 8 corridas no mes.',
        atual: corridasMes.length.toDouble(),
        objetivo: 8,
        categoria: FitaiMetaCategoria.corridas,
        unidade: 'corridas',
        fimPeriodo: _fimMes(agora),
        inicioPeriodo: inicioMes,
      ),
    ];
  }

  List<FitaiMetaModel> _metasPassos(
    int passosHoje,
    Map<String, int> metasPassos,
    List<PassosDiariosModel> historico,
    DateTime agora,
  ) {
    final diaria = metasPassos['diaria'] ?? 10000;
    final semanal = metasPassos['semanal'] ?? 70000;
    final mensal = metasPassos['mensal'] ?? 300000;
    final inicioSemana = _inicioSemana(agora);
    final inicioMes = DateTime(agora.year, agora.month);
    final historicoComHoje = _historicoPassosComHoje(
      historico,
      passosHoje,
      diaria,
    );
    final passosSemana = _passosEntre(
      historicoComHoje,
      inicioSemana,
      _fimSemana(agora),
    );
    final passosMes = _passosEntre(historicoComHoje, inicioMes, _fimMes(agora));

    return [
      _meta(
        id: 'passos_diaria',
        titulo: 'Meta diaria',
        descricao: 'Atingir $diaria passos hoje.',
        atual: passosHoje.toDouble(),
        objetivo: diaria.toDouble(),
        categoria: FitaiMetaCategoria.passos,
        unidade: 'passos',
        fimPeriodo: _fimDia(agora),
        inicioPeriodo: _somenteData(agora),
      ),
      _meta(
        id: 'passos_semanal',
        titulo: 'Meta semanal',
        descricao: 'Atingir $semanal passos na semana.',
        atual: passosSemana.toDouble(),
        objetivo: semanal.toDouble(),
        categoria: FitaiMetaCategoria.passos,
        unidade: 'passos',
        fimPeriodo: _fimSemana(agora),
        inicioPeriodo: inicioSemana,
      ),
      _meta(
        id: 'passos_mensal',
        titulo: 'Meta mensal',
        descricao: 'Atingir $mensal passos no mes.',
        atual: passosMes.toDouble(),
        objetivo: mensal.toDouble(),
        categoria: FitaiMetaCategoria.passos,
        unidade: 'passos',
        fimPeriodo: _fimMes(agora),
        inicioPeriodo: inicioMes,
      ),
    ];
  }

  List<FitaiMetaModel> _metasForca(
    List<HistoricoSerieTreinoModel> series,
    DateTime agora,
  ) {
    final inicioSemana = _inicioSemana(agora);
    final inicioMes = DateTime(agora.year, agora.month);
    final seriesSemana = _seriesEntre(series, inicioSemana, _fimSemana(agora));
    final seriesMes = _seriesEntre(series, inicioMes, _fimMes(agora));
    final maiorCarga = series.fold<double>(0, (maior, serie) {
      return serie.peso > maior ? serie.peso : maior;
    });
    final volumeSemana = _volumeTotal(seriesSemana);
    final volumeMes = _volumeTotal(seriesMes);
    final execucoesPorExercicio = _maiorExecucaoExercicio(seriesSemana);

    return [
      _meta(
        id: 'forca_maior_carga',
        titulo: 'Maior carga',
        descricao: 'Buscar uma nova melhor carga.',
        atual: maiorCarga,
        objetivo: maiorCarga <= 0 ? 50 : maiorCarga + 2.5,
        categoria: FitaiMetaCategoria.forca,
        unidade: 'kg',
        fimPeriodo: _fimMes(agora),
        inicioPeriodo: inicioMes,
      ),
      _meta(
        id: 'forca_volume_semanal',
        titulo: 'Volume semanal',
        descricao: 'Somar 10.000 kg de volume na semana.',
        atual: volumeSemana,
        objetivo: math.max(
          10000,
          volumeSemana > 0 ? volumeSemana * 1.05 : 10000,
        ),
        categoria: FitaiMetaCategoria.forca,
        unidade: 'kg',
        fimPeriodo: _fimSemana(agora),
        inicioPeriodo: inicioSemana,
      ),
      _meta(
        id: 'forca_volume_mensal',
        titulo: 'Volume mensal',
        descricao: 'Somar 40.000 kg de volume no mes.',
        atual: volumeMes,
        objetivo: math.max(40000, volumeMes > 0 ? volumeMes * 1.05 : 40000),
        categoria: FitaiMetaCategoria.forca,
        unidade: 'kg',
        fimPeriodo: _fimMes(agora),
        inicioPeriodo: inicioMes,
      ),
      _meta(
        id: 'forca_execucoes_exercicio',
        titulo: 'Execucoes por exercicio',
        descricao: 'Registrar 12 series em um exercicio na semana.',
        atual: execucoesPorExercicio.toDouble(),
        objetivo: 12,
        categoria: FitaiMetaCategoria.forca,
        unidade: 'series',
        fimPeriodo: _fimSemana(agora),
        inicioPeriodo: inicioSemana,
      ),
    ];
  }

  List<FitaiMetaModel> _metasCorpo(Map<String, String> perfil) {
    final pesoAtual = _numero(perfil['peso'] ?? '');
    final pesoAlvo = pesoAtual <= 0 ? 0.0 : math.max(35.0, pesoAtual - 2);
    final progressoPeso = pesoAtual <= 0 || pesoAlvo <= 0
        ? 0.0
        : (1 - ((pesoAtual - pesoAlvo).abs() / 10)).clamp(0, 1).toDouble();

    return [
      FitaiMetaModel(
        id: 'corpo_peso_alvo',
        titulo: 'Peso alvo',
        descricao: 'Meta inicial de composicao corporal.',
        valorAtual: pesoAtual,
        valorObjetivo: pesoAlvo,
        categoria: FitaiMetaCategoria.corpo,
        status: pesoAtual <= 0
            ? FitaiMetaStatus.pendente
            : progressoPeso >= 1
            ? FitaiMetaStatus.concluida
            : FitaiMetaStatus.emAndamento,
        progresso: progressoPeso,
        unidade: 'kg',
        tempoRestante: 'Acompanhe semanalmente',
        estimativa: 'Atualize seu perfil para refinar a estimativa.',
        coachDica: pesoAtual <= 0
            ? 'Informe seu peso no perfil para acompanhar esta meta.'
            : 'Mantenha consistencia em treino, passos e sono para aproximar do alvo.',
      ),
      _metaFutura(
        id: 'corpo_gordura',
        titulo: 'Percentual de gordura',
        descricao: 'Campo preparado para avaliacao futura.',
      ),
      _metaFutura(
        id: 'corpo_massa_muscular',
        titulo: 'Massa muscular',
        descricao: 'Campo preparado para avaliacao futura.',
      ),
    ];
  }

  FitaiMetaModel _meta({
    required String id,
    required String titulo,
    required String descricao,
    required double atual,
    required double objetivo,
    required FitaiMetaCategoria categoria,
    required String unidade,
    required DateTime fimPeriodo,
    required DateTime inicioPeriodo,
  }) {
    final progresso = objetivo <= 0
        ? 0.0
        : (atual / objetivo).clamp(0, 1).toDouble();
    final status = _status(progresso, inicioPeriodo, fimPeriodo);
    final faltam = math.max(0.0, objetivo - atual);

    return FitaiMetaModel(
      id: id,
      titulo: titulo,
      descricao: descricao,
      valorAtual: atual,
      valorObjetivo: objetivo,
      categoria: categoria,
      status: status,
      progresso: progresso,
      unidade: unidade,
      tempoRestante: _tempoRestante(fimPeriodo),
      estimativa: _estimativa(
        atual: atual,
        objetivo: objetivo,
        inicio: inicioPeriodo,
      ),
      coachDica: _coachDica(titulo, faltam, unidade, progresso, status),
    );
  }

  FitaiMetaModel _metaFutura({
    required String id,
    required String titulo,
    required String descricao,
  }) {
    return FitaiMetaModel(
      id: id,
      titulo: titulo,
      descricao: descricao,
      valorAtual: 0,
      valorObjetivo: 0,
      categoria: FitaiMetaCategoria.corpo,
      status: FitaiMetaStatus.pendente,
      progresso: 0,
      unidade: '',
      tempoRestante: 'Campo futuro',
      estimativa: 'Disponivel quando houver dados corporais.',
      coachDica: 'O FitIA ja esta preparado para acompanhar esse dado depois.',
    );
  }

  FitaiMetaStatus _status(double progresso, DateTime inicio, DateTime fim) {
    if (progresso >= 1) return FitaiMetaStatus.concluida;
    if (progresso <= 0) return FitaiMetaStatus.pendente;

    final total = math.max(1, fim.difference(inicio).inSeconds);
    final decorrido = DateTime.now()
        .difference(inicio)
        .inSeconds
        .clamp(0, total);
    final esperado = decorrido / total;

    if (esperado > 0.55 && progresso + 0.18 < esperado) {
      return FitaiMetaStatus.atrasada;
    }

    return FitaiMetaStatus.emAndamento;
  }

  String _coachDica(
    String titulo,
    double faltam,
    String unidade,
    double progresso,
    FitaiMetaStatus status,
  ) {
    if (status == FitaiMetaStatus.concluida) {
      return '$titulo concluida. Excelente consistencia.';
    }
    if (progresso >= 0.8) {
      return 'Voce ja completou ${(progresso * 100).round()}%. Falta pouco.';
    }
    if (faltam <= 2 && unidade != 'passos' && unidade != 'kg') {
      return 'Faltam apenas ${_formatarNumero(faltam)} $unidade.';
    }
    if (status == FitaiMetaStatus.atrasada) {
      return 'Hoje e um bom dia para recuperar ritmo nesta meta.';
    }
    return 'Avance um pouco hoje para manter a meta viva.';
  }

  String _estimativa({
    required double atual,
    required double objetivo,
    required DateTime inicio,
  }) {
    if (objetivo <= 0) return 'Defina dados para estimar.';
    if (atual >= objetivo) return 'Concluida agora.';
    if (atual <= 0) return 'Comece hoje para gerar previsao.';

    final dias = math.max(
      1,
      _somenteData(DateTime.now()).difference(inicio).inDays + 1,
    );
    final mediaDia = atual / dias;
    if (mediaDia <= 0) return 'Sem ritmo suficiente para estimar.';

    final faltam = objetivo - atual;
    final diasRestantes = (faltam / mediaDia).ceil();
    if (diasRestantes <= 1) return 'Possivel concluir hoje.';
    return 'Estimativa: $diasRestantes dias no ritmo atual.';
  }

  String _tempoRestante(DateTime fim) {
    final agora = DateTime.now();
    final diferenca = fim.difference(agora);
    if (diferenca.inHours <= 24) {
      return '${math.max(0, diferenca.inHours)}h restantes';
    }
    return '${math.max(0, diferenca.inDays)} dias restantes';
  }

  double _distanciaTotal(List<CorridaModel> corridas) {
    return corridas.fold<double>(
      0,
      (total, corrida) => total + corrida.distancia,
    );
  }

  List<HistoricoSerieTreinoModel> _seriesEntre(
    List<HistoricoSerieTreinoModel> series,
    DateTime inicio,
    DateTime fim,
  ) {
    return series.where((serie) {
      return !serie.dataHora.isBefore(inicio) && serie.dataHora.isBefore(fim);
    }).toList();
  }

  double _volumeTotal(List<HistoricoSerieTreinoModel> series) {
    return series.fold<double>(0, (total, serie) => total + serie.volume);
  }

  int _maiorExecucaoExercicio(List<HistoricoSerieTreinoModel> series) {
    final contagem = <String, int>{};
    for (final serie in series) {
      final chave = serie.exercicioId.trim().isNotEmpty
          ? serie.exercicioId
          : serie.nomeExercicio;
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    if (contagem.isEmpty) return 0;
    return contagem.values.reduce(math.max);
  }

  List<PassosDiariosModel> _historicoPassosComHoje(
    List<PassosDiariosModel> historico,
    int passosHoje,
    int metaDiaria,
  ) {
    final hoje = _chaveData(DateTime.now());
    final porData = {for (final item in historico) item.data: item};
    porData[hoje] = PassosDiariosModel(
      data: hoje,
      passos: passosHoje,
      metaDiaria: metaDiaria,
      distanciaKm: passosHoje * 0.000762,
      calorias: passosHoje * 0.04,
      tempoAtivoMinutos: (passosHoje / 100).round(),
    );
    return porData.values.toList();
  }

  int _passosEntre(
    List<PassosDiariosModel> historico,
    DateTime inicio,
    DateTime fim,
  ) {
    return historico.fold<int>(0, (total, item) {
      final data = DateTime.tryParse(item.data);
      if (data == null || data.isBefore(inicio) || !data.isBefore(fim)) {
        return total;
      }
      return total + item.passos;
    });
  }

  DateTime? _dataCorrida(CorridaModel corrida) {
    return DateTime.tryParse(corrida.data);
  }

  DateTime _inicioSemana(DateTime data) {
    final dia = _somenteData(data);
    return dia.subtract(Duration(days: dia.weekday - DateTime.monday));
  }

  DateTime _fimSemana(DateTime data) {
    return _inicioSemana(data).add(const Duration(days: 7));
  }

  DateTime _fimMes(DateTime data) {
    return DateTime(data.year, data.month + 1);
  }

  DateTime _fimDia(DateTime data) {
    return _somenteData(data).add(const Duration(days: 1));
  }

  DateTime _somenteData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  String _chaveData(DateTime data) {
    final local = data.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  double _numero(String texto) {
    final match = RegExp(r'(\d+([,.]\d+)?)').firstMatch(texto);
    if (match == null) return 0;
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  }

  String _formatarNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toStringAsFixed(1).replaceAll('.', ',');
  }
}
