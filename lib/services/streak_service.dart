import '../models/historico_treino_model.dart';

class StreakResumo {
  final int atual;
  final int melhor;
  final bool treinouHoje;

  const StreakResumo({
    required this.atual,
    required this.melhor,
    required this.treinouHoje,
  });
}

class StreakService {
  const StreakService();

  StreakResumo calcularStreak(List<HistoricoTreinoModel> historico) {
    if (historico.isEmpty) {
      return const StreakResumo(atual: 0, melhor: 0, treinouHoje: false);
    }

    final diasTreinados = historico
        .map((item) => _chaveData(item.dataHora.toLocal()))
        .toSet();
    final hoje = _somenteData(DateTime.now());
    final ontem = hoje.subtract(const Duration(days: 1));
    final treinouHoje = diasTreinados.contains(_chaveData(hoje));
    final inicioStreak = treinouHoje ? hoje : ontem;
    var streakAtual = 0;
    var cursor = inicioStreak;

    while (diasTreinados.contains(_chaveData(cursor))) {
      streakAtual++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final diasOrdenados = diasTreinados.map(_dataDaChave).toList()..sort();
    var melhorStreak = 0;
    var sequencia = 0;
    DateTime? anterior;

    for (final dia in diasOrdenados) {
      if (anterior == null || dia.difference(anterior).inDays == 1) {
        sequencia++;
      } else {
        sequencia = 1;
      }

      if (sequencia > melhorStreak) {
        melhorStreak = sequencia;
      }

      anterior = dia;
    }

    return StreakResumo(
      atual: streakAtual,
      melhor: melhorStreak,
      treinouHoje: treinouHoje,
    );
  }

  int treinosNaSemana(List<HistoricoTreinoModel> historico) {
    final inicio = _inicioSemana(DateTime.now());

    return historico.where((item) {
      final data = _somenteData(item.dataHora.toLocal());
      return !data.isBefore(inicio);
    }).length;
  }

  int xpTreinosNaSemana(List<HistoricoTreinoModel> historico) {
    final inicio = _inicioSemana(DateTime.now());

    return historico
        .where((item) {
          final data = _somenteData(item.dataHora.toLocal());
          return !data.isBefore(inicio);
        })
        .fold<int>(0, (total, item) => total + item.xpGanho);
  }

  DateTime _inicioSemana(DateTime data) {
    final dia = _somenteData(data);
    return dia.subtract(Duration(days: dia.weekday - DateTime.monday));
  }

  DateTime _somenteData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  String _chaveData(DateTime data) {
    final local = _somenteData(data);
    return '${local.year}-${local.month}-${local.day}';
  }

  DateTime _dataDaChave(String chave) {
    final partes = chave.split('-');
    if (partes.length != 3) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime(
      int.tryParse(partes[0]) ?? 0,
      int.tryParse(partes[1]) ?? 1,
      int.tryParse(partes[2]) ?? 1,
    );
  }
}
