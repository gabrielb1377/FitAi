import 'package:flutter/material.dart';

import '../../models/historico_treino_model.dart';
import '../../models/progresso_exercicio_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class _MetricData {
  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  double distanciaTotal = 0;
  int tempoTotal = 0;
  int totalCorridas = 0;
  double velocidadeMedia = 0;
  int passosTotais = 0;
  int nivel = 1;
  int xp = 0;
  bool carregando = true;
  List<HistoricoTreinoModel> historicoTreinos = [];
  List<ProgressoExercicioModel> progressosExercicios = [];

  @override
  void initState() {
    super.initState();
    carregarStats();
  }

  Future<void> carregarStats() async {
    final dist = await StorageService.carregarDistanciaTotal();
    final tempo = await StorageService.carregarTempoTotal();
    final corridas = await StorageService.carregarTotalCorridas();
    final passos = await StorageService.carregarPassos();
    final lvl = await StorageService.carregarNivel();
    final xpAtual = await StorageService.carregarXp();
    final historico = await StorageService.carregarHistoricoTreinos();
    final progressos = await StorageService.carregarProgressos();

    if (!mounted) return;

    setState(() {
      distanciaTotal = dist;
      tempoTotal = tempo;
      totalCorridas = corridas;
      passosTotais = passos;
      nivel = lvl;
      xp = xpAtual;
      historicoTreinos = historico;
      progressosExercicios = progressos;
      carregando = false;

      velocidadeMedia = tempo > 0 ? dist / (tempo / 3600) : 0;
    });
  }

  int get totalTreinos => historicoTreinos.length;

  int get tempoTreinosSegundos {
    return historicoTreinos.fold<int>(
      0,
      (total, item) => total + item.tempoSegundos,
    );
  }

  int get caloriasTreinos {
    return historicoTreinos.fold<int>(
      0,
      (total, item) => total + item.caloriasEstimadas,
    );
  }

  int get xpTreinos {
    return historicoTreinos.fold<int>(0, (total, item) => total + item.xpGanho);
  }

  int get exerciciosConcluidos {
    return historicoTreinos.fold<int>(
      0,
      (total, item) => total + item.exerciciosConcluidos,
    );
  }

  int get mediaDuracaoSegundos {
    if (historicoTreinos.isEmpty) return 0;
    return (tempoTreinosSegundos / historicoTreinos.length).round();
  }

  int get totalRegistrosProgresso => progressosExercicios.length;

  ProgressoExercicioModel? get maiorCargaRegistrada {
    if (progressosExercicios.isEmpty) return null;

    return progressosExercicios.reduce(
      (atual, item) => item.peso > atual.peso ? item : atual,
    );
  }

  String get exercicioMaisTreinado {
    if (progressosExercicios.isEmpty) return "Nenhum";

    final contagem = <String, int>{};

    for (final progresso in progressosExercicios) {
      contagem.update(
        progresso.nomeExercicio,
        (valor) => valor + 1,
        ifAbsent: () => 1,
      );
    }

    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entradas.first.key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Estatisticas")),
      body: RefreshIndicator(
        onRefresh: carregarStats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            _horizontalPadding(context),
            20,
            _horizontalPadding(context),
            100,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            if (carregando)
              _loadingCard()
            else ...[
              if (historicoTreinos.isEmpty)
                _estadoVazioTreinos(context)
              else ...[
                _buildResumoTreinos(context),
                const SizedBox(height: 20),
                _buildMetricasTreino(),
              ],
              const SizedBox(height: 20),
              _buildProgressaoCargaCard(),
              const SizedBox(height: 20),
              _buildCorridasCard(context),
              const SizedBox(height: 20),
              _buildContaCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const AppPremiumHeader(
      eyebrow: "Sua evolucao",
      title: "Estatisticas",
      subtitle: "Acompanhe treinos, corridas, progresso de carga e conta.",
      icon: Icons.query_stats_rounded,
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }

  Widget _loadingCard() {
    return const AppLoading(message: "Carregando estatisticas...");
  }

  Widget _estadoVazioTreinos(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.insights_rounded,
      title: "Nenhum treino finalizado ainda",
      message:
          "Finalize um treino para liberar tempo total, XP, calorias e media de duracao.",
    );
  }

  Widget _buildResumoTreinos(BuildContext context) {
    return AppCard(
      gradient: AppColors.gradientPrimary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(26),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.query_stats_rounded,
              color: Colors.black,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TREINOS",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$totalTreinos sessoes concluidas",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${_formatarTempo(tempoTreinosSegundos)} treinando no historico",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasTreino() {
    final metricas = [
      _MetricData(
        titulo: "Total de treinos",
        valor: "$totalTreinos",
        icon: Icons.fitness_center_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        titulo: "Tempo total",
        valor: _formatarTempo(tempoTreinosSegundos),
        icon: Icons.timer_rounded,
        color: AppColors.accent1,
      ),
      _MetricData(
        titulo: "Calorias",
        valor: "$caloriasTreinos kcal",
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accent2,
      ),
      _MetricData(
        titulo: "XP de treinos",
        valor: "+$xpTreinos",
        icon: Icons.bolt_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        titulo: "Media de duracao",
        valor: _formatarTempo(mediaDuracaoSegundos),
        icon: Icons.speed_rounded,
        color: AppColors.accent3,
      ),
      _MetricData(
        titulo: "Exercicios concluidos",
        valor: "$exerciciosConcluidos",
        icon: Icons.check_circle_rounded,
        color: AppColors.accent1,
      ),
    ];

    return _metricGrid(metricas);
  }

  Widget _buildProgressaoCargaCard() {
    final maiorCarga = maiorCargaRegistrada;
    final metricas = [
      _MetricData(
        titulo: "Maior carga registrada",
        valor: maiorCarga == null
            ? "0 kg"
            : "${_formatarPeso(maiorCarga.peso)} kg",
        icon: Icons.fitness_center_rounded,
        color: AppColors.accent2,
      ),
      _MetricData(
        titulo: "Exercicio mais treinado",
        valor: exercicioMaisTreinado,
        icon: Icons.repeat_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        titulo: "Registros de progresso",
        valor: "$totalRegistrosProgresso",
        icon: Icons.trending_up_rounded,
        color: AppColors.accent1,
      ),
    ];

    return AppSection(
      title: "Progressao de cargas",
      child: _metricGrid(metricas),
    );
  }

  Widget _metricGrid(List<_MetricData> metricas) {
    return AppMetricWrap(
      children: [
        for (final metrica in metricas)
          AppMetricCard(
            label: metrica.titulo,
            value: metrica.valor,
            icon: metrica.icon,
            color: metrica.color,
          ),
      ],
    );
  }

  Widget _buildCorridasCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CORRIDAS E PASSOS",
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 14),
          _resumoLinha(
            icon: Icons.directions_run_rounded,
            label: "Distancia total",
            value: "${distanciaTotal.toStringAsFixed(2)} km",
            color: AppColors.accent2,
          ),
          _resumoLinha(
            icon: Icons.timer_rounded,
            label: "Tempo total",
            value: _formatarTempo(tempoTotal),
            color: AppColors.accent1,
          ),
          _resumoLinha(
            icon: Icons.flag_rounded,
            label: "Corridas",
            value: "$totalCorridas",
            color: AppColors.primary,
          ),
          _resumoLinha(
            icon: Icons.speed_rounded,
            label: "Velocidade media",
            value: "${velocidadeMedia.toStringAsFixed(2)} km/h",
            color: AppColors.accent3,
          ),
          _resumoLinha(
            icon: Icons.directions_walk_rounded,
            label: "Passos",
            value: "$passosTotais",
            color: AppColors.accent1,
            ultimo: true,
          ),
        ],
      ),
    );
  }

  Widget _buildContaCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NIVEL ATUAL",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  "Nivel $nivel",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          Text(
            "$xp XP",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumoLinha({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool ultimo = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarTempo(int segundos) {
    if (segundos <= 0) return "0 min";
    if (segundos < 60) return "<1 min";

    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;

    if (horas > 0) {
      return "${horas}h ${minutos}min";
    }

    return "${minutos}min";
  }

  String _formatarPeso(double peso) {
    if (peso == peso.roundToDouble()) return peso.round().toString();
    return peso.toStringAsFixed(1).replaceAll(".", ",");
  }
}
