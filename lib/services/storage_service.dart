import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/exercises/exercise_identity.dart';
import '../core/xp/xp_config.dart';
import '../features/activities/domain/activity_query.dart';
import '../models/agenda_treino_override_model.dart';
import '../models/achievement_model.dart';
import '../models/corrida_model.dart';
import '../models/daily_steps_model.dart';
import '../models/fitai_recorde_model.dart';
import '../models/fitai_memory_model.dart';
import '../models/fitai_notification_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import '../models/passos_diarios_model.dart';
import '../models/progresso_exercicio_model.dart';
import '../models/running_session_model.dart';
import '../models/treino_model.dart';
import 'sync_service.dart';

class XpNivelResultado {
  final int xp;
  final int nivel;
  final int xpGanho;
  final int niveisGanhos;

  const XpNivelResultado({
    required this.xp,
    required this.nivel,
    required this.xpGanho,
    required this.niveisGanhos,
  });

  bool get subiuNivel => niveisGanhos > 0;
}

class StorageService {
  static const int xpPorNivel = 100;
  static const String _runningSessionKey = 'runningSessionActive';
  static const String _dailyStepsHistoryKey = 'dailyStepsHistory';
  static const String _stepsXpAwardedKey = 'stepsXpAwardedDates';
  static const String _activitiesIndexSchemaVersionKey =
      'activitiesIndexSchemaVersion';
  static const String _runningActivityIndexKey = 'activitiesRunningIndexV1';
  static const String _dailyStepsActivityIndexKey =
      'activitiesDailyStepsIndexV1';
  static const int _activitiesIndexSchemaVersion = 2;
  static const String _localActivitiesUserId = DailyStepsModel.defaultUserId;
  static const String _exerciseHistorySchemaVersionKey =
      'exerciseHistorySchemaVersion';
  static const String _exerciseProgressionDecisionsKey =
      'exerciseProgressionDecisions';
  static const int _exerciseHistorySchemaVersion = 1;

  static int xpNecessarioParaNivel(int nivelAtual) {
    return XpConfig.xpParaProximoNivel(nivelAtual);
  }

  static Future<void> salvarPerfilUsuario({
    required String nome,
    required String peso,
    required String altura,
    required String idade,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfilNome', nome);
    await prefs.setString('perfilPeso', peso);
    await prefs.setString('perfilAltura', altura);
    await prefs.setString('perfilIdade', idade);

    unawaited(
      SyncService.instance.syncProfile({
        'nome': nome,
        'peso': peso,
        'altura': altura,
        'idade': idade,
      }),
    );
  }

  static Future<Map<String, String>> carregarPerfilUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'nome': prefs.getString('perfilNome') ?? 'Gabriel',
      'peso': prefs.getString('perfilPeso') ?? '70 kg',
      'altura': prefs.getString('perfilAltura') ?? '175 cm',
      'idade': prefs.getString('perfilIdade') ?? '18',
    };
  }

  /// Le os campos do perfil local sem introduzir valores de demonstracao.
  ///
  /// A leitura com valores padrao acima e mantida por compatibilidade com as
  /// telas legadas. Novos agregados, como o Perfil canonico, precisam distinguir
  /// um campo ausente de um dado efetivamente informado pelo usuario.
  static Future<Map<String, String>> carregarPerfilUsuarioLocal() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'nome': prefs.getString('perfilNome')?.trim() ?? '',
      'peso': prefs.getString('perfilPeso')?.trim() ?? '',
      'altura': prefs.getString('perfilAltura')?.trim() ?? '',
      'idade': prefs.getString('perfilIdade')?.trim() ?? '',
    };
  }

  static Future<void> salvarXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    final xpSeguro = XpConfig.normalizarXp(xp);
    await prefs.setInt('xp', xpSeguro);

    debugPrint("XP SALVO: $xpSeguro");
  }

  static Future<int> carregarXp() async {
    final prefs = await SharedPreferences.getInstance();

    int xp = XpConfig.normalizarXp(prefs.getInt('xp') ?? 0);

    debugPrint("XP CARREGADO: $xp");

    return xp;
  }

  static Future<void> salvarNivel(int nivel) async {
    final prefs = await SharedPreferences.getInstance();
    final nivelSeguro = nivel < 1 ? 1 : nivel;
    await prefs.setInt('nivel', nivelSeguro);

    debugPrint("NIVEL SALVO: $nivelSeguro");
  }

  static Future<int> carregarNivel() async {
    final prefs = await SharedPreferences.getInstance();

    int nivel = prefs.getInt('nivel') ?? 1;
    if (nivel < 1) nivel = 1;

    debugPrint("NIVEL CARREGADO: $nivel");

    return nivel;
  }

  static XpNivelResultado calcularNivelamento({
    required int xp,
    required int nivel,
    int xpGanho = 0,
  }) {
    var xpRestante = XpConfig.normalizarXp(xp);
    var nivelAtual = nivel < 1 ? 1 : nivel;
    var niveisGanhos = 0;

    while (xpRestante >= XpConfig.xpParaProximoNivel(nivelAtual)) {
      xpRestante -= XpConfig.xpParaProximoNivel(nivelAtual);
      nivelAtual++;
      niveisGanhos++;
    }

    return XpNivelResultado(
      xp: xpRestante,
      nivel: nivelAtual,
      xpGanho: xpGanho,
      niveisGanhos: niveisGanhos,
    );
  }

  static Future<XpNivelResultado> salvarXpNivelado({
    required int xp,
    required int nivel,
    int xpGanho = 0,
  }) async {
    final resultado = calcularNivelamento(
      xp: xp,
      nivel: nivel,
      xpGanho: xpGanho,
    );

    await salvarXp(resultado.xp);
    await salvarNivel(resultado.nivel);

    return resultado;
  }

  static Future<XpNivelResultado> adicionarXp(int xpGanho) async {
    final xpAtual = await carregarXp();
    final nivelAtual = await carregarNivel();
    final ganhoSeguro = XpConfig.normalizarGanho(xpGanho);

    return salvarXpNivelado(
      xp: xpAtual + ganhoSeguro,
      nivel: nivelAtual,
      xpGanho: ganhoSeguro,
    );
  }

  static Future<void> salvarPrimeiraCorrida(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('primeiraCorrida', valor);
  }

  static Future<bool> carregarPrimeiraCorrida() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('primeiraCorrida') ?? false;
  }

  static Future<void> salvar10Km(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('conquista10Km', valor);
  }

  static Future<bool> carregar10Km() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('conquista10Km') ?? false;
  }

  static Future<void> salvarDistancia(double distancia) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('distancia', distancia);
  }

  static Future<double> carregarDistancia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('distancia') ?? 0.0;
  }

  static Future<void> salvarSegundos(int segundos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('segundos', segundos);
  }

  static Future<int> carregarSegundos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('segundos') ?? 0;
  }

  static Future<void> salvarPassos(int passos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('passos', passos < 0 ? 0 : passos);
  }

  static Future<int> carregarPassos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('passos') ?? 0;
  }

  static Future<void> salvarDailySteps(DailyStepsModel registro) async {
    final atualizados = await salvarDailyStepsHistory([registro]);
    final hoje = _formatarDataChave(DateTime.now());
    DailyStepsModel? registroHoje;

    for (final item in atualizados) {
      if (item.date == hoje) {
        registroHoje = item;
        break;
      }
    }

    if (registroHoje != null) {
      await salvarPassos(registroHoje.steps);
    }
  }

  static Future<List<DailyStepsModel>> salvarDailyStepsHistory(
    List<DailyStepsModel> registros,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final porRegistro = {
      for (final registro in await carregarDailyStepsHistory())
        if (registro.date.trim().isNotEmpty) registro.recordId: registro,
    };

    for (final registro in registros) {
      if (registro.date.trim().isEmpty) continue;

      final existente = porRegistro[registro.recordId];
      porRegistro[registro.recordId] = _reconciliarDailySteps(
        existente,
        registro,
      );
    }

    final atualizados = porRegistro.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    await prefs.setStringList(
      _dailyStepsHistoryKey,
      atualizados.map((item) => jsonEncode(item.toJson())).toList(),
    );

    for (final registro in atualizados) {
      await salvarHistoricoPassos(_dailyStepsToPassosDiarios(registro));
    }

    final hoje = _formatarDataChave(DateTime.now());
    for (final registro in atualizados) {
      if (registro.date == hoje) {
        await salvarPassos(registro.steps);
        break;
      }
    }

    await _refreshActivitiesIndexes(prefs);

    return atualizados;
  }

  static Future<List<DailyStepsModel>> carregarDailyStepsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_dailyStepsHistoryKey) ?? [];
    final porRegistro = <String, DailyStepsModel>{};

    for (final item in lista) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map<String, dynamic>) {
          final registro = DailyStepsModel.fromJson(decoded);
          porRegistro[registro.recordId] = _reconciliarDailySteps(
            porRegistro[registro.recordId],
            registro,
          );
        } else if (decoded is Map) {
          final registro = DailyStepsModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          porRegistro[registro.recordId] = _reconciliarDailySteps(
            porRegistro[registro.recordId],
            registro,
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar passos diarios: $erro");
      }
    }

    if (porRegistro.isEmpty) {
      final legado = await carregarHistoricoPassos();
      for (final registro in legado) {
        final convertido = DailyStepsModel(
          date: registro.data,
          steps: registro.passos,
          goal: registro.metaDiaria,
          source: _normalizarFontePassos(registro.origem),
          recordedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        porRegistro[convertido.recordId] = _reconciliarDailySteps(
          porRegistro[convertido.recordId],
          convertido,
        );
      }
    }

    final historico = porRegistro.values.toList();
    historico.sort((a, b) => b.date.compareTo(a.date));
    return historico;
  }

  /// Remove somente registros identificados por uma fonte específica. É usado
  /// para impedir que dados seed persistidos em debug vazem para builds release.
  static Future<List<DailyStepsModel>> removerDailyStepsPorFonte(
    String source,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizarFontePassos(source);
    final remaining = (await carregarDailyStepsHistory())
        .where((record) => _normalizarFontePassos(record.source) != normalized)
        .toList(growable: false);

    await prefs.setStringList(
      _dailyStepsHistoryKey,
      remaining.map((record) => jsonEncode(record.toJson())).toList(),
    );

    final legacy = await carregarHistoricoPassos();
    final legacyRemaining = legacy
        .where((record) => _normalizarFontePassos(record.origem) != normalized)
        .map((record) => jsonEncode(record.toJson()))
        .toList(growable: false);
    await prefs.setStringList('historicoPassosDiarios', legacyRemaining);

    final today = _formatarDataChave(DateTime.now());
    final todayRecord = remaining.where((record) => record.date == today);
    await salvarPassos(todayRecord.isEmpty ? 0 : todayRecord.first.steps);
    await _refreshActivitiesIndexes(prefs);
    return remaining;
  }

  static Future<void> marcarDailyStepsSincronizado(String date) async {
    final historico = await carregarDailyStepsHistory();
    final agora = DateTime.now();
    await salvarDailyStepsHistory(
      historico.map((registro) {
        if (registro.date != date) return registro;
        return registro.copyWith(
          syncedAt: agora,
          syncStatus: DailyStepsSyncStatus.synced,
          updatedAt: agora,
        );
      }).toList(),
    );
  }

  /// Migra apenas metadados de consulta; historicos existentes nao sao
  /// apagados, copiados para outro banco ou convertidos de forma destrutiva.
  static Future<void> migrarAtividadesIndexadas() async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureActivitiesIndexes(prefs);
  }

  /// Leitura por intervalo para semana, mes e calendario. Apenas registros do
  /// intervalo solicitado sao desserializados apos a consulta ao indice.
  static Future<List<DailyStepsModel>> carregarDailyStepsNoIntervalo({
    required DateTime from,
    required DateTime to,
    String userId = _localActivitiesUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureActivitiesIndexes(prefs);
    final first = _formatarDataChave(from);
    final last = _formatarDataChave(to);
    final entries = _dailyStepsIndexEntries(prefs)
        .where(
          (entry) =>
              entry.userId == userId &&
              entry.date.compareTo(first) >= 0 &&
              entry.date.compareTo(last) <= 0,
        )
        .toList(growable: false);
    return _dailyStepsForIds(prefs, entries.map((entry) => entry.recordId));
  }

  /// Pagina passos por data local em ordem decrescente, sem converter todo o
  /// historico para modelos em memoria.
  static Future<ActivityStoragePage<DailyStepsModel>>
  carregarDailyStepsPaginados({
    ActivityTimelineCursor? cursor,
    int limit = 31,
    String userId = _localActivitiesUserId,
    DailyStepsSyncStatus? syncStatus,
  }) async {
    assert(limit > 0);
    final prefs = await SharedPreferences.getInstance();
    await _ensureActivitiesIndexes(prefs);
    final entries = _dailyStepsIndexEntries(prefs)
        .where((entry) {
          if (entry.userId != userId) {
            return false;
          }
          if (syncStatus != null && entry.syncStatus != syncStatus) {
            return false;
          }
          final occurredAt =
              DateTime.tryParse(entry.date) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return cursor == null ||
              cursor.includesAfter(occurredAt, entry.recordId);
        })
        .toList(growable: false);
    final selected = entries.take(limit + 1).toList(growable: false);
    final visibleEntries = selected.take(limit).toList(growable: false);
    final records = await _dailyStepsForIds(
      prefs,
      visibleEntries.map((entry) => entry.recordId),
    );
    final next = selected.length > visibleEntries.length && records.isNotEmpty
        ? ActivityTimelineCursor(
            occurredAt:
                DateTime.tryParse(visibleEntries.last.date) ??
                DateTime.fromMillisecondsSinceEpoch(0),
            id: visibleEntries.last.recordId,
          )
        : null;
    return ActivityStoragePage(items: records, nextCursor: next);
  }

  static Future<bool> passosMetaDiariaXpConcedido(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final datas = prefs.getStringList(_stepsXpAwardedKey) ?? const <String>[];

    return datas.contains(date);
  }

  static Future<void> marcarPassosMetaDiariaXpConcedido(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final datas = (prefs.getStringList(_stepsXpAwardedKey) ?? const <String>[])
        .toSet();

    datas.add(date);
    await prefs.setStringList(_stepsXpAwardedKey, datas.toList()..sort());
  }

  static Future<void> salvarMetasPassos({
    required int diaria,
    required int semanal,
    required int mensal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('metaPassosDiaria', diaria);
    await prefs.setInt('metaPassosSemanal', semanal);
    await prefs.setInt('metaPassosMensal', mensal);

    unawaited(
      SyncService.instance.syncGoals([
        _metaPassosToJson(
          'meta_passos_diaria',
          'Meta diaria de passos',
          diaria,
        ),
        _metaPassosToJson(
          'meta_passos_semanal',
          'Meta semanal de passos',
          semanal,
        ),
        _metaPassosToJson(
          'meta_passos_mensal',
          'Meta mensal de passos',
          mensal,
        ),
      ]),
    );
  }

  static Future<Map<String, int>> carregarMetasPassos() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'diaria': prefs.getInt('metaPassosDiaria') ?? 10000,
      'semanal': prefs.getInt('metaPassosSemanal') ?? 70000,
      'mensal': prefs.getInt('metaPassosMensal') ?? 300000,
    };
  }

  static Future<void> salvarHistoricoPassos(PassosDiariosModel registro) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('historicoPassosDiarios') ?? [];

    final atualizados = <String>[];
    var substituiu = false;

    for (final item in lista) {
      try {
        final json = jsonDecode(item);
        final existente = json is Map<String, dynamic>
            ? PassosDiariosModel.fromJson(json)
            : PassosDiariosModel.fromJson(Map<String, dynamic>.from(json));

        if (existente.data == registro.data) {
          atualizados.add(jsonEncode(registro.toJson()));
          substituiu = true;
        } else {
          atualizados.add(item);
        }
      } catch (erro) {
        debugPrint("Erro ao atualizar historico de passos: $erro");
      }
    }

    if (!substituiu) {
      atualizados.add(jsonEncode(registro.toJson()));
    }

    await prefs.setStringList('historicoPassosDiarios', atualizados);
  }

  static Future<List<PassosDiariosModel>> carregarHistoricoPassos() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('historicoPassosDiarios') ?? [];
    final historico = <PassosDiariosModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          historico.add(PassosDiariosModel.fromJson(json));
        } else if (json is Map) {
          historico.add(
            PassosDiariosModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar historico de passos: $erro");
      }
    }

    historico.sort((a, b) => b.data.compareTo(a.data));

    return historico;
  }

  static Future<void> salvarFitAIMemory(FitAIMemoryModel memoria) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fitaiMemory', jsonEncode(memoria.toJson()));
  }

  static Future<FitAIMemoryModel?> carregarFitAIMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString('fitaiMemory');

    if (texto == null || texto.trim().isEmpty) return null;

    try {
      final json = jsonDecode(texto);

      if (json is Map<String, dynamic>) {
        return FitAIMemoryModel.fromJson(json);
      }

      if (json is Map) {
        return FitAIMemoryModel.fromJson(Map<String, dynamic>.from(json));
      }
    } catch (erro) {
      debugPrint("Erro ao carregar memoria FITAI: $erro");
    }

    return null;
  }

  static Future<void> limparFitAIMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fitaiMemory');
  }

  /// Persiste uma corrida finalizada sem duplicar o mesmo [CorridaModel.id].
  ///
  /// O retorno informa se a corrida foi inserida pela primeira vez. Isso evita
  /// totais duplicados quando o app e interrompido entre salvar o historico e
  /// limpar a sessao ativa.
  static Future<bool> salvarCorrida(CorridaModel corrida) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList('historicoCorridas') ?? <String>[];
    final index = _indiceCorridaPorId(lista, corrida.id);
    final inserted = index < 0;

    if (inserted) {
      lista.add(jsonEncode(corrida.toJson()));
    } else {
      lista[index] = jsonEncode(corrida.toJson());
    }

    await prefs.setStringList('historicoCorridas', lista);
    await _refreshActivitiesIndexes(prefs);
    if (inserted) {
      await _salvarRecordesCorrida(corrida);
    }
    return inserted;
  }

  /// Atualiza campos locais, como o status de sincronizacao, sem recalcular
  /// totais ou recordes.
  static Future<bool> atualizarCorrida(CorridaModel corrida) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('historicoCorridas') ?? <String>[];
    final index = _indiceCorridaPorId(lista, corrida.id);
    if (index < 0) return false;

    lista[index] = jsonEncode(corrida.toJson());
    await prefs.setStringList('historicoCorridas', lista);
    await _refreshActivitiesIndexes(prefs);
    return true;
  }

  static Future<void> salvarRecordes(List<FitaiRecordeModel> recordes) async {
    final prefs = await SharedPreferences.getInstance();
    final unicos = <String, FitaiRecordeModel>{};

    for (final recorde in recordes) {
      if (recorde.id.trim().isEmpty) continue;
      unicos[recorde.id] = recorde;
    }

    final lista = unicos.values
        .map((recorde) => jsonEncode(recorde.toJson()))
        .toList();

    await prefs.setStringList('fitaiRecordes', lista);

    unawaited(
      SyncService.instance.syncRecords(
        unicos.values.map((recorde) => recorde.toJson()).toList(),
      ),
    );
  }

  static Future<List<FitaiRecordeModel>> carregarRecordes() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('fitaiRecordes') ?? [];
    final recordes = <FitaiRecordeModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          recordes.add(FitaiRecordeModel.fromJson(json));
        } else if (json is Map) {
          recordes.add(
            FitaiRecordeModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar recorde: $erro");
      }
    }

    recordes.sort((a, b) => b.data.compareTo(a.data));
    return recordes;
  }

  static Future<void> salvarRecorde(FitaiRecordeModel recorde) async {
    final recordes = await carregarRecordes();
    final atualizados = recordes.where((item) => item.id != recorde.id).toList()
      ..add(recorde);

    await salvarRecordes(atualizados);
  }

  static Future<bool> salvarRecordeSeMaior(FitaiRecordeModel recorde) async {
    final recordes = await carregarRecordes();
    FitaiRecordeModel? atual;

    for (final item in recordes) {
      if (item.id == recorde.id) {
        atual = item;
        break;
      }
    }

    if (atual != null && recorde.valor <= atual.valor + 0.0001) {
      return false;
    }

    await salvarRecorde(recorde);
    return true;
  }

  static Future<void> _salvarRecordesCorrida(CorridaModel corrida) async {
    final data =
        DateTime.tryParse(corrida.data) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final minutos = corrida.segundos / 60;
    final horas = corrida.segundos <= 0 ? 0.0 : corrida.segundos / 3600;
    final velocidade = horas <= 0 ? 0.0 : corrida.distancia / horas;

    if (corrida.distancia > 0) {
      await salvarRecordeSeMaior(
        FitaiRecordeModel(
          id: 'corrida_distancia',
          titulo: 'Maior distancia corrida',
          descricao: 'Sua maior distancia registrada em uma corrida.',
          categoria: FitaiRecordeCategoria.corridas,
          valor: corrida.distancia,
          unidade: 'km',
          data: data,
        ),
      );
    }

    if (minutos > 0) {
      await salvarRecordeSeMaior(
        FitaiRecordeModel(
          id: 'corrida_tempo',
          titulo: 'Maior tempo correndo',
          descricao: 'Seu maior tempo continuo em uma corrida.',
          categoria: FitaiRecordeCategoria.corridas,
          valor: minutos,
          unidade: 'min',
          data: data,
        ),
      );
    }

    if (velocidade > 0) {
      await salvarRecordeSeMaior(
        FitaiRecordeModel(
          id: 'corrida_velocidade',
          titulo: 'Melhor velocidade media',
          descricao: 'Sua melhor velocidade media registrada.',
          categoria: FitaiRecordeCategoria.corridas,
          valor: velocidade,
          unidade: 'km/h',
          data: data,
        ),
      );
    }
  }

  static Future<void> salvarCorridaIniciada(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('corridaIniciada', valor);
  }

  static Future<bool> carregarCorridaIniciada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('corridaIniciada') ?? false;
  }

  static Future<void> salvarInicioCorridaIso(String? valor) async {
    final prefs = await SharedPreferences.getInstance();

    if (valor == null || valor.trim().isEmpty) {
      await prefs.remove('inicioCorridaIso');
      await prefs.remove('inicioCorrida');
      return;
    }

    await prefs.setString('inicioCorridaIso', valor);
    await prefs.setString('inicioCorrida', valor);
  }

  static Future<String?> carregarInicioCorridaIso() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('inicioCorridaIso') ??
        prefs.getString('inicioCorrida');
  }

  static Future<void> salvarCorridaAtiva({
    required bool corridaIniciada,
    required DateTime? inicioCorrida,
    required int segundos,
    required double distancia,
    required double velocidadeMedia,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await salvarCorridaIniciada(corridaIniciada);
    await prefs.setInt('corridaAtivaSegundos', segundos);
    await prefs.setDouble('corridaAtivaDistancia', distancia);
    await prefs.setDouble('corridaAtivaVelocidadeMedia', velocidadeMedia);
    await prefs.setInt('segundos', segundos);
    await prefs.setDouble('distancia', distancia);
    await prefs.setDouble('velocidadeMedia', velocidadeMedia);

    await salvarInicioCorridaIso(inicioCorrida?.toIso8601String());
  }

  static Future<void> salvarRunningSessionAtiva(
    RunningSessionModel session,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_runningSessionKey, jsonEncode(session.toJson()));
    await salvarCorridaAtiva(
      corridaIniciada: !session.finished,
      inicioCorrida: session.startTime,
      segundos: session.elapsedSeconds,
      distancia: session.distanceKm,
      velocidadeMedia: session.averageSpeed,
    );
  }

  static Future<RunningSessionModel?> carregarRunningSessionAtiva() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_runningSessionKey);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          return RunningSessionModel.fromJson(decoded);
        }

        if (decoded is Map) {
          return RunningSessionModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao restaurar sessao de corrida: $erro");
      }
    }

    final legado = await carregarCorridaAtiva();
    if (legado['corridaIniciada'] != true) return null;

    final inicio =
        DateTime.tryParse(legado['inicioCorrida']?.toString() ?? '') ??
        DateTime.now();
    final elapsed = _intFromStorage(legado['segundos']);
    final distance = _doubleFromStorage(legado['distancia']);
    final averageSpeed = _doubleFromStorage(legado['velocidadeMedia']);

    return RunningSessionModel(
      id: 'run_${inicio.microsecondsSinceEpoch}',
      startTime: inicio,
      elapsedSeconds: elapsed,
      distanceKm: distance,
      averageSpeed: averageSpeed,
      currentSpeed: 0,
      pace: distance > 0 && elapsed > 0 ? (elapsed / 60) / distance : 0,
      calories: null,
      route: const [],
      paused: false,
      finished: false,
      lastUpdatedAt: DateTime.now(),
    );
  }

  static Future<Map<String, dynamic>> carregarCorridaAtiva() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'corridaIniciada': await carregarCorridaIniciada(),
      'inicioCorrida': await carregarInicioCorridaIso(),
      'segundos': prefs.getInt('corridaAtivaSegundos') ?? 0,
      'distancia': prefs.getDouble('corridaAtivaDistancia') ?? 0.0,
      'velocidadeMedia': prefs.getDouble('corridaAtivaVelocidadeMedia') ?? 0.0,
    };
  }

  static Future<void> limparCorridaAtiva() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_runningSessionKey);
    await salvarCorridaIniciada(false);
    await salvarInicioCorridaIso(null);
    await prefs.remove('inicioCorrida');
    await prefs.remove('inicioCorridaIso');
    await prefs.remove('corridaAtivaSegundos');
    await prefs.remove('corridaAtivaDistancia');
    await prefs.remove('corridaAtivaVelocidadeMedia');
    await prefs.setInt('segundos', 0);
    await prefs.setDouble('distancia', 0);
    await prefs.setDouble('velocidadeMedia', 0);
  }

  static Future<List<CorridaModel>> carregarCorridas() async {
    final prefs = await SharedPreferences.getInstance();

    return _corridasDaLista(
      prefs.getStringList('historicoCorridas') ?? const [],
    );
  }

  /// Consulta Corridas em ordem decrescente por data/hora usando um indice
  /// reconstruivel. A lista original continua sendo a fonte unica de dados.
  static Future<ActivityStoragePage<CorridaModel>> carregarCorridasPaginadas({
    ActivityTimelineCursor? cursor,
    int limit = 20,
    String userId = _localActivitiesUserId,
    RunningSyncStatus? syncStatus,
  }) async {
    assert(limit > 0);
    final prefs = await SharedPreferences.getInstance();
    await _ensureActivitiesIndexes(prefs);
    final entries = _runningIndexEntries(prefs)
        .where((entry) {
          if (entry.userId != userId) {
            return false;
          }
          if (syncStatus != null && entry.syncStatus != syncStatus) {
            return false;
          }
          return cursor == null ||
              cursor.includesAfter(entry.occurredAt, entry.id);
        })
        .toList(growable: false);
    final selected = entries.take(limit + 1).toList(growable: false);
    final visibleEntries = selected.take(limit).toList(growable: false);
    final runs = _runsForIds(prefs, visibleEntries.map((entry) => entry.id));
    final next = selected.length > visibleEntries.length && runs.isNotEmpty
        ? ActivityTimelineCursor(
            occurredAt: visibleEntries.last.occurredAt,
            id: visibleEntries.last.id,
          )
        : null;
    return ActivityStoragePage(items: runs, nextCursor: next);
  }

  static Future<List<CorridaModel>> carregarCorridasNoIntervalo({
    required DateTime from,
    required DateTime to,
    String userId = _localActivitiesUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureActivitiesIndexes(prefs);
    final entries = _runningIndexEntries(prefs)
        .where(
          (entry) =>
              entry.userId == userId &&
              !entry.occurredAt.isBefore(from) &&
              !entry.occurredAt.isAfter(to),
        )
        .toList(growable: false);
    return _runsForIds(prefs, entries.map((entry) => entry.id));
  }

  static Future<List<CorridaModel>> carregarCorridasPendentes() async {
    final corridas = await carregarCorridas();
    return corridas
        .where((corrida) => corrida.syncStatus != RunningSyncStatus.synced)
        .toList();
  }

  static Future<void> removerCorrida(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('historicoCorridas') ?? [];

    if (index < 0 || index >= lista.length) return;

    final removida = CorridaModel.fromJson(jsonDecode(lista[index]));
    await _removerCorridaPorId(prefs, removida.id);
  }

  /// Remove por ID para historicos paginados, sem depender da posicao de uma
  /// lista carregada em outra pagina.
  static Future<void> removerCorridaPorId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await _removerCorridaPorId(prefs, id);
  }

  static Future<void> _removerCorridaPorId(
    SharedPreferences prefs,
    String id,
  ) async {
    final lista = prefs.getStringList('historicoCorridas') ?? [];
    final index = _indiceCorridaPorId(lista, id);
    if (index < 0) return;
    final removida = CorridaModel.fromJson(jsonDecode(lista[index]));
    lista.removeAt(index);
    await prefs.setStringList('historicoCorridas', lista);
    await _refreshActivitiesIndexes(prefs);

    final distanciaAtual = prefs.getDouble('distanciaTotal') ?? 0;
    final tempoAtual = prefs.getInt('tempoTotal') ?? 0;
    final totalAtual = prefs.getInt('totalCorridas') ?? 0;

    await prefs.setDouble(
      'distanciaTotal',
      (distanciaAtual - removida.distancia).clamp(0.0, double.infinity),
    );
    await prefs.setInt(
      'tempoTotal',
      (tempoAtual - removida.segundos).clamp(0, tempoAtual),
    );
    await prefs.setInt('totalCorridas', (totalAtual - 1).clamp(0, totalAtual));
  }

  static int _indiceCorridaPorId(List<String> lista, String id) {
    for (var index = 0; index < lista.length; index++) {
      try {
        final decoded = jsonDecode(lista[index]);
        if (decoded is Map && decoded['id']?.toString() == id) return index;
      } catch (error) {
        debugPrint('Erro ao ler corrida salva: $error');
      }
    }
    return -1;
  }

  static List<CorridaModel> _corridasDaLista(List<String> lista) {
    final corridas = <CorridaModel>[];
    for (final item in lista) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          corridas.add(CorridaModel.fromJson(decoded));
        } else if (decoded is Map) {
          corridas.add(
            CorridaModel.fromJson(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (error) {
        debugPrint('Erro ao carregar corrida salva: $error');
      }
    }
    return corridas;
  }

  @Deprecated(
    'Historico de musculacao novo deve ser finalizado pelo journal canonico.',
  )
  static Future<void> salvarHistoricoTreino(
    HistoricoTreinoModel historico,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList("historicoTreinos") ?? [];

    final atualizados = lista.where((item) {
      try {
        final json = jsonDecode(item);
        if (json is Map) return json['id']?.toString() != historico.id;
      } catch (erro) {
        if (kDebugMode) {
          debugPrint('Erro ao comparar historico de treino: $erro');
        }
      }
      return true;
    }).toList();
    atualizados.add(jsonEncode(historico.toJson()));

    await prefs.setStringList("historicoTreinos", atualizados);
  }

  static Future<List<HistoricoTreinoModel>> carregarHistoricoTreinos() async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList("historicoTreinos") ?? [];
    final historico = <HistoricoTreinoModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          historico.add(HistoricoTreinoModel.fromJson(json));
        } else if (json is Map) {
          historico.add(
            HistoricoTreinoModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar historico de treino: $erro");
      }
    }

    historico.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    return historico;
  }

  static Future<void> limparHistoricoTreinos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("historicoTreinos");
  }

  static Future<void> salvarAgendaTreinoOverride(
    AgendaTreinoOverrideModel override,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = await carregarAgendaTreinoOverrides();
    final atualizados =
        overrides.where((item) => item.id != override.id).toList()
          ..add(override);
    final lista = atualizados.map((item) => jsonEncode(item.toJson())).toList();

    await prefs.setStringList('agendaTreinoOverrides', lista);
  }

  static Future<List<AgendaTreinoOverrideModel>>
  carregarAgendaTreinoOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('agendaTreinoOverrides') ?? [];
    final overrides = <AgendaTreinoOverrideModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);
        if (json is Map<String, dynamic>) {
          overrides.add(AgendaTreinoOverrideModel.fromJson(json));
        } else if (json is Map) {
          overrides.add(
            AgendaTreinoOverrideModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (_) {}
    }

    overrides.sort((a, b) => a.data.compareTo(b.data));
    return overrides;
  }

  static Future<void> removerAgendaTreinoOverride(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = await carregarAgendaTreinoOverrides();
    final atualizados = overrides
        .where((item) => item.id != id)
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList('agendaTreinoOverrides', atualizados);
  }

  static Future<void> salvarConquistas(
    List<AchievementModel> conquistas,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = conquistas
        .map((conquista) => jsonEncode(conquista.toJson()))
        .toList();

    await prefs.setStringList("conquistas", lista);
  }

  static Future<List<AchievementModel>> carregarConquistasSalvas() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("conquistas") ?? [];
    final conquistas = <AchievementModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          conquistas.add(AchievementModel.fromJson(json));
        } else if (json is Map) {
          conquistas.add(
            AchievementModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar conquistas: $erro");
      }
    }

    return conquistas;
  }

  @Deprecated(
    'Series novas devem ser registradas pelo journal canonico de treino.',
  )
  static Future<void> salvarHistoricoSerieTreino(
    HistoricoSerieTreinoModel historico,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("historicoSeriesTreino") ?? [];

    final atualizados = lista.where((item) {
      try {
        final json = jsonDecode(item);
        if (json is Map) {
          final atual = HistoricoSerieTreinoModel.fromJson(
            Map<String, dynamic>.from(json),
          );
          final mesmoId = atual.id.isNotEmpty && atual.id == historico.id;
          final mesmaSerie =
              atual.deduplicationKey == historico.deduplicationKey;
          if (mesmoId || mesmaSerie) {
            if (kDebugMode) {
              debugPrint(
                '[ExerciseHistory] Duplicacao de serie evitada: ${historico.chaveExercicio}.',
              );
            }
            return false;
          }
        }
      } catch (erro) {
        debugPrint("Erro ao comparar historico de serie: $erro");
      }

      return true;
    }).toList();

    atualizados.add(jsonEncode(historico.toJson()));

    await prefs.setStringList("historicoSeriesTreino", atualizados);
  }

  static Future<void> salvarHistoricoExercicio(
    HistoricoSerieTreinoModel historico,
  ) async {
    await salvarHistoricoSerieTreino(historico);
  }

  static Future<List<HistoricoSerieTreinoModel>>
  carregarHistoricoSeriesTreino() async {
    await migrateExerciseHistorySchema();
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("historicoSeriesTreino") ?? [];
    final historico = <HistoricoSerieTreinoModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          historico.add(HistoricoSerieTreinoModel.fromJson(json));
        } else if (json is Map) {
          historico.add(
            HistoricoSerieTreinoModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar historico de serie: $erro");
      }
    }

    historico.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    return historico;
  }

  /// Guarda apenas a confirmacao da sugestao para a proxima execucao.
  /// O plano original permanece intacto e a decisao pode ser sincronizada depois.
  static Future<void> salvarDecisaoProgressaoExercicio(
    Map<String, dynamic> decisao,
  ) async {
    final exerciseKey = decisao['exerciseKey']?.toString().trim() ?? '';
    if (exerciseKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final atuais = prefs.getStringList(_exerciseProgressionDecisionsKey) ?? [];
    final atualizados = <String>[];

    for (final item in atuais) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map &&
            decoded['exerciseKey']?.toString().trim() == exerciseKey) {
          continue;
        }
      } catch (_) {
        // Preserva entradas legiveis e substitui somente a decisao do exercicio.
      }
      atualizados.add(item);
    }

    atualizados.add(
      jsonEncode({...decisao, 'acceptedAt': DateTime.now().toIso8601String()}),
    );
    await prefs.setStringList(_exerciseProgressionDecisionsKey, atualizados);
    if (kDebugMode) {
      debugPrint('[ExerciseProgression] Decisao salva para $exerciseKey.');
    }
  }

  static Future<Map<String, dynamic>?> carregarDecisaoProgressaoExercicio(
    String exerciseKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final itens = prefs.getStringList(_exerciseProgressionDecisionsKey) ?? [];

    for (final item in itens.reversed) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map &&
            decoded['exerciseKey']?.toString().trim() == exerciseKey) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        if (kDebugMode) {
          debugPrint('[ExerciseProgression] Decisao local invalida ignorada.');
        }
      }
    }
    return null;
  }

  /// Atualiza apenas a chave derivada de registros antigos, sem apagar dados.
  static Future<void> migrateExerciseHistorySchema() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_exerciseHistorySchemaVersionKey) ?? 0;
    if (version >= _exerciseHistorySchemaVersion) return;

    final raw = prefs.getStringList('historicoSeriesTreino') ?? [];
    var changed = false;
    final updated = <String>[];

    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map) {
          updated.add(item);
          continue;
        }
        final json = Map<String, dynamic>.from(decoded);
        final key = json['exerciseKey']?.toString().trim() ?? '';
        final name = json['nomeExercicio']?.toString() ?? '';
        if (key.isEmpty && name.trim().isNotEmpty) {
          json['exerciseKey'] = ExerciseIdentity.buildExerciseKey(
            exerciseId: json['exercicioId']?.toString(),
            exerciseName: name,
          );
          changed = true;
          updated.add(jsonEncode(json));
        } else {
          updated.add(item);
        }
      } catch (erro) {
        if (kDebugMode) {
          debugPrint('[ExerciseHistory] Registro legado preservado: $erro');
        }
        updated.add(item);
      }
    }

    if (changed) {
      await prefs.setStringList('historicoSeriesTreino', updated);
      if (kDebugMode) {
        debugPrint('[ExerciseHistory] Migracao local executada.');
      }
    }
    await prefs.setInt(
      _exerciseHistorySchemaVersionKey,
      _exerciseHistorySchemaVersion,
    );
  }

  static Future<List<HistoricoSerieTreinoModel>>
  carregarHistoricoSeriesPorTreino(String treinoId) async {
    final historico = await carregarHistoricoSeriesTreino();

    return historico.where((item) => item.treinoId == treinoId).toList();
  }

  static Future<List<HistoricoSerieTreinoModel>>
  carregarHistoricoSeriesExercicio(String idOuNome) async {
    final historico = await carregarHistoricoSeriesTreino();
    final busca = idOuNome.trim();
    final buscaNormalizada = _normalizarNomeExercicio(busca);

    return historico.where((item) {
      final mesmoId =
          busca.isNotEmpty &&
          item.exercicioId.trim().isNotEmpty &&
          item.exercicioId.trim() == busca;
      final mesmoNome =
          _normalizarNomeExercicio(item.nomeExercicio) == buscaNormalizada;

      return mesmoId || mesmoNome;
    }).toList();
  }

  static Future<void> removerHistoricoSerieTreino(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("historicoSeriesTreino") ?? [];

    final atualizados = lista.where((item) {
      try {
        final json = jsonDecode(item);
        if (json is Map<String, dynamic>) {
          return json["id"]?.toString() != id;
        }
        if (json is Map) {
          return json["id"]?.toString() != id;
        }
      } catch (erro) {
        debugPrint("Erro ao remover historico de serie: $erro");
      }

      return true;
    }).toList();

    await prefs.setStringList("historicoSeriesTreino", atualizados);
  }

  static Future<Set<String>> carregarFavoritosExercicios() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("favoritosExercicios") ?? [];

    return lista.toSet();
  }

  static Future<void> salvarFavoritosExercicios(Set<String> favoritos) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = favoritos.where((id) => id.trim().isNotEmpty).toList()
      ..sort();

    await prefs.setStringList("favoritosExercicios", lista);
  }

  static Future<bool> alternarFavoritoExercicio(String exercicioId) async {
    final favoritos = await carregarFavoritosExercicios();

    if (favoritos.contains(exercicioId)) {
      favoritos.remove(exercicioId);
      await salvarFavoritosExercicios(favoritos);
      return false;
    }

    favoritos.add(exercicioId);
    await salvarFavoritosExercicios(favoritos);
    return true;
  }

  static Future<List<String>> carregarNotasExercicio(String idOuNome) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_chaveNotasExercicio(idOuNome)) ??
        const <String>[];
  }

  static Future<void> salvarNotasExercicio(
    String idOuNome,
    List<String> notas,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final limpas = notas
        .map((nota) => nota.trim())
        .where((nota) => nota.isNotEmpty)
        .toList(growable: false);

    await prefs.setStringList(_chaveNotasExercicio(idOuNome), limpas);
  }

  static Future<void> adicionarNotaExercicio(
    String idOuNome,
    String nota,
  ) async {
    final texto = nota.trim();
    if (texto.isEmpty) return;

    final notas = await carregarNotasExercicio(idOuNome);
    await salvarNotasExercicio(idOuNome, [texto, ...notas]);
  }

  static Future<void> editarNotaExercicio(
    String idOuNome,
    int index,
    String nota,
  ) async {
    final texto = nota.trim();
    final notas = await carregarNotasExercicio(idOuNome);

    if (index < 0 || index >= notas.length || texto.isEmpty) return;

    final atualizadas = [...notas];
    atualizadas[index] = texto;
    await salvarNotasExercicio(idOuNome, atualizadas);
  }

  static Future<void> removerNotaExercicio(String idOuNome, int index) async {
    final notas = await carregarNotasExercicio(idOuNome);
    if (index < 0 || index >= notas.length) return;

    final atualizadas = [...notas]..removeAt(index);
    await salvarNotasExercicio(idOuNome, atualizadas);
  }

  static Future<void> salvarProgresso(ProgressoExercicioModel progresso) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("progressosExercicios") ?? [];

    lista.add(jsonEncode(progresso.toJson()));

    await prefs.setStringList("progressosExercicios", lista);
  }

  static Future<List<ProgressoExercicioModel>> carregarProgressos() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("progressosExercicios") ?? [];
    final progressos = <ProgressoExercicioModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          progressos.add(ProgressoExercicioModel.fromJson(json));
        } else if (json is Map) {
          progressos.add(
            ProgressoExercicioModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar progresso de exercicio: $erro");
      }
    }

    progressos.sort((a, b) => b.data.compareTo(a.data));

    return progressos;
  }

  static Future<ProgressoExercicioModel?> carregarUltimoProgresso(
    String nomeExercicio,
  ) async {
    final historico = await carregarHistoricoExercicio<ProgressoExercicioModel>(
      nomeExercicio,
    );

    if (historico.isEmpty) return null;

    return historico.first;
  }

  static Future<List<T>> carregarHistoricoExercicio<T>(String idOuNome) async {
    if (T == HistoricoSerieTreinoModel) {
      final historico = await carregarHistoricoSeriesExercicio(idOuNome);
      return historico.cast<T>();
    }

    final progressos = await carregarProgressos();
    final nomeNormalizado = _normalizarNomeExercicio(idOuNome);

    final historico = progressos.where((progresso) {
      return _normalizarNomeExercicio(progresso.nomeExercicio) ==
          nomeNormalizado;
    }).toList();

    return historico.cast<T>();
  }

  static Future<void> removerProgresso(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final progressos = await carregarProgressos();
    final atualizados = progressos
        .where((progresso) => progresso.id != id)
        .map((progresso) => jsonEncode(progresso.toJson()))
        .toList();

    await prefs.setStringList("progressosExercicios", atualizados);
  }

  static String _normalizarNomeExercicio(String nome) {
    var valor = nome.toLowerCase().trim();
    final substituicoes = {
      "á": "a",
      "à": "a",
      "â": "a",
      "ã": "a",
      "ä": "a",
      "é": "e",
      "ê": "e",
      "è": "e",
      "ë": "e",
      "í": "i",
      "ì": "i",
      "î": "i",
      "ï": "i",
      "ó": "o",
      "ò": "o",
      "ô": "o",
      "õ": "o",
      "ö": "o",
      "ú": "u",
      "ù": "u",
      "û": "u",
      "ü": "u",
      "ç": "c",
      "Ã¡": "a",
      "Ã ": "a",
      "Ã¢": "a",
      "Ã£": "a",
      "Ã¤": "a",
      "Ã©": "e",
      "Ãª": "e",
      "Ã¨": "e",
      "Ã«": "e",
      "Ã­": "i",
      "Ã¬": "i",
      "Ã®": "i",
      "Ã¯": "i",
      "Ã³": "o",
      "Ã²": "o",
      "Ã´": "o",
      "Ãµ": "o",
      "Ã¶": "o",
      "Ãº": "u",
      "Ã¹": "u",
      "Ã»": "u",
      "Ã¼": "u",
      "Ã§": "c",
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }

  static String _chaveNotasExercicio(String idOuNome) {
    final normalizado = _normalizarNomeExercicio(idOuNome)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return 'notasExercicio_${normalizado.isEmpty ? 'sem_nome' : normalizado}';
  }

  // ===============================
  // ESTATÍSTICAS
  // ===============================

  static Future<void> salvarDistanciaTotal(double valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('distanciaTotal', valor);
  }

  static Future<double> carregarDistanciaTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('distanciaTotal') ?? 0;
  }

  static Future<void> salvarTempoTotal(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tempoTotal', valor);
  }

  static Future<int> carregarTempoTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('tempoTotal') ?? 0;
  }

  static Future<void> salvarTotalCorridas(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalCorridas', valor);
  }

  static Future<int> carregarTotalCorridas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('totalCorridas') ?? 0;
  }

  static Future<void> salvarTreino(
    TreinoModel treino, {
    SyncService? syncService,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList("treinos") ?? [];
    final atualizados = lista.where((item) {
      try {
        final json = jsonDecode(item);
        if (json is Map<String, dynamic>) {
          return json["id"]?.toString() != treino.id;
        }
        if (json is Map) {
          return json["id"]?.toString() != treino.id;
        }
      } catch (erro) {
        debugPrint("Erro ao comparar treino salvo: $erro");
      }

      return true;
    }).toList();

    atualizados.add(jsonEncode(treino.toJson()));

    await prefs.setStringList("treinos", atualizados);

    unawaited(
      (syncService ?? SyncService.instance).syncWorkouts([treino.toJson()]),
    );
  }

  static Future<List<TreinoModel>> carregarTreinos() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> lista = prefs.getStringList("treinos") ?? [];

    return lista.map((item) {
      return TreinoModel.fromJson(jsonDecode(item));
    }).toList();
  }

  static Future<void> apagarTreinos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("treinos");
  }

  static Future<List<FitaiNotificationModel>> carregarNotificacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("fitaiNotificacoes") ?? [];
    final notificacoes = <FitaiNotificationModel>[];

    for (final item in lista) {
      try {
        final json = jsonDecode(item);
        if (json is Map<String, dynamic>) {
          notificacoes.add(FitaiNotificationModel.fromJson(json));
        } else if (json is Map) {
          notificacoes.add(
            FitaiNotificationModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (erro) {
        debugPrint("Erro ao carregar notificacao: $erro");
      }
    }

    notificacoes.sort((a, b) => b.data.compareTo(a.data));
    return notificacoes;
  }

  static Future<void> salvarNotificacoes(
    List<FitaiNotificationModel> notificacoes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = notificacoes
        .where((item) => item.id.trim().isNotEmpty)
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList("fitaiNotificacoes", lista);
  }

  static Future<void> salvarNotificacao(
    FitaiNotificationModel notificacao,
  ) async {
    final notificacoes = await carregarNotificacoes();
    final atualizadas = notificacoes
        .where((item) => item.id != notificacao.id)
        .toList();

    atualizadas.add(notificacao);
    await salvarNotificacoes(atualizadas);
  }

  static Future<void> marcarNotificacaoLida(String id) async {
    final notificacoes = await carregarNotificacoes();
    final atualizadas = notificacoes.map((item) {
      if (item.id != id) return item;
      return item.copyWith(lida: true);
    }).toList();

    await salvarNotificacoes(atualizadas);
  }

  static Future<void> marcarTodasNotificacoesLidas() async {
    final notificacoes = await carregarNotificacoes();
    final atualizadas = notificacoes
        .map((item) => item.copyWith(lida: true))
        .toList();

    await salvarNotificacoes(atualizadas);
  }

  static Future<void> excluirNotificacao(String id) async {
    final notificacoes = await carregarNotificacoes();
    final atualizadas = notificacoes.where((item) => item.id != id).toList();

    await salvarNotificacoes(atualizadas);
  }

  static DailyStepsModel _reconciliarDailySteps(
    DailyStepsModel? existente,
    DailyStepsModel recebido,
  ) {
    if (existente == null) return recebido;

    // A versão é a regra principal: edições manuais incrementam a versão e
    // nunca são reduzidas silenciosamente por uma fonte seed ou legada.
    if (recebido.version < existente.version) return existente;
    if (recebido.version == existente.version &&
        _prioridadeFontePassos(recebido.source) <
            _prioridadeFontePassos(existente.source)) {
      return existente;
    }

    final sameVersion = recebido.version == existente.version;
    return recebido.copyWith(
      id: existente.recordId,
      goal: recebido.goal > 0 ? recebido.goal : existente.goal,
      recordedAt: existente.recordedAt.isBefore(recebido.recordedAt)
          ? existente.recordedAt
          : recebido.recordedAt,
      syncedAt: recebido.syncedAt ?? existente.syncedAt,
      syncStatus:
          sameVersion &&
              recebido.syncStatus == DailyStepsSyncStatus.local &&
              existente.syncStatus == DailyStepsSyncStatus.synced
          ? existente.syncStatus
          : recebido.syncStatus,
      updatedAt: recebido.updatedAt.isAfter(existente.updatedAt)
          ? recebido.updatedAt
          : existente.updatedAt,
      version: recebido.version > existente.version
          ? recebido.version
          : existente.version,
    );
  }

  static PassosDiariosModel _dailyStepsToPassosDiarios(
    DailyStepsModel registro,
  ) {
    return PassosDiariosModel(
      data: registro.date,
      passos: registro.steps,
      metaDiaria: registro.goal,
      distanciaKm: registro.estimatedDistanceMeters == null
          ? 0
          : registro.estimatedDistanceMeters! / 1000,
      calorias: registro.estimatedCalories ?? 0,
      tempoAtivoMinutos: 0,
      origem: registro.source,
    );
  }

  static int _prioridadeFontePassos(String source) {
    return switch (_normalizarFontePassos(source)) {
      DailyStepsModel.sourceManual => 4,
      DailyStepsModel.sourceHealthConnect => 3,
      DailyStepsModel.sourceDevice => 3,
      DailyStepsModel.sourceLocal => 2,
      DailyStepsModel.sourceSeed => 1,
      _ => 0,
    };
  }

  static String _normalizarFontePassos(String source) {
    final normalized = source.trim().toLowerCase();
    if (normalized == DailyStepsModel.sourceHealthConnect ||
        normalized == 'healthconnect' ||
        normalized == 'health') {
      return DailyStepsModel.sourceHealthConnect;
    }
    if (normalized == DailyStepsModel.sourceManual) {
      return DailyStepsModel.sourceManual;
    }
    if (normalized == DailyStepsModel.sourceSeed) {
      return DailyStepsModel.sourceSeed;
    }
    if (normalized == DailyStepsModel.sourceDevice) {
      return DailyStepsModel.sourceDevice;
    }

    return DailyStepsModel.sourceLocal;
  }

  static String _formatarDataChave(DateTime data) {
    final local = data.toLocal();
    final mes = local.month.toString().padLeft(2, '0');
    final dia = local.day.toString().padLeft(2, '0');

    return '${local.year}-$mes-$dia';
  }

  static Future<void> _ensureActivitiesIndexes(SharedPreferences prefs) async {
    if (prefs.getInt(_activitiesIndexSchemaVersionKey) ==
        _activitiesIndexSchemaVersion) {
      return;
    }
    await _rebuildActivitiesIndexes(prefs);
  }

  static Future<void> _refreshActivitiesIndexes(SharedPreferences prefs) async {
    try {
      await _rebuildActivitiesIndexes(prefs);
    } catch (error) {
      // O dado principal ja foi salvo. Um proximo read reconstrui o indice.
      debugPrint('Erro ao atualizar indices de Atividades: $error');
      await prefs.remove(_activitiesIndexSchemaVersionKey);
    }
  }

  static Future<void> _rebuildActivitiesIndexes(SharedPreferences prefs) async {
    final runs = _corridasDaLista(
      prefs.getStringList('historicoCorridas') ?? const [],
    );
    final steps = await carregarDailyStepsHistory();
    final runningIndex =
        runs.map(_RunningActivityIndexEntry.fromRun).toList(growable: false)
          ..sort(_RunningActivityIndexEntry.descending);
    final stepsIndex =
        steps
            .map(_DailyStepsActivityIndexEntry.fromRecord)
            .toList(growable: false)
          ..sort(_DailyStepsActivityIndexEntry.descending);
    await prefs.setStringList(
      _runningActivityIndexKey,
      runningIndex.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    await prefs.setStringList(
      _dailyStepsActivityIndexKey,
      stepsIndex.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    await prefs.setInt(
      _activitiesIndexSchemaVersionKey,
      _activitiesIndexSchemaVersion,
    );
  }

  static List<_RunningActivityIndexEntry> _runningIndexEntries(
    SharedPreferences prefs,
  ) {
    final entries = <_RunningActivityIndexEntry>[];
    for (final raw
        in prefs.getStringList(_runningActivityIndexKey) ?? const []) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          entries.add(
            _RunningActivityIndexEntry.fromJson(
              Map<String, dynamic>.from(decoded),
            ),
          );
        }
      } catch (error) {
        debugPrint('Erro ao ler indice de corrida: $error');
      }
    }
    entries.sort(_RunningActivityIndexEntry.descending);
    return entries;
  }

  static List<_DailyStepsActivityIndexEntry> _dailyStepsIndexEntries(
    SharedPreferences prefs,
  ) {
    final entries = <_DailyStepsActivityIndexEntry>[];
    for (final raw
        in prefs.getStringList(_dailyStepsActivityIndexKey) ?? const []) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          entries.add(
            _DailyStepsActivityIndexEntry.fromJson(
              Map<String, dynamic>.from(decoded),
            ),
          );
        }
      } catch (error) {
        debugPrint('Erro ao ler indice de passos: $error');
      }
    }
    entries.sort(_DailyStepsActivityIndexEntry.descending);
    return entries;
  }

  static List<CorridaModel> _runsForIds(
    SharedPreferences prefs,
    Iterable<String> ids,
  ) {
    final wanted = ids.toList(growable: false);
    final byId = <String, CorridaModel>{
      for (final run in _corridasDaLista(
        prefs.getStringList('historicoCorridas') ?? const [],
      ))
        run.id: run,
    };
    return wanted
        .map((id) => byId[id])
        .whereType<CorridaModel>()
        .toList(growable: false);
  }

  static Future<List<DailyStepsModel>> _dailyStepsForIds(
    SharedPreferences prefs,
    Iterable<String> ids,
  ) async {
    final wanted = ids.toList(growable: false);
    if (wanted.isEmpty) {
      return const [];
    }
    final wantedIds = wanted.toSet();
    final stored = prefs.getStringList(_dailyStepsHistoryKey) ?? const [];
    if (stored.isNotEmpty) {
      final records = <String, DailyStepsModel>{};
      for (final raw in stored) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) {
            continue;
          }
          final record = DailyStepsModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          if (wantedIds.contains(record.recordId)) {
            records[record.recordId] = record;
          }
        } catch (error) {
          debugPrint('Erro ao ler passos indexados: $error');
        }
      }
      return wanted
          .map((id) => records[id])
          .whereType<DailyStepsModel>()
          .toList(growable: false);
    }

    // Dados exclusivamente legados ainda passam pela leitura compatível. A
    // migração de índice não converte nem descarta registros existentes.
    final byId = <String, DailyStepsModel>{
      for (final record in await carregarDailyStepsHistory())
        record.recordId: record,
    };
    return wanted
        .map((id) => byId[id])
        .whereType<DailyStepsModel>()
        .toList(growable: false);
  }

  static Map<String, dynamic> _metaPassosToJson(
    String id,
    String titulo,
    int valorObjetivo,
  ) {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': 'Meta configurada localmente no FitIA.',
      'categoria': 'passos',
      'status': 'emAndamento',
      'valorAtual': 0,
      'valorObjetivo': valorObjetivo,
      'unidade': 'passos',
    };
  }

  static int _intFromStorage(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleFromStorage(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}

/// Metadado reconstruivel para consulta de Corridas. O usuario local e usado
/// enquanto a conta autenticada ainda nao fornece um identificador ao storage.
class _RunningActivityIndexEntry {
  const _RunningActivityIndexEntry({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.occurredAt,
    required this.finished,
    required this.syncStatus,
  });

  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime occurredAt;
  final bool finished;
  final RunningSyncStatus syncStatus;

  factory _RunningActivityIndexEntry.fromRun(CorridaModel run) {
    return _RunningActivityIndexEntry(
      id: run.id,
      userId: DailyStepsModel.defaultUserId,
      startedAt:
          DateTime.tryParse(run.startTime)?.toLocal() ??
          DateTime.tryParse(run.data)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      occurredAt:
          DateTime.tryParse(run.endTime ?? run.data)?.toLocal() ??
          DateTime.tryParse(run.data)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      finished: run.finished,
      syncStatus: run.syncStatus,
    );
  }

  factory _RunningActivityIndexEntry.fromJson(Map<String, dynamic> json) {
    return _RunningActivityIndexEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? DailyStepsModel.defaultUserId,
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.tryParse(json['occurredAt']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      occurredAt:
          DateTime.tryParse(json['occurredAt']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      finished: json['finished'] == true,
      syncStatus: RunningSyncStatusStorage.fromStorage(json['syncStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'startedAt': startedAt.toIso8601String(),
    'occurredAt': occurredAt.toIso8601String(),
    'finished': finished,
    'syncStatus': syncStatus.storageValue,
  };

  static int descending(
    _RunningActivityIndexEntry first,
    _RunningActivityIndexEntry second,
  ) {
    final date = second.occurredAt.compareTo(first.occurredAt);
    return date != 0 ? date : second.id.compareTo(first.id);
  }
}

/// Metadado reconstruivel para consulta por usuario/data de Passos.
class _DailyStepsActivityIndexEntry {
  const _DailyStepsActivityIndexEntry({
    required this.recordId,
    required this.userId,
    required this.date,
    required this.syncStatus,
  });

  final String recordId;
  final String userId;
  final String date;
  final DailyStepsSyncStatus syncStatus;

  factory _DailyStepsActivityIndexEntry.fromRecord(DailyStepsModel record) {
    return _DailyStepsActivityIndexEntry(
      recordId: record.recordId,
      userId: record.userId,
      date: record.date,
      syncStatus: record.syncStatus,
    );
  }

  factory _DailyStepsActivityIndexEntry.fromJson(Map<String, dynamic> json) {
    return _DailyStepsActivityIndexEntry(
      recordId: json['recordId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? DailyStepsModel.defaultUserId,
      date: DailyStepsModel.normalizeDateKey(json['date']?.toString() ?? ''),
      syncStatus: DailyStepsSyncStatusStorage.fromStorage(json['syncStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'userId': userId,
    'date': date,
    'syncStatus': syncStatus.storageValue,
  };

  static int descending(
    _DailyStepsActivityIndexEntry first,
    _DailyStepsActivityIndexEntry second,
  ) {
    final dateOrder = second.date.compareTo(first.date);
    return dateOrder != 0
        ? dateOrder
        : second.recordId.compareTo(first.recordId);
  }
}
