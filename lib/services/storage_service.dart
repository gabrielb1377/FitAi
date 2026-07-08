import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/xp/xp_config.dart';
import '../models/agenda_treino_override_model.dart';
import '../models/achievement_model.dart';
import '../models/corrida_model.dart';
import '../models/fitai_memory_model.dart';
import '../models/fitai_notification_model.dart';
import '../models/historico_serie_treino_model.dart';
import '../models/historico_treino_model.dart';
import '../models/passos_diarios_model.dart';
import '../models/progresso_exercicio_model.dart';
import '../models/treino_model.dart';

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
    await prefs.setInt('passos', passos);
  }

  static Future<int> carregarPassos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('passos') ?? 0;
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

  static Future<void> salvarCorrida(CorridaModel corrida) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> lista = prefs.getStringList('historicoCorridas') ?? [];

    lista.add(jsonEncode(corrida.toJson()));

    await prefs.setStringList('historicoCorridas', lista);
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

    List<String> lista = prefs.getStringList('historicoCorridas') ?? [];

    return lista.map((item) {
      return CorridaModel.fromJson(jsonDecode(item));
    }).toList();
  }

  static Future<void> removerCorrida(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('historicoCorridas') ?? [];

    if (index < 0 || index >= lista.length) return;

    final removida = CorridaModel.fromJson(jsonDecode(lista[index]));
    lista.removeAt(index);

    await prefs.setStringList('historicoCorridas', lista);

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

  static Future<void> salvarHistoricoTreino(
    HistoricoTreinoModel historico,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = prefs.getStringList("historicoTreinos") ?? [];

    lista.add(jsonEncode(historico.toJson()));

    await prefs.setStringList("historicoTreinos", lista);
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

  static Future<void> salvarHistoricoSerieTreino(
    HistoricoSerieTreinoModel historico,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList("historicoSeriesTreino") ?? [];

    final atualizados = lista.where((item) {
      try {
        final json = jsonDecode(item);
        if (json is Map<String, dynamic>) {
          return json["id"]?.toString() != historico.id;
        }
        if (json is Map) {
          return json["id"]?.toString() != historico.id;
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

  static Future<void> salvarTreino(TreinoModel treino) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> lista = prefs.getStringList("treinos") ?? [];

    lista.add(jsonEncode(treino.toJson()));

    await prefs.setStringList("treinos", lista);
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
}
