import '../models/historico_treino_model.dart';
import '../models/treino_model.dart';

class TreinoDoDiaSelecao {
  final TreinoModel? treino;
  final bool diaDeDescanso;
  final bool treinoConcluidoHoje;
  final bool todosTreinosConcluidosHoje;
  final String titulo;
  final String descricao;
  final String motivo;

  const TreinoDoDiaSelecao({
    required this.treino,
    required this.diaDeDescanso,
    required this.treinoConcluidoHoje,
    required this.todosTreinosConcluidosHoje,
    required this.titulo,
    required this.descricao,
    required this.motivo,
  });
}

class TreinoDoDiaService {
  const TreinoDoDiaService();

  TreinoModel? selecionarTreinoDoDia(
    List<TreinoModel> treinos,
    List<HistoricoTreinoModel> historico,
  ) {
    return selecionarTreinoDoDiaDetalhado(treinos, historico).treino;
  }

  TreinoDoDiaSelecao selecionarTreinoDoDiaDetalhado(
    List<TreinoModel> treinos,
    List<HistoricoTreinoModel>? historico,
  ) {
    if (treinos.isEmpty) {
      return const TreinoDoDiaSelecao(
        treino: null,
        diaDeDescanso: false,
        treinoConcluidoHoje: false,
        todosTreinosConcluidosHoje: false,
        titulo: 'Nenhum treino criado ainda',
        descricao: 'Monte uma ficha manual ou gere uma com IA.',
        motivo: 'Nenhum treino disponível.',
      );
    }

    final concluidosHoje = _nomesTreinosConcluidosHoje(historico);
    final todosConcluidosHoje = treinos.every(
      (treino) => _foiConcluidoHoje(treino, concluidosHoje),
    );

    if (todosConcluidosHoje) {
      final treino = treinos.first;

      return TreinoDoDiaSelecao(
        treino: treino,
        diaDeDescanso: false,
        treinoConcluidoHoje: true,
        todosTreinosConcluidosHoje: true,
        titulo: 'Treino do dia concluído',
        descricao:
            'Você já concluiu todos os treinos disponíveis hoje. Priorize recuperação.',
        motivo:
            'Todos os treinos disponíveis já aparecem no histórico de hoje.',
      );
    }

    final abc = _treinosPorLetra(treinos);
    if (abc.length >= 3) {
      return _selecionarTreinoAbc(treinos, abc, concluidosHoje);
    }

    final pushPullLegs = _treinosPushPullLegs(treinos);
    if (pushPullLegs.length >= 3) {
      return _selecionarTreinoPushPullLegs(
        treinos,
        pushPullLegs,
        concluidosHoje,
      );
    }

    final fullBody = _treinosFullBody(treinos);
    if (fullBody.isNotEmpty) {
      return _selecionarTreinoFullBody(treinos, fullBody, concluidosHoje);
    }

    final treino = _primeiroNaoConcluidoHoje(treinos, concluidosHoje);

    if (treino != null) {
      return TreinoDoDiaSelecao(
        treino: treino,
        diaDeDescanso: false,
        treinoConcluidoHoje: false,
        todosTreinosConcluidosHoje: false,
        titulo: treino.nome,
        descricao: 'Primeiro treino disponível ainda não concluído hoje.',
        motivo: 'Nenhuma divisão semanal foi detectada pelo nome dos treinos.',
      );
    }

    return TreinoDoDiaSelecao(
      treino: treinos.first,
      diaDeDescanso: false,
      treinoConcluidoHoje: true,
      todosTreinosConcluidosHoje: true,
      titulo: 'Treino do dia concluído',
      descricao: 'Você já concluiu os treinos disponíveis hoje.',
      motivo: 'Não há treino pendente para hoje.',
    );
  }

  bool existeTreinoConcluidoHoje(List<HistoricoTreinoModel> historico) {
    final agora = DateTime.now();

    return historico.any((item) {
      final data = item.dataHora.toLocal();

      return data.year == agora.year &&
          data.month == agora.month &&
          data.day == agora.day;
    });
  }

  TreinoDoDiaSelecao _selecionarTreinoAbc(
    List<TreinoModel> treinos,
    Map<String, TreinoModel> porLetra,
    Set<String> concluidosHoje,
  ) {
    final weekday = DateTime.now().weekday;
    String? letra;
    var diaDeDescanso = false;

    switch (weekday) {
      case DateTime.monday:
        letra = 'a';
        break;
      case DateTime.tuesday:
        letra = 'b';
        break;
      case DateTime.wednesday:
        letra = 'c';
        break;
      case DateTime.thursday:
        letra = porLetra.containsKey('d') ? 'd' : null;
        diaDeDescanso = letra == null;
        break;
      case DateTime.friday:
        letra = porLetra.containsKey('e') ? 'e' : 'a';
        break;
      case DateTime.saturday:
        letra = null;
        break;
      case DateTime.sunday:
        diaDeDescanso = true;
        break;
    }

    final treinoAlvo = letra == null ? null : porLetra[letra];
    final treinoPendente =
        treinoAlvo != null && !_foiConcluidoHoje(treinoAlvo, concluidosHoje)
        ? treinoAlvo
        : _primeiroNaoConcluidoHoje(_ordenarAbc(treinos), concluidosHoje);

    if (diaDeDescanso) {
      final treinoRecuperacao =
          _treinoRecuperacao(treinos, concluidosHoje) ?? treinoPendente;

      return TreinoDoDiaSelecao(
        treino: treinoRecuperacao,
        diaDeDescanso: true,
        treinoConcluidoHoje: treinoRecuperacao == null
            ? false
            : _foiConcluidoHoje(treinoRecuperacao, concluidosHoje),
        todosTreinosConcluidosHoje: false,
        titulo: 'Dia de recuperação',
        descricao:
            'A divisão não prevê treino pesado hoje. Foque em recuperação ou movimento leve.',
        motivo: 'Divisão ABC detectada e dia atual sem grupo principal claro.',
      );
    }

    return _selecaoComFallback(
      treino: treinoPendente,
      treinos: treinos,
      concluidosHoje: concluidosHoje,
      motivo: 'Divisão ABC/ABCD/ABCDE detectada pelo nome dos treinos.',
    );
  }

  TreinoDoDiaSelecao _selecionarTreinoPushPullLegs(
    List<TreinoModel> treinos,
    Map<String, TreinoModel> divisao,
    Set<String> concluidosHoje,
  ) {
    final weekday = DateTime.now().weekday;
    String? chave;
    var diaDeDescanso = false;

    switch (weekday) {
      case DateTime.monday:
        chave = 'push';
        break;
      case DateTime.tuesday:
        chave = 'pull';
        break;
      case DateTime.wednesday:
        chave = 'legs';
        break;
      case DateTime.thursday:
        diaDeDescanso = true;
        break;
      case DateTime.friday:
        chave = 'push';
        break;
      case DateTime.saturday:
        chave = divisao.containsKey('pull') ? 'pull' : 'legs';
        break;
      case DateTime.sunday:
        diaDeDescanso = true;
        break;
    }

    final treinoAlvo = chave == null ? null : divisao[chave];
    final ordem = [
      if (divisao['push'] != null) divisao['push']!,
      if (divisao['pull'] != null) divisao['pull']!,
      if (divisao['legs'] != null) divisao['legs']!,
    ];
    final treinoPendente =
        treinoAlvo != null && !_foiConcluidoHoje(treinoAlvo, concluidosHoje)
        ? treinoAlvo
        : _primeiroNaoConcluidoHoje(ordem, concluidosHoje);

    if (diaDeDescanso) {
      final treinoRecuperacao =
          _treinoRecuperacao(treinos, concluidosHoje) ??
          (weekday == DateTime.thursday ? treinoPendente : null);

      return TreinoDoDiaSelecao(
        treino: treinoRecuperacao,
        diaDeDescanso: true,
        treinoConcluidoHoje: treinoRecuperacao == null
            ? false
            : _foiConcluidoHoje(treinoRecuperacao, concluidosHoje),
        todosTreinosConcluidosHoje: false,
        titulo: 'Dia de recuperação',
        descricao:
            'A divisão Push Pull Legs indica recuperação hoje. Se quiser, faça algo leve.',
        motivo: 'Divisão Push Pull Legs detectada.',
      );
    }

    return _selecaoComFallback(
      treino: treinoPendente,
      treinos: treinos,
      concluidosHoje: concluidosHoje,
      motivo: 'Divisão Push Pull Legs detectada pelo nome dos treinos.',
    );
  }

  TreinoDoDiaSelecao _selecionarTreinoFullBody(
    List<TreinoModel> treinos,
    List<TreinoModel> fullBody,
    Set<String> concluidosHoje,
  ) {
    final weekday = DateTime.now().weekday;
    final diaDeTreino =
        weekday == DateTime.monday ||
        weekday == DateTime.wednesday ||
        weekday == DateTime.friday;

    if (!diaDeTreino) {
      final recuperacao = _treinoRecuperacao(treinos, concluidosHoje);

      return TreinoDoDiaSelecao(
        treino: recuperacao,
        diaDeDescanso: true,
        treinoConcluidoHoje: recuperacao == null
            ? false
            : _foiConcluidoHoje(recuperacao, concluidosHoje),
        todosTreinosConcluidosHoje: false,
        titulo: 'Dia de recuperação',
        descricao:
            'A ficha Full Body costuma render melhor com recuperação entre sessões.',
        motivo: 'Divisão Full Body detectada.',
      );
    }

    final treino = _primeiroNaoConcluidoHoje(fullBody, concluidosHoje);

    return _selecaoComFallback(
      treino: treino,
      treinos: fullBody,
      concluidosHoje: concluidosHoje,
      motivo: 'Divisão Full Body detectada para segunda, quarta e sexta.',
    );
  }

  TreinoDoDiaSelecao _selecaoComFallback({
    required TreinoModel? treino,
    required List<TreinoModel> treinos,
    required Set<String> concluidosHoje,
    required String motivo,
  }) {
    if (treino != null) {
      final concluido = _foiConcluidoHoje(treino, concluidosHoje);

      return TreinoDoDiaSelecao(
        treino: treino,
        diaDeDescanso: false,
        treinoConcluidoHoje: concluido,
        todosTreinosConcluidosHoje: false,
        titulo: concluido ? 'Treino do dia concluído' : treino.nome,
        descricao: concluido
            ? 'Você já concluiu esse treino hoje.'
            : 'Treino selecionado automaticamente para hoje.',
        motivo: motivo,
      );
    }

    final fallback = treinos.isEmpty ? null : treinos.first;

    return TreinoDoDiaSelecao(
      treino: fallback,
      diaDeDescanso: false,
      treinoConcluidoHoje: fallback == null
          ? false
          : _foiConcluidoHoje(fallback, concluidosHoje),
      todosTreinosConcluidosHoje: true,
      titulo: 'Treino do dia concluído',
      descricao: 'Você já concluiu os treinos previstos para hoje.',
      motivo: motivo,
    );
  }

  Set<String> _nomesTreinosConcluidosHoje(
    List<HistoricoTreinoModel>? historico,
  ) {
    final agora = DateTime.now();
    final listaHistorico = historico ?? <HistoricoTreinoModel>[];

    return listaHistorico
        .where((item) {
          final data = item.dataHora.toLocal();

          return data.year == agora.year &&
              data.month == agora.month &&
              data.day == agora.day;
        })
        .map((item) => _normalizar(item.nomeTreino))
        .toSet();
  }

  bool _foiConcluidoHoje(TreinoModel treino, Set<String> concluidosHoje) {
    return concluidosHoje.contains(_normalizar(treino.nome));
  }

  TreinoModel? _primeiroNaoConcluidoHoje(
    List<TreinoModel> treinos,
    Set<String> concluidosHoje,
  ) {
    for (final treino in treinos) {
      if (!_foiConcluidoHoje(treino, concluidosHoje)) {
        return treino;
      }
    }

    return null;
  }

  Map<String, TreinoModel> _treinosPorLetra(List<TreinoModel> treinos) {
    final porLetra = <String, TreinoModel>{};

    for (final treino in treinos) {
      final nome = _normalizar(treino.nome);

      for (final letra in const ['a', 'b', 'c', 'd', 'e']) {
        if (nome.startsWith('$letra -') || nome.startsWith('$letra ')) {
          porLetra.putIfAbsent(letra, () => treino);
        }
      }
    }

    return porLetra;
  }

  List<TreinoModel> _ordenarAbc(List<TreinoModel> treinos) {
    final porLetra = _treinosPorLetra(treinos);
    final ordenados = <TreinoModel>[];

    for (final letra in const ['a', 'b', 'c', 'd', 'e']) {
      final treino = porLetra[letra];
      if (treino != null) ordenados.add(treino);
    }

    for (final treino in treinos) {
      if (!ordenados.any((item) => item.id == treino.id)) {
        ordenados.add(treino);
      }
    }

    return ordenados;
  }

  Map<String, TreinoModel> _treinosPushPullLegs(List<TreinoModel> treinos) {
    final divisao = <String, TreinoModel>{};

    for (final treino in treinos) {
      final nome = _normalizar(treino.nome);

      if (nome.startsWith('push')) {
        divisao.putIfAbsent('push', () => treino);
      } else if (nome.startsWith('pull')) {
        divisao.putIfAbsent('pull', () => treino);
      } else if (nome.startsWith('legs')) {
        divisao.putIfAbsent('legs', () => treino);
      }
    }

    return divisao;
  }

  List<TreinoModel> _treinosFullBody(List<TreinoModel> treinos) {
    return treinos.where((treino) {
      final texto = _normalizar('${treino.nome} ${treino.descricao}');

      return texto.contains('full body') || texto.contains('corpo inteiro');
    }).toList();
  }

  TreinoModel? _treinoRecuperacao(
    List<TreinoModel> treinos,
    Set<String> concluidosHoje,
  ) {
    final candidatos = treinos.where((treino) {
      if (_foiConcluidoHoje(treino, concluidosHoje)) return false;

      final texto = _normalizar(
        '${treino.nome} ${treino.descricao} ${treino.objetivo} '
        '${treino.exercicios.map((e) => '${e.nome} ${e.categoria} ${e.tags.join(' ')}').join(' ')}',
      );

      return texto.contains('alongamento') ||
          texto.contains('mobilidade') ||
          texto.contains('cardio') ||
          texto.contains('caminhada') ||
          texto.contains('leve');
    }).toList();

    if (candidatos.isEmpty) return null;

    candidatos.sort((a, b) => a.tempoEstimado.compareTo(b.tempoEstimado));

    return candidatos.first;
  }

  String _normalizar(String texto) {
    var valor = texto.toLowerCase().trim();
    final substituicoes = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'ê': 'e',
      'è': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'Ã¡': 'a',
      'Ã ': 'a',
      'Ã¢': 'a',
      'Ã£': 'a',
      'Ã¤': 'a',
      'Ã©': 'e',
      'Ãª': 'e',
      'Ã¨': 'e',
      'Ã«': 'e',
      'Ã­': 'i',
      'Ã¬': 'i',
      'Ã®': 'i',
      'Ã¯': 'i',
      'Ã³': 'o',
      'Ã²': 'o',
      'Ã´': 'o',
      'Ãµ': 'o',
      'Ã¶': 'o',
      'Ãº': 'u',
      'Ã¹': 'u',
      'Ã»': 'u',
      'Ã¼': 'u',
      'Ã§': 'c',
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }
}
