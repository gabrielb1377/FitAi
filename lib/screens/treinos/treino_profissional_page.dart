import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/progression/progression.dart';
import '../../models/exercicio_model.dart';
import '../../models/historico_serie_treino_model.dart';
import '../../models/historico_treino_model.dart';
import '../../models/progresso_exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../services/progressao_service.dart';
import '../../services/recorde_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import '../../widgets/exercicio_gif_viewer.dart';

class TreinoProfissionalPage extends StatefulWidget {
  final TreinoModel treino;
  final Future<void> Function()? onXpAtualizado;

  const TreinoProfissionalPage({
    super.key,
    required this.treino,
    this.onXpAtualizado,
  });

  @override
  State<TreinoProfissionalPage> createState() => _TreinoProfissionalPageState();
}

class _TreinoProfissionalPageState extends State<TreinoProfissionalPage> {
  static const int _totalSeries = 3;
  static const int _descansoPadrao = 60;

  final pesoController = TextEditingController(text: "0");
  final repeticoesController = TextEditingController(text: "10");
  final descansoController = TextEditingController(text: "$_descansoPadrao");

  final Map<int, Set<int>> seriesConcluidas = {};
  final Map<String, _SerieExecutada> seriesExecutadas = {};
  final Map<String, ResultadoRecorde> recordesPorSerie = {};
  final String sessaoTreinoId =
      "sessao_${DateTime.now().microsecondsSinceEpoch}";
  final ProgressaoService progressaoService = const ProgressaoService();
  final RecordeService recordeService = const RecordeService();

  Timer? treinoTimer;
  Timer? descansoTimer;
  ProgressaoSugestao? progressaoAtual;
  int indiceAtual = 0;
  int segundos = 0;
  int descansoTotal = 0;
  int descansoRestante = 0;
  bool avancarAoFimDoDescanso = false;
  bool finalizando = false;

  List<ExercicioModel> get exercicios => widget.treino.exercicios;

  ExercicioModel? get exercicioAtual {
    if (exercicios.isEmpty) return null;
    return exercicios[indiceAtual.clamp(0, exercicios.length - 1)];
  }

  Set<int> get _seriesAtual {
    return seriesConcluidas.putIfAbsent(indiceAtual, () => <int>{});
  }

  int get exerciciosConcluidos {
    var total = 0;
    for (var index = 0; index < exercicios.length; index++) {
      if ((seriesConcluidas[index] ?? const <int>{}).length >= _totalSeries) {
        total++;
      }
    }
    return total;
  }

  int get totalSeriesConcluidas {
    return seriesConcluidas.values.fold<int>(
      0,
      (total, series) => total + series.length,
    );
  }

  double get volumeTotalEstimado {
    var total = 0.0;

    for (final entrada in seriesConcluidas.entries) {
      for (final serieIndex in entrada.value) {
        final serie = seriesExecutadas[_serieId(entrada.key, serieIndex)];
        if (serie != null) total += serie.volume;
      }
    }

    return total;
  }

  int get recordesBatidos {
    return recordesPorSerie.values.fold<int>(
      0,
      (total, resultado) => total + resultado.tipos.length,
    );
  }

  double get progresso {
    if (exercicios.isEmpty) return 0;
    return (indiceAtual + 1) / exercicios.length;
  }

  String get tempoFormatado {
    final minutos = segundos ~/ 60;
    final segundo = segundos % 60;
    return "${minutos.toString().padLeft(2, "0")}:${segundo.toString().padLeft(2, "0")}";
  }

  int get xpGanho => ProgressionRules.workoutCompletionXp;

  int get caloriasEstimadas {
    final concluidos = <ExercicioModel>[];
    for (var index = 0; index < exercicios.length; index++) {
      if ((seriesConcluidas[index] ?? const <int>{}).length >= _totalSeries) {
        concluidos.add(exercicios[index]);
      }
    }

    final base = concluidos.isEmpty ? exercicios : concluidos;
    final calorias = base
        .map((exercicio) => exercicio.caloriasHora)
        .where((valor) => valor > 0)
        .toList();

    if (calorias.isEmpty) return 0;

    final media = calorias.reduce((a, b) => a + b) / calorias.length;
    final minutosPorExercicio = exercicios.isEmpty
        ? 0.0
        : widget.treino.tempoEstimado / exercicios.length;
    final horas = segundos > 0
        ? segundos / 3600
        : (minutosPorExercicio * exerciciosConcluidos) / 60;

    return (media * horas).round();
  }

  @override
  void initState() {
    super.initState();
    _iniciarCronometro();
    _carregarUltimoProgresso();
  }

  void _iniciarCronometro() {
    treinoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        segundos++;
      });
    });
  }

  Future<void> _carregarUltimoProgresso() async {
    final indiceCarregado = indiceAtual;
    final exercicio = exercicioAtual;
    if (exercicio == null) return;

    setState(() {
      progressaoAtual = null;
    });

    final sugestao = await progressaoService.calcularSugestao(
      exercicio: exercicio,
      metaRepeticoes: 10,
    );
    final progresso = await StorageService.carregarUltimoProgresso(
      exercicio.nome,
    );

    if (!mounted || indiceCarregado != indiceAtual) return;

    setState(() {
      progressaoAtual = sugestao;
      pesoController.text = sugestao.cargaSugerida > 0
          ? _formatarNumero(sugestao.cargaSugerida)
          : progresso == null || progresso.peso <= 0
          ? "0"
          : _formatarNumero(progresso.peso);
      repeticoesController.text = sugestao.repeticoesMax.toString();
      descansoController.text = (progresso?.tempoDescanso ?? _descansoPadrao)
          .toString();
    });
  }

  @override
  void dispose() {
    treinoTimer?.cancel();
    descansoTimer?.cancel();
    pesoController.dispose();
    repeticoesController.dispose();
    descansoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercicio = exercicioAtual;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.treino.nome),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: AppChip(
                label: tempoFormatado,
                icon: Icons.timer_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: exercicio == null
          ? const _TreinoProfissionalVazio()
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 920;
                final horizontal = _horizontalPadding(context);
                final leftColumn = AnimatedSwitcher(
                  duration: AppMotion.normal,
                  switchInCurve: AppMotion.curve,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: Column(
                    key: ValueKey("${exercicio.id}-$indiceAtual"),
                    children: [
                      _gifCard(exercicio),
                      const SizedBox(height: 16),
                      _exercicioHeader(exercicio),
                      const SizedBox(height: 16),
                      _progressaoCard(),
                    ],
                  ),
                );
                final rightColumn = Column(
                  children: [
                    _estatisticasTempoRealCard(),
                    const SizedBox(height: 16),
                    _seriesCard(),
                    const SizedBox(height: 16),
                    _cargaCard(),
                    const SizedBox(height: 16),
                    _descansoCard(),
                    const SizedBox(height: 18),
                    _acoesExecucao(),
                  ],
                );

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 28),
                  children: [
                    _barraSuperiorCard(),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: leftColumn),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: rightColumn),
                        ],
                      )
                    else ...[
                      leftColumn,
                      const SizedBox(height: 16),
                      rightColumn,
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _barraSuperiorCard() {
    final total = exercicios.length;
    final percentual = (progresso.clamp(0.0, 1.0) * 100).round();

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.treino.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Exercício ${indiceAtual + 1} de $total",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(90)),
                ),
                child: Text(
                  "$percentual%",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progresso.clamp(0.0, 1.0).toDouble()),
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: AppColors.primary,
                  backgroundColor: Colors.white.withAlpha(18),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _indicadorExercicios(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "$exerciciosConcluidos/$total exercícios finalizados",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                "$totalSeriesConcluidas séries • +$xpGanho XP",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicadorExercicios() {
    return Row(
      children: [
        for (var index = 0; index < exercicios.length; index++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.normal,
              curve: AppMotion.curve,
              height: 5,
              decoration: BoxDecoration(
                color: index < indiceAtual
                    ? AppColors.primary
                    : index == indiceAtual
                    ? AppColors.accent1
                    : Colors.white.withAlpha(22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (index < exercicios.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }

  Widget _estatisticasTempoRealCard() {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Painel ao vivo",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Atualizado a cada série concluída.",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620
                  ? 3
                  : constraints.maxWidth >= 420
                  ? 2
                  : 1;
              final spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _statTile(
                    width: width,
                    icon: Icons.timer_rounded,
                    label: "Tempo",
                    value: tempoFormatado,
                    color: AppColors.primary,
                  ),
                  _statTile(
                    width: width,
                    icon: Icons.format_list_numbered_rounded,
                    label: "Séries",
                    value: "$totalSeriesConcluidas",
                    color: AppColors.accent1,
                  ),
                  _statTile(
                    width: width,
                    icon: Icons.check_circle_rounded,
                    label: "Exercícios",
                    value: "$exerciciosConcluidos/${exercicios.length}",
                    color: AppColors.primaryLight,
                  ),
                  _statTile(
                    width: width,
                    icon: Icons.monitor_weight_rounded,
                    label: "Volume",
                    value: "${_formatarNumero(volumeTotalEstimado)} kg",
                    color: AppColors.accent2,
                  ),
                  _statTile(
                    width: width,
                    icon: Icons.bolt_rounded,
                    label: "XP ganho",
                    value: "+$xpGanho",
                    color: AppColors.accent3,
                  ),
                  _statTile(
                    width: width,
                    icon: Icons.emoji_events_rounded,
                    label: "Recordes",
                    value: "$recordesBatidos",
                    color: AppColors.rankOuro,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        constraints: const BoxConstraints(minHeight: 94),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(16)),
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
            const SizedBox(height: 2),
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

  Widget _gifCard(ExercicioModel exercicio) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => mostrarGifExercicioTelaCheia(
        context,
        imagem: exercicio.imagem,
        titulo: exercicio.nome,
        subtitulo: exercicio.categoria,
      ),
      child: AppGradientCard(
        padding: EdgeInsets.zero,
        borderRadius: 24,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final altura = constraints.maxWidth >= 620 ? 300.0 : 220.0;

              return ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 320,
                  minHeight: 190,
                ),
                child: SizedBox(
                  height: altura,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.black.withAlpha(35)),
                      _gif(exercicio),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: _overlayPill(
                          icon: Icons.play_circle_outline_rounded,
                          label: "GIF do movimento",
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: _overlayPill(
                          icon: Icons.open_in_full_rounded,
                          label: "Ampliar",
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _overlayPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(112),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gif(ExercicioModel exercicio) {
    final imagem = exercicio.imagem.trim();
    if (imagem.isEmpty) return _gifFallback(exercicio);

    final isNetwork =
        imagem.startsWith("http://") || imagem.startsWith("https://");

    if (isNetwork) {
      return Image.network(
        imagem,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _gifFallback(exercicio),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.contain,
      cacheWidth: 900,
      filterQuality: FilterQuality.low,
      semanticLabel: exercicio.nome,
      errorBuilder: (_, _, _) => _gifFallback(exercicio),
    );
  }

  Widget _gifFallback(ExercicioModel exercicio) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientWorkout),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              exercicio.categoria,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exercicioHeader(ExercicioModel exercicio) {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Center(
                  child: Text(
                    "${indiceAtual + 1}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "EXERCÍCIO ATUAL",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      exercicio.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.hub_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _textoMusculos(exercicio),
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(exercicio.categoria, Icons.category_rounded),
              _chip(exercicio.dificuldade, Icons.trending_up_rounded),
              _chip(
                "Meta ${repeticoesController.text.trim().isEmpty ? "10" : repeticoesController.text.trim()} reps",
                Icons.repeat_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressaoCard() {
    final sugestao = progressaoAtual;

    return AppGradientCard(
      child: sugestao == null
          ? const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Calculando progressão inteligente...",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _progressaoColor(sugestao.tipo).withAlpha(32),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _progressaoIcon(sugestao.tipo),
                        color: _progressaoColor(sugestao.tipo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sugestão para hoje",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _progressaoLabel(sugestao.tipo),
                            style: TextStyle(
                              color: _progressaoColor(sugestao.tipo),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _progressaoLinha(
                  label: "Última execução",
                  value: _ultimaExecucaoTexto(sugestao),
                  subvalue: _ultimaExecucaoData(sugestao),
                ),
                const SizedBox(height: 12),
                _progressaoLinha(
                  label: "Para hoje",
                  value: _sugestaoTexto(sugestao),
                  subvalue: sugestao.motivo,
                ),
              ],
            ),
    );
  }

  Widget _progressaoLinha({
    required String label,
    required String value,
    required String subvalue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subvalue.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subvalue,
              style: const TextStyle(color: Colors.white60, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seriesCard() {
    final concluidas = _seriesAtual.length;

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Séries",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "$concluidas/$_totalSeries concluídas",
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: concluidas / _totalSeries,
              minHeight: 7,
              color: AppColors.primary,
              backgroundColor: Colors.white.withAlpha(18),
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < _totalSeries; index++) ...[
            _serieLinha(index),
            if (index < _totalSeries - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _serieLinha(int index) {
    final concluida = _seriesAtual.contains(index);
    final serieId = _serieId(indiceAtual, index);
    final executada = seriesExecutadas[serieId];
    final bateuRecorde = recordesPorSerie.containsKey(serieId);
    final reps = executada?.repeticoes ?? _parseRepeticoes();
    final peso = executada?.peso ?? _parsePeso();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _alternarSerie(index, !concluida),
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: concluida
              ? AppColors.primary.withAlpha(30)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: concluida ? AppColors.primary : Colors.white.withAlpha(16),
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Container(
                key: ValueKey(concluida),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: concluida ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: concluida ? AppColors.primary : Colors.white38,
                  ),
                ),
                child: Icon(
                  concluida ? Icons.check_rounded : Icons.circle_outlined,
                  color: concluida ? Colors.black : Colors.white54,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Série ${index + 1}",
                        style: TextStyle(
                          color: concluida ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (bateuRecorde) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.rankOuro,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    concluida
                        ? "${_formatarNumero(peso)} kg • $reps reps"
                        : "Toque para registrar esta série",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              concluida ? "Feita" : "$reps reps",
              style: TextStyle(
                color: concluida ? AppColors.primary : Colors.white54,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cargaCard() {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent1.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.accent1),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Carga e meta",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Ajuste antes de registrar a série.",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final ladoALado = constraints.maxWidth >= 430;

              final pesoField = _campoNumero(
                controller: pesoController,
                label: "Peso",
                suffix: "kg",
                icon: Icons.fitness_center_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              );
              final repsField = _campoNumero(
                controller: repeticoesController,
                label: "Repetições",
                suffix: "reps",
                icon: Icons.repeat_rounded,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              );

              if (!ladoALado) {
                return Column(
                  children: [pesoField, const SizedBox(height: 10), repsField],
                );
              }

              return Row(
                children: [
                  Expanded(child: pesoField),
                  const SizedBox(width: 12),
                  Expanded(child: repsField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _campoNumero({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    required TextInputType keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _descansoCard() {
    final descansoAtivo = descansoRestante > 0;
    final progressoDescanso = descansoTotal <= 0
        ? 0.0
        : 1 - (descansoRestante / descansoTotal);

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent2.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: AppColors.accent2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descansoAtivo ? "Descanso ativo" : "Descanso",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descansoAtivo
                          ? "Respire, recupere e prepare a próxima série."
                          : "Defina o intervalo entre séries.",
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: AppMotion.normal,
            switchInCurve: AppMotion.curve,
            switchOutCurve: Curves.easeIn,
            child: descansoAtivo
                ? Column(
                    key: const ValueKey("descanso-ativo"),
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.94, end: 1),
                        duration: AppMotion.normal,
                        curve: AppMotion.curve,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent2.withAlpha(70),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "$descansoRestante",
                                style: const TextStyle(
                                  color: AppColors.accent2,
                                  fontSize: 72,
                                  fontWeight: FontWeight.w900,
                                  height: 0.92,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatarTempo(descansoRestante),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressoDescanso.clamp(0.0, 1.0).toDouble(),
                          minHeight: 10,
                          color: AppColors.accent2,
                          backgroundColor: Colors.white.withAlpha(18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              onPressed: _pularDescanso,
                              icon: Icons.skip_next_rounded,
                              label: "Pular",
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 82,
                            child: AppButton.ghost(
                              onPressed: () => _ajustarDescanso(15),
                              label: "+15s",
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 82,
                            child: AppButton.ghost(
                              onPressed: () => _ajustarDescanso(-15),
                              label: "-15s",
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey("descanso-config"),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: descansoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Descanso",
                                suffixText: "s",
                                prefixIcon: Icon(
                                  Icons.hourglass_bottom_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 132,
                            child: AppButton.secondary(
                              onPressed: _iniciarDescanso,
                              icon: Icons.play_arrow_rounded,
                              label: "Iniciar",
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Padrão de 60s quando nenhum descanso estiver definido.",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _acoesExecucao() {
    final seriesRestantes = _totalSeries - _seriesAtual.length;
    final label = seriesRestantes > 0
        ? "Registrar série ${_seriesAtual.length + 1}"
        : indiceAtual >= exercicios.length - 1
        ? "Finalizar treino"
        : "Próximo exercício";

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          AppButton.primary(
            onPressed: finalizando ? null : _concluirProximaSerie,
            loading: finalizando,
            icon: seriesRestantes > 0
                ? Icons.check_circle_rounded
                : Icons.arrow_forward_rounded,
            label: label,
          ),
          const SizedBox(height: 12),
          _navegacao(),
        ],
      ),
    );
  }

  Widget _navegacao() {
    return Row(
      children: [
        Expanded(
          child: AppButton.ghost(
            onPressed: indiceAtual == 0 ? null : _anterior,
            icon: Icons.chevron_left_rounded,
            label: "Anterior",
            compact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton.secondary(
            onPressed: finalizando ? null : _proximo,
            icon: Icons.chevron_right_rounded,
            label: "Próximo",
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _chip(String texto, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _alternarSerie(int index, bool concluida) async {
    final exercicio = exercicioAtual;
    if (exercicio == null || finalizando) return;

    final jaConcluida = _seriesAtual.contains(index);
    final serieId = _serieId(indiceAtual, index);

    setState(() {
      if (concluida) {
        _seriesAtual.add(index);
      } else {
        _seriesAtual.remove(index);
        seriesExecutadas.remove(serieId);
        recordesPorSerie.remove(serieId);
      }
    });

    if (!concluida && jaConcluida) {
      await _removerDadosSerie(index);
      return;
    }

    if (concluida && !jaConcluida) {
      await _salvarProgressoSerie(exercicio, index);
      if (!mounted) return;
      _iniciarDescanso(avancarAoFinal: _seriesAtual.length >= _totalSeries);
      return;
    }
  }

  Future<void> _concluirProximaSerie() async {
    for (var index = 0; index < _totalSeries; index++) {
      if (!_seriesAtual.contains(index)) {
        await _alternarSerie(index, true);
        return;
      }
    }

    await _avancarOuFinalizar();
  }

  Future<void> _salvarProgressoSerie(
    ExercicioModel exercicio,
    int serieIndex,
  ) async {
    final agora = DateTime.now();
    final serieId = _serieId(indiceAtual, serieIndex);
    final progressoId = "progresso_$serieId";
    final historicoId = "serie_$serieId";
    final peso = _parsePeso();
    final repeticoes = _parseRepeticoes();
    final recorde = await recordeService.detectarRecordes(
      exercicio: exercicio,
      peso: peso,
      repeticoes: repeticoes,
    );

    seriesExecutadas[serieId] = _SerieExecutada(
      peso: peso,
      repeticoes: repeticoes,
    );
    if (recorde.bateuRecorde) {
      recordesPorSerie[serieId] = recorde;
    } else {
      recordesPorSerie.remove(serieId);
    }

    await StorageService.removerProgresso(progressoId);
    await StorageService.salvarProgresso(
      ProgressoExercicioModel(
        id: progressoId,
        nomeExercicio: exercicio.nome,
        peso: peso,
        series: serieIndex + 1,
        repeticoes: repeticoes,
        tempoDescanso: _parseDescanso(),
        observacao: "Plano: ${widget.treino.nome}",
        data: agora,
      ),
    );

    await StorageService.salvarHistoricoSerieTreino(
      HistoricoSerieTreinoModel(
        id: historicoId,
        treinoId: widget.treino.id,
        sessaoTreinoId: sessaoTreinoId,
        nomeTreino: widget.treino.nome,
        exercicioId: exercicio.id,
        nomeExercicio: exercicio.nome,
        serieNumero: serieIndex + 1,
        peso: peso,
        repeticoes: repeticoes,
        dataHora: agora,
      ),
    );

    if (recorde.bateuRecorde && mounted) {
      _mostrarRecorde(recorde);
    }
  }

  Future<void> _removerDadosSerie(int serieIndex) async {
    final serieId = _serieId(indiceAtual, serieIndex);

    await StorageService.removerProgresso("progresso_$serieId");
    await StorageService.removerHistoricoSerieTreino("serie_$serieId");
  }

  void _mostrarRecorde(ResultadoRecorde recorde) {
    final tipos = recorde.tipos.map(_recordeLabel).join(", ");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.rankOuro,
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tipos.isEmpty
                    ? "Novo recorde pessoal!"
                    : "Novo recorde pessoal! $tipos",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _iniciarDescanso({bool avancarAoFinal = false}) {
    descansoTimer?.cancel();
    final total = _parseDescanso();

    setState(() {
      descansoTotal = total;
      descansoRestante = total;
      avancarAoFimDoDescanso = avancarAoFinal;
    });

    descansoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (descansoRestante <= 1) {
        timer.cancel();
        _encerrarDescanso(mostrarMensagem: true, avancarSeNecessario: true);
        return;
      }

      setState(() {
        descansoRestante--;
      });
    });
  }

  void _pularDescanso() {
    _encerrarDescanso(mostrarMensagem: true, avancarSeNecessario: true);
  }

  void _cancelarDescanso() {
    _encerrarDescanso(mostrarMensagem: false, avancarSeNecessario: false);
  }

  void _encerrarDescanso({
    required bool mostrarMensagem,
    required bool avancarSeNecessario,
  }) {
    descansoTimer?.cancel();
    if (!mounted) return;

    final deveAvancar = avancarAoFimDoDescanso;

    setState(() {
      descansoTotal = 0;
      descansoRestante = 0;
      avancarAoFimDoDescanso = false;
    });

    if (mostrarMensagem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.timer_off_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text("Descanso finalizado")),
            ],
          ),
        ),
      );
    }

    if (deveAvancar && avancarSeNecessario) {
      unawaited(_avancarOuFinalizar());
    }
  }

  void _ajustarDescanso(int segundos) {
    if (descansoRestante <= 0) return;

    final novoRestante = (descansoRestante + segundos).clamp(0, 600).toInt();

    if (novoRestante <= 0) {
      _encerrarDescanso(mostrarMensagem: true, avancarSeNecessario: true);
      return;
    }

    setState(() {
      descansoRestante = novoRestante;
      descansoTotal = (descansoTotal + segundos)
          .clamp(novoRestante, 600)
          .toInt();
      descansoController.text = novoRestante.toString();
    });
  }

  Future<void> _avancarOuFinalizar() async {
    if (indiceAtual >= exercicios.length - 1) {
      await _finalizarTreino();
      return;
    }

    _cancelarDescanso();

    setState(() {
      indiceAtual++;
    });

    await _carregarUltimoProgresso();
  }

  void _anterior() {
    if (indiceAtual == 0) return;

    _cancelarDescanso();
    setState(() {
      indiceAtual--;
    });
    _carregarUltimoProgresso();
  }

  Future<void> _proximo() async {
    if (indiceAtual >= exercicios.length - 1) {
      if (_seriesAtual.length >= _totalSeries) {
        await _finalizarTreino();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text("Conclua as séries para finalizar.")),
            ],
          ),
        ),
      );
      return;
    }

    _cancelarDescanso();
    setState(() {
      indiceAtual++;
    });
    await _carregarUltimoProgresso();
  }

  Future<void> _finalizarTreino() async {
    if (finalizando) return;

    setState(() {
      finalizando = true;
    });

    treinoTimer?.cancel();
    descansoTimer?.cancel();

    final agora = DateTime.now();
    final totalExercicios = exercicios.length;
    final concluidos = exerciciosConcluidos;
    final series = totalSeriesConcluidas;
    final volume = volumeTotalEstimado;
    final recordes = recordesBatidos;
    final calorias = caloriasEstimadas;
    final xp = ProgressionRules.workoutCompletionXp;

    await StorageService.salvarHistoricoTreino(
      HistoricoTreinoModel(
        id: sessaoTreinoId,
        nomeTreino: widget.treino.nome,
        dataHora: agora,
        tempoSegundos: segundos,
        tempoFormatado: tempoFormatado,
        exerciciosTotais: totalExercicios,
        exerciciosConcluidos: concluidos,
        xpGanho: xp,
        caloriasEstimadas: calorias,
        objetivo: widget.treino.objetivo,
        nivel: widget.treino.nivel,
        seriesConcluidas: series,
        volumeTotal: volume,
        recordesBatidos: recordes,
      ),
    );

    await _registrarProgressaoSemBloquearResumo();
    await widget.onXpAtualizado?.call();

    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ResumoTreinoProfissionalPage(
          nomeTreino: widget.treino.nome,
          tempoTotal: tempoFormatado,
          exercicios: "$concluidos/$totalExercicios",
          series: "$series",
          volume: "${_formatarNumero(volume)} kg",
          recordes: "$recordes",
          xp: "+$xp",
        ),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _registrarProgressaoSemBloquearResumo() async {
    try {
      final history = await StorageService.carregarHistoricoTreinos();
      await ProgressionEngine.instance.reconcile(
        sources: ProgressionSourceData(
          workouts: [
            for (final item in history)
              ProgressionWorkoutSource(
                id: item.id,
                completedAt: item.dataHora,
                name: item.nomeTreino,
              ),
          ],
          runsAvailable: false,
          stepsAvailable: false,
          favoritesAvailable: false,
        ),
      );
    } on Object {
      // A persistencia do treino ja terminou; a reconciliacao e segura.
    }
  }

  String _textoMusculos(ExercicioModel exercicio) {
    final musculos = [...exercicio.musculos, ...exercicio.musculosSecundarios];
    if (musculos.isEmpty) return "Músculos não cadastrados.";
    return musculos.take(5).join(" • ");
  }

  IconData _progressaoIcon(TipoProgressao tipo) {
    return switch (tipo) {
      TipoProgressao.progressao => Icons.arrow_upward_rounded,
      TipoProgressao.deload => Icons.arrow_downward_rounded,
      TipoProgressao.manutencao => Icons.trending_flat_rounded,
      TipoProgressao.inicial => Icons.auto_graph_rounded,
    };
  }

  Color _progressaoColor(TipoProgressao tipo) {
    return switch (tipo) {
      TipoProgressao.progressao => AppColors.primary,
      TipoProgressao.deload => AppColors.accent2,
      TipoProgressao.manutencao => AppColors.accent1,
      TipoProgressao.inicial => AppColors.accent3,
    };
  }

  String _progressaoLabel(TipoProgressao tipo) {
    return switch (tipo) {
      TipoProgressao.progressao => "Progressão",
      TipoProgressao.deload => "Deload",
      TipoProgressao.manutencao => "Manutenção",
      TipoProgressao.inicial => "Primeira referência",
    };
  }

  String _recordeLabel(TipoRecorde tipo) {
    return switch (tipo) {
      TipoRecorde.carga => "Recorde de carga",
      TipoRecorde.repeticoes => "Recorde de reps",
      TipoRecorde.volume => "Recorde de volume",
    };
  }

  String _ultimaExecucaoTexto(ProgressaoSugestao sugestao) {
    final ultima = sugestao.ultimaExecucao;
    if (ultima == null) return "Sem execução anterior";

    return "${_formatarNumero(ultima.peso)} kg x ${ultima.repeticoes} reps";
  }

  String _ultimaExecucaoData(ProgressaoSugestao sugestao) {
    final ultima = sugestao.ultimaExecucao;
    if (ultima == null) return "Conclua este exercício para criar histórico.";

    return "Data: ${_formatarData(ultima.dataHora)}";
  }

  String _sugestaoTexto(ProgressaoSugestao sugestao) {
    final carga = sugestao.cargaSugerida > 0
        ? "${_formatarNumero(sugestao.cargaSugerida)} kg"
        : "Carga livre";

    return "$carga x ${sugestao.repeticoesMin}-${sugestao.repeticoesMax} reps";
  }

  String _serieId(int exercicioIndex, int serieIndex) {
    if (exercicioIndex < 0 || exercicioIndex >= exercicios.length) {
      return "${sessaoTreinoId}_${exercicioIndex}_${serieIndex + 1}";
    }

    final exercicio = exercicios[exercicioIndex];
    final exercicioId = exercicio.id.trim().isEmpty
        ? exercicio.nome
        : exercicio.id;

    return "${sessaoTreinoId}_${exercicioIndex}_${exercicioId}_${serieIndex + 1}";
  }

  int _parseRepeticoes() {
    final valor = int.tryParse(repeticoesController.text.trim()) ?? 10;
    if (valor <= 0) return 10;
    if (valor > 999) return 999;
    return valor;
  }

  int _parseDescanso() {
    final valor =
        int.tryParse(descansoController.text.trim()) ?? _descansoPadrao;
    if (valor < 10) return 10;
    if (valor > 600) return 600;
    return valor;
  }

  double _parsePeso() {
    return double.tryParse(pesoController.text.trim().replaceAll(",", ".")) ??
        0;
  }

  String _formatarNumero(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toStringAsFixed(1).replaceAll(".", ",");
  }

  String _formatarTempo(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    return "${minutos.toString().padLeft(2, "0")}:${segundos.toString().padLeft(2, "0")}";
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, "0");
    final mes = data.month.toString().padLeft(2, "0");
    final ano = data.year.toString();

    return "$dia/$mes/$ano";
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class _ResumoTreinoProfissionalPage extends StatelessWidget {
  final String nomeTreino;
  final String tempoTotal;
  final String exercicios;
  final String series;
  final String volume;
  final String recordes;
  final String xp;

  const _ResumoTreinoProfissionalPage({
    required this.nomeTreino,
    required this.tempoTotal,
    required this.exercicios,
    required this.series,
    required this.volume,
    required this.recordes,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Resumo do treino"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          20,
          _horizontalPadding(context),
          28,
        ),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: AppGradientCard(
              gradient: AppColors.gradientPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.black,
                    size: 42,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Treino salvo no histórico",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nomeTreino,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppGradientCard(
            child: Column(
              children: [
                _resumoItem(Icons.timer_rounded, "Tempo total", tempoTotal),
                _resumoItem(
                  Icons.check_circle_rounded,
                  "Exercícios",
                  exercicios,
                ),
                _resumoItem(
                  Icons.format_list_numbered_rounded,
                  "Séries",
                  series,
                ),
                _resumoItem(Icons.monitor_weight_rounded, "Volume", volume),
                _resumoItem(
                  Icons.emoji_events_rounded,
                  "Recordes batidos",
                  recordes,
                ),
                _resumoItem(Icons.bolt_rounded, "XP", xp),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton.primary(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.done_rounded,
            label: "Concluir",
          ),
        ],
      ),
    );
  }

  Widget _resumoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class _SerieExecutada {
  final double peso;
  final int repeticoes;

  const _SerieExecutada({required this.peso, required this.repeticoes});

  double get volume => peso * repeticoes;
}

class _TreinoProfissionalVazio extends StatelessWidget {
  const _TreinoProfissionalVazio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: AppEmptyState(
          icon: Icons.fitness_center_rounded,
          title: "Plano sem exercícios",
          message: "Adicione exercícios ao plano antes de iniciar.",
        ),
      ),
    );
  }
}
