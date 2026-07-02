import 'package:flutter/material.dart';

import '../../models/achievement_model.dart';
import '../../models/historico_serie_treino_model.dart';
import '../../models/historico_treino_model.dart';
import '../../services/achievement_service.dart';
import '../../services/insights_service.dart';
import '../../services/storage_service.dart';
import '../../services/streak_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class EvolucaoPage extends StatelessWidget {
  const EvolucaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Dashboard de EvoluÃ§Ã£o")),
      body: FutureBuilder<_EvolucaoDados>(
        future: _carregarDados(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppLoading(message: "Carregando evoluÃ§Ã£o..."),
            );
          }

          final dados = snapshot.data;

          if (dados == null || dados.historicoTreinos.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppEmptyState(
                icon: Icons.auto_graph_rounded,
                title: "Complete seu primeiro treino para ver sua evoluÃ§Ã£o.",
                message:
                    "Quando vocÃª finalizar treinos, seus nÃºmeros aparecem aqui.",
              ),
            );
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              20,
              _horizontalPadding(context),
              32,
            ),
            children: [
              _hero(dados),
              const SizedBox(height: 18),
              _metricasGerais(context, dados),
              const SizedBox(height: 22),
              _secaoTitulo(context, "Insights da IA"),
              const SizedBox(height: 10),
              _insightsIa(dados.insights),
              const SizedBox(height: 22),
              _secaoTitulo(context, "Resumo da semana"),
              const SizedBox(height: 10),
              _resumoSemana(context, dados),
              const SizedBox(height: 22),
              _secaoTitulo(context, "Melhores exercÃ­cios"),
              const SizedBox(height: 10),
              _melhoresExercicios(dados),
              const SizedBox(height: 22),
              _secaoTitulo(context, "Progresso recente"),
              const SizedBox(height: 10),
              _progressoRecente(dados),
            ],
          );
        },
      ),
    );
  }

  Future<_EvolucaoDados> _carregarDados() async {
    final historicoTreinos = await StorageService.carregarHistoricoTreinos();
    final historicoSeries =
        await StorageService.carregarHistoricoSeriesTreino();
    final xpAtual = await StorageService.carregarXp();
    final nivelAtual = await StorageService.carregarNivel();
    final conquistas = await const AchievementService().carregarConquistas();
    final insights = const InsightsService().analisarHistorico(
      historicoTreinos: historicoTreinos,
      historicoSeries: historicoSeries,
    );

    return _EvolucaoDados(
      historicoTreinos: historicoTreinos,
      historicoSeries: historicoSeries,
      xpAtual: xpAtual,
      nivelAtual: nivelAtual,
      conquistas: conquistas,
      insights: insights,
    );
  }

  Widget _hero(_EvolucaoDados dados) {
    return AppPremiumHeader(
      eyebrow: "Dashboard de evolucao",
      title: "Sua evolucao FitIA",
      subtitle:
          "${dados.totalTreinos} treinos concluidos â€¢ Nivel ${dados.nivelAtual}",
      icon: Icons.auto_graph_rounded,
    );
  }

  Widget _metricasGerais(BuildContext context, _EvolucaoDados dados) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 560
            ? (constraints.maxWidth - 24) / 3
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metrica(
              width,
              Icons.fitness_center_rounded,
              "Treinos",
              "${dados.totalTreinos}",
              AppColors.primary,
            ),
            _metrica(
              width,
              Icons.format_list_numbered_rounded,
              "SÃ©ries",
              "${dados.totalSeries}",
              AppColors.accent1,
            ),
            _metrica(
              width,
              Icons.monitor_weight_rounded,
              "Volume",
              _formatarPeso(dados.volumeTotal),
              AppColors.accent2,
            ),
            _metrica(
              width,
              Icons.timer_rounded,
              "Tempo",
              _formatarDuracao(dados.tempoTotalSegundos),
              AppColors.primaryLight,
            ),
            _metrica(
              width,
              Icons.bolt_rounded,
              "XP atual",
              "${dados.xpAtual}",
              AppColors.accent3,
            ),
            _metrica(
              width,
              Icons.emoji_events_rounded,
              "Recordes",
              "${dados.totalRecordes}",
              AppColors.rankOuro,
            ),
            _metrica(
              width,
              Icons.workspace_premium_rounded,
              "Conquistas",
              "${dados.conquistasDesbloqueadas}",
              AppColors.rankPlatina,
            ),
            _metrica(
              width,
              Icons.local_fire_department_rounded,
              "SequÃªncia",
              "${dados.melhorSequencia} dias",
              AppColors.accent2,
            ),
          ],
        );
      },
    );
  }

  Widget _metrica(
    double width,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumoSemana(BuildContext context, _EvolucaoDados dados) {
    final semana = dados.semanaAtual;

    return AppGradientCard(
      child: Column(
        children: [
          _infoRow(
            Icons.fitness_center_rounded,
            "Treinos na semana",
            "${semana.treinos}",
          ),
          _infoRow(
            Icons.monitor_weight_rounded,
            "Volume semanal",
            _formatarPeso(semana.volume),
          ),
          _infoRow(
            Icons.format_list_numbered_rounded,
            "SÃ©ries semanais",
            "${semana.series}",
          ),
          _infoRow(
            Icons.timer_rounded,
            "Tempo semanal",
            _formatarDuracao(semana.tempoSegundos),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _insightsIa(List<InsightEvolucao> insights) {
    if (insights.isEmpty) {
      return AppGradientCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Insights em preparo",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Complete mais alguns treinos para receber insights personalizados.",
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppGradientCard(
      child: Column(
        children: [
          for (var index = 0; index < insights.length; index++)
            _insightItem(insights[index], isLast: index == insights.length - 1),
        ],
      ),
    );
  }

  Widget _insightItem(InsightEvolucao insight, {required bool isLast}) {
    final color = _corInsight(insight.tipo);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withAlpha(180),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconeInsight(insight.icone), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        insight.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      AppChip(
                        label: _labelInsight(insight.tipo),
                        icon: _iconeInsight(insight.icone),
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.descricao,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _melhoresExercicios(_EvolucaoDados dados) {
    return AppGradientCard(
      child: Column(
        children: [
          _infoRow(
            Icons.fitness_center_rounded,
            "Maior carga",
            dados.maiorCarga == null
                ? "Sem dados"
                : "${dados.maiorCarga!.nome} â€¢ ${_formatarNumero(dados.maiorCarga!.valor)} kg",
          ),
          _infoRow(
            Icons.monitor_weight_rounded,
            "Maior volume",
            dados.maiorVolume == null
                ? "Sem dados"
                : "${dados.maiorVolume!.nome} â€¢ ${_formatarPeso(dados.maiorVolume!.valor)}",
          ),
          _infoRow(
            Icons.format_list_numbered_rounded,
            "Mais sÃ©ries",
            dados.maisSeries == null
                ? "Sem dados"
                : "${dados.maisSeries!.nome} â€¢ ${dados.maisSeries!.valor.round()} sÃ©ries",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _progressoRecente(_EvolucaoDados dados) {
    final atual = dados.semanaAtual;
    final anterior = dados.semanaAnterior;

    return AppGradientCard(
      child: Column(
        children: [
          _comparacaoLinha(
            "Treinos",
            atual.treinos.toDouble(),
            anterior.treinos.toDouble(),
          ),
          _comparacaoLinha("Volume", atual.volume, anterior.volume),
          _comparacaoLinha(
            "SÃ©ries",
            atual.series.toDouble(),
            anterior.series.toDouble(),
          ),
          _comparacaoLinha(
            "Tempo",
            atual.tempoSegundos.toDouble(),
            anterior.tempoSegundos.toDouble(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _comparacaoLinha(
    String label,
    double atual,
    double anterior, {
    bool isLast = false,
  }) {
    final variacao = _variacaoPercentual(atual, anterior);
    final indicador = variacao > 2
        ? "â†‘"
        : variacao < -2
        ? "â†“"
        : "â†’";
    final color = variacao > 2
        ? AppColors.primary
        : variacao < -2
        ? AppColors.accent2
        : AppColors.accent1;
    final barra = anterior <= 0 && atual <= 0
        ? 0.0
        : anterior <= 0
        ? 1.0
        : (atual / anterior).clamp(0.0, 1.5) / 1.5;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                "$indicador ${variacao.abs().toStringAsFixed(0)}%",
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: barra.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: color,
              backgroundColor: const Color(0xFF2A2A2A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secaoTitulo(BuildContext context, String titulo) {
    return Text(
      titulo,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    );
  }

  Color _corInsight(InsightTipo tipo) {
    switch (tipo) {
      case InsightTipo.positivo:
        return AppColors.primary;
      case InsightTipo.alerta:
        return AppColors.accent2;
      case InsightTipo.neutro:
        return AppColors.accent1;
    }
  }

  IconData _iconeInsight(String icone) {
    switch (icone) {
      case 'calendar':
        return Icons.event_available_rounded;
      case 'volume':
        return Icons.monitor_weight_rounded;
      case 'series':
        return Icons.format_list_numbered_rounded;
      case 'pr':
        return Icons.emoji_events_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'muscle':
        return Icons.fitness_center_rounded;
      case 'alert':
        return Icons.balance_rounded;
      case 'timer':
        return Icons.timer_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _labelInsight(InsightTipo tipo) {
    switch (tipo) {
      case InsightTipo.positivo:
        return "Positivo";
      case InsightTipo.alerta:
        return "Alerta";
      case InsightTipo.neutro:
        return "Neutro";
    }
  }

  double _variacaoPercentual(double atual, double anterior) {
    if (anterior <= 0 && atual <= 0) return 0;
    if (anterior <= 0) return 100;
    return ((atual - anterior) / anterior) * 100;
  }

  String _formatarPeso(double peso) {
    if (peso >= 1000) {
      return "${_formatarNumero(peso / 1000)} t";
    }

    return "${_formatarNumero(peso)} kg";
  }

  String _formatarNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toStringAsFixed(1).replaceAll(".", ",");
  }

  String _formatarDuracao(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;

    if (horas <= 0) return "${minutos}min";
    if (minutos <= 0) return "${horas}h";

    return "${horas}h ${minutos}min";
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class _EvolucaoDados {
  final List<HistoricoTreinoModel> historicoTreinos;
  final List<HistoricoSerieTreinoModel> historicoSeries;
  final int xpAtual;
  final int nivelAtual;
  final List<AchievementModel> conquistas;
  final List<InsightEvolucao> insights;

  const _EvolucaoDados({
    required this.historicoTreinos,
    required this.historicoSeries,
    required this.xpAtual,
    required this.nivelAtual,
    required this.conquistas,
    required this.insights,
  });

  int get totalTreinos => historicoTreinos.length;

  int get totalSeries {
    if (historicoSeries.isNotEmpty) return historicoSeries.length;
    return historicoTreinos.fold<int>(
      0,
      (total, treino) => total + treino.seriesConcluidas,
    );
  }

  double get volumeTotal {
    final volumeSeries = historicoSeries.fold<double>(
      0,
      (total, serie) => total + serie.volume,
    );
    if (volumeSeries > 0) return volumeSeries;

    return historicoTreinos.fold<double>(
      0,
      (total, treino) => total + treino.volumeTotal,
    );
  }

  int get tempoTotalSegundos {
    return historicoTreinos.fold<int>(
      0,
      (total, treino) => total + treino.tempoSegundos,
    );
  }

  int get totalRecordes {
    return historicoTreinos.fold<int>(
      0,
      (total, treino) => total + treino.recordesBatidos,
    );
  }

  int get conquistasDesbloqueadas {
    return conquistas.where((conquista) => conquista.desbloqueada).length;
  }

  int get melhorSequencia {
    return const StreakService().calcularStreak(historicoTreinos).melhor;
  }

  _SemanaResumo get semanaAtual {
    final inicio = _inicioSemana(DateTime.now());
    final fim = inicio.add(const Duration(days: 7));
    return _semanaEntre(inicio, fim);
  }

  _SemanaResumo get semanaAnterior {
    final inicioAtual = _inicioSemana(DateTime.now());
    final inicioAnterior = inicioAtual.subtract(const Duration(days: 7));
    return _semanaEntre(inicioAnterior, inicioAtual);
  }

  _MelhorExercicio? get maiorCarga {
    if (historicoSeries.isEmpty) return null;

    final melhor = [...historicoSeries]
      ..sort((a, b) => b.peso.compareTo(a.peso));

    return _MelhorExercicio(melhor.first.nomeExercicio, melhor.first.peso);
  }

  _MelhorExercicio? get maiorVolume {
    if (historicoSeries.isEmpty) return null;

    final volumes = <String, double>{};
    final nomes = <String, String>{};

    for (final serie in historicoSeries) {
      final chave = _normalizar(serie.nomeExercicio);
      nomes[chave] = serie.nomeExercicio;
      volumes[chave] = (volumes[chave] ?? 0) + serie.volume;
    }

    final melhor = volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (melhor.isEmpty) return null;
    return _MelhorExercicio(
      nomes[melhor.first.key] ?? melhor.first.key,
      melhor.first.value,
    );
  }

  _MelhorExercicio? get maisSeries {
    if (historicoSeries.isEmpty) return null;

    final series = <String, int>{};
    final nomes = <String, String>{};

    for (final serie in historicoSeries) {
      final chave = _normalizar(serie.nomeExercicio);
      nomes[chave] = serie.nomeExercicio;
      series[chave] = (series[chave] ?? 0) + 1;
    }

    final melhor = series.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (melhor.isEmpty) return null;
    return _MelhorExercicio(
      nomes[melhor.first.key] ?? melhor.first.key,
      melhor.first.value.toDouble(),
    );
  }

  _SemanaResumo _semanaEntre(DateTime inicio, DateTime fim) {
    final treinos = historicoTreinos.where((treino) {
      final data = DateTime(
        treino.dataHora.year,
        treino.dataHora.month,
        treino.dataHora.day,
      );
      return !data.isBefore(inicio) && data.isBefore(fim);
    }).toList();
    final series = historicoSeries.where((serie) {
      final data = DateTime(
        serie.dataHora.year,
        serie.dataHora.month,
        serie.dataHora.day,
      );
      return !data.isBefore(inicio) && data.isBefore(fim);
    }).toList();
    final volumeSeries = series.fold<double>(
      0,
      (total, serie) => total + serie.volume,
    );

    return _SemanaResumo(
      treinos: treinos.length,
      series: series.isNotEmpty
          ? series.length
          : treinos.fold<int>(
              0,
              (total, treino) => total + treino.seriesConcluidas,
            ),
      volume: volumeSeries > 0
          ? volumeSeries
          : treinos.fold<double>(
              0,
              (total, treino) => total + treino.volumeTotal,
            ),
      tempoSegundos: treinos.fold<int>(
        0,
        (total, treino) => total + treino.tempoSegundos,
      ),
    );
  }

  DateTime _inicioSemana(DateTime data) {
    final dia = DateTime(data.year, data.month, data.day);
    return dia.subtract(Duration(days: dia.weekday - DateTime.monday));
  }

  String _normalizar(String texto) {
    return texto.toLowerCase().trim();
  }
}

class _SemanaResumo {
  final int treinos;
  final int series;
  final double volume;
  final int tempoSegundos;

  const _SemanaResumo({
    required this.treinos,
    required this.series,
    required this.volume,
    required this.tempoSegundos,
  });
}

class _MelhorExercicio {
  final String nome;
  final double valor;

  const _MelhorExercicio(this.nome, this.valor);
}
