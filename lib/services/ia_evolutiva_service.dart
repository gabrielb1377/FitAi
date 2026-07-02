import '../models/historico_treino_model.dart';
import '../models/treino_model.dart';
import 'storage_service.dart';

class IaEvolutivaRecomendacao {
  final String titulo;
  final String texto;
  final String motivo;
  final String intensidade;
  final TreinoModel? treinoRecomendado;

  const IaEvolutivaRecomendacao({
    required this.titulo,
    required this.texto,
    required this.motivo,
    required this.intensidade,
    this.treinoRecomendado,
  });
}

class IaEvolutivaService {
  IaEvolutivaService._internal();

  static final IaEvolutivaService instance = IaEvolutivaService._internal();

  Future<IaEvolutivaRecomendacao> gerarRecomendacao({
    required List<TreinoModel> treinosDisponiveis,
    List<HistoricoTreinoModel>? historico,
    int? xpAtual,
    int? nivelAtual,
  }) async {
    final historicoBase =
        historico ?? await StorageService.carregarHistoricoTreinos();
    final xp = xpAtual ?? await StorageService.carregarXp();
    final nivel = nivelAtual ?? await StorageService.carregarNivel();
    final historicoOrdenado = [...historicoBase]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    if (historicoOrdenado.isEmpty) {
      final treinoInicial = _escolherTreinoLeve(treinosDisponiveis);

      return IaEvolutivaRecomendacao(
        titulo: 'Primeiro passo inteligente',
        texto: treinoInicial == null
            ? 'Você ainda não tem histórico. Comece com uma ficha ABC ou um treino único para o FitIA aprender seu ritmo.'
            : 'Você ainda não tem histórico. Comece com ${treinoInicial.nome} e use essa sessão para calibrar seu ritmo.',
        motivo: 'Ainda não há treinos finalizados salvos no histórico.',
        intensidade: 'leve',
        treinoRecomendado: treinoInicial,
      );
    }

    final ultimoTreino = historicoOrdenado.first;
    final diasDesdeUltimo = _diasDesde(ultimoTreino.dataHora);
    final frequencia7Dias = _frequenciaNosUltimosDias(historicoOrdenado, 7);
    final concluiuTudoUltimo =
        ultimoTreino.exerciciosTotais > 0 &&
        ultimoTreino.exerciciosConcluidos >= ultimoTreino.exerciciosTotais;

    if (diasDesdeUltimo >= 4) {
      final treinoRetomada =
          _escolherTreinoPorTermos(treinosDisponiveis, const [
            'full body',
            'corpo inteiro',
            'funcional',
          ]) ??
          _escolherTreinoLeve(treinosDisponiveis);

      return IaEvolutivaRecomendacao(
        titulo: 'Retomada com controle',
        texto:
            'Você está há alguns dias sem treinar. Recomendo um treino Full Body leve ou uma sessão curta para retomar a consistência.',
        motivo: 'Último treino registrado há $diasDesdeUltimo dias.',
        intensidade: 'leve',
        treinoRecomendado: treinoRetomada,
      );
    }

    if (frequencia7Dias >= 5) {
      final treinoLeve = _escolherTreinoLeve(
        treinosDisponiveis,
        evitarNome: ultimoTreino.nomeTreino,
      );

      return IaEvolutivaRecomendacao(
        titulo: 'Recuperação também evolui',
        texto:
            'Você treinou bastante nos últimos dias. Hoje vale priorizar um treino leve, mobilidade ou alongamento.',
        motivo: '$frequencia7Dias treinos concluídos nos últimos 7 dias.',
        intensidade: 'leve',
        treinoRecomendado: treinoLeve,
      );
    }

    if (diasDesdeUltimo <= 1 && !concluiuTudoUltimo) {
      final treinoLeve = _escolherTreinoLeve(
        treinosDisponiveis,
        evitarNome: ultimoTreino.nomeTreino,
      );

      return IaEvolutivaRecomendacao(
        titulo: 'Sessão leve recomendada',
        texto:
            'Você treinou recentemente. Faça um treino leve ou alongamento para manter o corpo ativo sem exagerar.',
        motivo:
            'Último treino recente com ${ultimoTreino.exerciciosConcluidos}/${ultimoTreino.exerciciosTotais} exercícios concluídos.',
        intensidade: 'leve',
        treinoRecomendado: treinoLeve,
      );
    }

    if (concluiuTudoUltimo) {
      final proximoTreino = _escolherProximoTreino(
        treinosDisponiveis,
        ultimoTreino.nomeTreino,
      );

      return IaEvolutivaRecomendacao(
        titulo: 'Hora de progredir',
        texto:
            'Você concluiu todos os exercícios do último treino. Na próxima sessão, tente aumentar a intensidade com boa técnica.',
        motivo:
            'Último treino completo: ${ultimoTreino.exerciciosConcluidos}/${ultimoTreino.exerciciosTotais} exercícios.',
        intensidade: nivel >= 5 || xp >= 50 ? 'intenso' : 'moderado',
        treinoRecomendado: proximoTreino,
      );
    }

    final treinoModerado = _escolherProximoTreino(
      treinosDisponiveis,
      ultimoTreino.nomeTreino,
    );

    return IaEvolutivaRecomendacao(
      titulo: 'Consistência em primeiro lugar',
      texto:
          'Hoje é um bom dia para manter a consistência. Escolha um treino confortável e tente concluir mais exercícios que na última sessão.',
      motivo:
          'Frequência recente: $frequencia7Dias treino(s) nos últimos 7 dias.',
      intensidade: 'moderado',
      treinoRecomendado: treinoModerado,
    );
  }

  TreinoModel? _escolherProximoTreino(
    List<TreinoModel> treinos,
    String ultimoNome,
  ) {
    if (treinos.isEmpty) return null;

    for (final treino in treinos) {
      if (_normalizar(treino.nome) != _normalizar(ultimoNome)) {
        return treino;
      }
    }

    return treinos.first;
  }

  TreinoModel? _escolherTreinoLeve(
    List<TreinoModel> treinos, {
    String? evitarNome,
  }) {
    if (treinos.isEmpty) return null;

    final candidatos = treinos.where((treino) {
      if (evitarNome == null) return true;
      return _normalizar(treino.nome) != _normalizar(evitarNome);
    }).toList();

    final base = candidatos.isEmpty ? [...treinos] : candidatos;

    base.sort((a, b) {
      final pesoA = a.tempoEstimado + (a.exercicios.length * 3);
      final pesoB = b.tempoEstimado + (b.exercicios.length * 3);

      return pesoA.compareTo(pesoB);
    });

    return base.first;
  }

  TreinoModel? _escolherTreinoPorTermos(
    List<TreinoModel> treinos,
    List<String> termos,
  ) {
    if (treinos.isEmpty) return null;

    final termosNormalizados = termos.map(_normalizar).toList();

    for (final treino in treinos) {
      final texto = _normalizar(
        '${treino.nome} ${treino.descricao} ${treino.objetivo}',
      );

      if (termosNormalizados.any(texto.contains)) {
        return treino;
      }
    }

    return null;
  }

  int _frequenciaNosUltimosDias(
    List<HistoricoTreinoModel> historico,
    int dias,
  ) {
    final agora = DateTime.now();

    return historico.where((item) {
      final diferenca = agora.difference(item.dataHora.toLocal());

      return !diferenca.isNegative && diferenca.inDays < dias;
    }).length;
  }

  int _diasDesde(DateTime data) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final diaTreino = data.toLocal();
    final dataTreino = DateTime(diaTreino.year, diaTreino.month, diaTreino.day);
    final diferenca = hoje.difference(dataTreino).inDays;

    return diferenca < 0 ? 0 : diferenca;
  }

  String _normalizar(String texto) {
    var valor = texto.toLowerCase().trim();
    final substituicoes = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
      'ã¡': 'a',
      'ã ': 'a',
      'ã¢': 'a',
      'ã£': 'a',
      'ã©': 'e',
      'ãª': 'e',
      'ã­': 'i',
      'ã³': 'o',
      'ã´': 'o',
      'ãµ': 'o',
      'ãº': 'u',
      'ã¼': 'u',
      'ã§': 'c',
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }
}
