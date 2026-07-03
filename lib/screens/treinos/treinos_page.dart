import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../ai_workout_page.dart';
import '../../services/storage_service.dart';
import '../../services/treino_service.dart';
import '../../models/historico_treino_model.dart';
import '../../models/treino_model.dart';
import '../../models/exercicio_model.dart';
import 'criar_treino_page.dart';
import 'historico_treinos_page.dart';
import 'widgets/create_plan_bottomsheet.dart';
import 'widgets/plan_card.dart';

class TreinosPage extends StatefulWidget {
  final Future<void> Function()? onXpAtualizado;

  const TreinosPage({super.key, this.onXpAtualizado});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  final treinoService = TreinoService.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarTreinos() async {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _carregarTreinos,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _searchVisible
                        ? Padding(
                            key: const ValueKey("search"),
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildSearchField(context),
                          )
                        : const SizedBox.shrink(key: ValueKey("empty-search")),
                  ),
                  _buildCriarPlanoCard(context),
                  const SizedBox(height: 12),
                  _buildHistoricoTreinosCard(context),
                  const SizedBox(height: 24),
                  _buildTreinos(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Planos FITAI",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Meus Planos",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _headerAction(
            icon: Icons.search_rounded,
            tooltip: "Pesquisar",
            onTap: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchController.clear();
                  _searchQuery = "";
                }
              });
            },
          ),
          const SizedBox(width: 10),
          _headerAction(
            icon: Icons.add_rounded,
            tooltip: "Criar plano",
            onTap: _abrirCriacaoPlano,
            primary: true,
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: primary ? AppColors.gradientPrimary : null,
              color: primary ? null : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary
                    ? Colors.transparent
                    : AppColors.primary.withAlpha(40),
              ),
            ),
            child: Icon(
              icon,
              color: primary ? Colors.black : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return AppGradientCard(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          labelText: "Pesquisar plano",
          hintText: "Nome, objetivo ou nivel",
        ),
      ),
    );
  }

  Widget _buildCriarPlanoCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _abrirCriacaoPlano,
        child: AppGradientCard(
          gradient: AppColors.gradientPrimary,
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.black,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Criar Plano",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Monte uma ficha com IA ou manualmente.",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirCriacaoPlano() async {
    final action = await showModalBottomSheet<CreatePlanAction>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const CreatePlanBottomSheet(),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case CreatePlanAction.ia:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIWorkoutPage()),
        );
        break;
      case CreatePlanAction.manual:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CriarTreinoPage()),
        );
        break;
    }

    if (!mounted) return;

    await _carregarTreinos();
  }

  // ignore: unused_element
  Widget _buildAcoesCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIWorkoutPage()),
        );

        if (!mounted) return;

        await _carregarTreinos();
      },
      child: AppGradientCard(
        gradient: AppColors.gradientPrimary,
        child: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.black),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                "Gerar treino com IA",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCriarManualCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CriarTreinoPage()),
        );

        if (!mounted) return;

        await _carregarTreinos();
      },
      child: AppGradientCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "Criar treino manual",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoTreinosCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoricoTreinosPage()),
        );

        if (!mounted) return;

        setState(() {});
      },
      child: AppGradientCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.accent1,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Histórico de treinos",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Sessões finalizadas, XP e calorias",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCategorias(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _categoriaCard(
            titulo: "Hipertrofia",
            icon: Icons.fitness_center,
            gradient: AppColors.gradientWorkout,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _categoriaCard(
            titulo: "Cardio",
            icon: Icons.directions_run,
            gradient: AppColors.gradientRun,
          ),
        ),
      ],
    );
  }

  Widget _categoriaCard({
    required String titulo,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return AppGradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 18),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreinos() {
    final query = _searchQuery.toLowerCase().trim();
    final treinos = treinoService.treinos.where((treino) {
      if (query.isEmpty) return true;
      final text = "${treino.nome} ${treino.objetivo} ${treino.nivel}"
          .toLowerCase()
          .trim();
      return text.contains(query);
    }).toList();

    if (treinos.isEmpty) {
      return AppGradientCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? "Nenhum plano criado ainda."
                  : "Nenhum plano encontrado.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isEmpty
                  ? "Crie seu primeiro plano para comecar."
                  : "Tente outro nome, objetivo ou nivel.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            "Lista de planos",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 760;
            final cardWidth = twoColumns
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final treino in treinos)
                  SizedBox(
                    width: cardWidth,
                    child: PlanCard(
                      treino: treino,
                      ultimaExecucao: "0 realizados",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TreinoDetalhesPage(treino: treino),
                          ),
                        );

                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class TreinoDetalhesPage extends StatelessWidget {
  final TreinoModel treino;

  const TreinoDetalhesPage({super.key, required this.treino});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Detalhes do plano")),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppGradientCard(
            gradient: AppColors.gradientPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PLANO ATIVO",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  treino.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _darkPill(
                      Icons.timer_rounded,
                      "${treino.tempoEstimado} min",
                    ),
                    _darkPill(
                      Icons.fitness_center_rounded,
                      "${treino.exercicios.length} exercicios",
                    ),
                    _darkPill(Icons.trending_up_rounded, treino.nivel),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Exercicios",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (treino.exercicios.isEmpty)
            AppGradientCard(
              child: const Text(
                "Nenhum exercicio cadastrado neste plano.",
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            for (var index = 0; index < treino.exercicios.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppGradientCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              treino.exercicios[index].nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              treino.exercicios[index].categoria,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _darkPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black87, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class TreinoEmAndamentoPage extends StatefulWidget {
  final TreinoModel treino;
  final Future<void> Function()? onXpAtualizado;

  const TreinoEmAndamentoPage({
    super.key,
    required this.treino,
    this.onXpAtualizado,
  });

  @override
  State<TreinoEmAndamentoPage> createState() => _TreinoEmAndamentoPageState();
}

class _TreinoEmAndamentoPageState extends State<TreinoEmAndamentoPage> {
  final Set<String> exerciciosConcluidos = {};

  Timer? timer;
  int segundos = 0;
  bool treinoIniciado = false;
  bool finalizandoTreino = false;

  double get progresso {
    if (widget.treino.exercicios.isEmpty) return 0;
    return exerciciosConcluidos.length / widget.treino.exercicios.length;
  }

  List<ExercicioModel> get exerciciosConcluidosLista {
    return widget.treino.exercicios
        .where((exercicio) => exerciciosConcluidos.contains(exercicio.id))
        .toList();
  }

  ExercicioModel? get proximoExercicio {
    for (final exercicio in widget.treino.exercicios) {
      if (!exerciciosConcluidos.contains(exercicio.id)) {
        return exercicio;
      }
    }

    return null;
  }

  String get tempoFormatado {
    final minutos = segundos ~/ 60;
    final seg = segundos % 60;

    return "${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}";
  }

  int get caloriasEstimadas {
    final exerciciosBase = exerciciosConcluidosLista.isEmpty
        ? widget.treino.exercicios
        : exerciciosConcluidosLista;

    if (exerciciosBase.isEmpty) return 0;

    final caloriasValidas = exerciciosBase
        .map((exercicio) => exercicio.caloriasHora)
        .where((calorias) => calorias > 0)
        .toList();

    if (caloriasValidas.isEmpty) return 0;

    final mediaCaloriasHora =
        caloriasValidas.reduce((a, b) => a + b) / caloriasValidas.length;
    final minutosEstimadosPorExercicio = widget.treino.exercicios.isEmpty
        ? 0.0
        : widget.treino.tempoEstimado / widget.treino.exercicios.length;
    final minutosEstimadosConcluidos =
        minutosEstimadosPorExercicio * exerciciosConcluidos.length;
    final horas = segundos > 0
        ? segundos / 3600
        : minutosEstimadosConcluidos / 60;

    return (mediaCaloriasHora * horas).round();
  }

  int get xpGanho {
    final bonusTreinoCompleto =
        widget.treino.exercicios.isNotEmpty &&
            exerciciosConcluidos.length == widget.treino.exercicios.length
        ? 5
        : 0;

    return 20 + (exerciciosConcluidos.length * 10) + bonusTreinoCompleto;
  }

  void iniciarOuPausarTreino() {
    if (treinoIniciado) {
      timer?.cancel();

      setState(() {
        treinoIniciado = false;
      });

      return;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        segundos++;
      });
    });

    setState(() {
      treinoIniciado = true;
    });
  }

  bool concluirExercicio(ExercicioModel exercicio) {
    if (exerciciosConcluidos.contains(exercicio.id)) {
      return false;
    }

    setState(() {
      exerciciosConcluidos.add(exercicio.id);
    });

    return true;
  }

  Future<void> finalizarTreino() async {
    if (finalizandoTreino) return;

    timer?.cancel();
    final tempoTotal = tempoFormatado;
    final concluidos = exerciciosConcluidos.length;
    final totalExercicios = widget.treino.exercicios.length;
    final calorias = caloriasEstimadas;
    final xp = xpGanho;
    final dataFinalizacao = DateTime.now();

    setState(() {
      treinoIniciado = false;
      finalizandoTreino = true;
    });

    await StorageService.salvarHistoricoTreino(
      HistoricoTreinoModel(
        id: "historico_${dataFinalizacao.microsecondsSinceEpoch}",
        nomeTreino: widget.treino.nome,
        dataHora: dataFinalizacao,
        tempoSegundos: segundos,
        tempoFormatado: tempoTotal,
        exerciciosTotais: totalExercicios,
        exerciciosConcluidos: concluidos,
        xpGanho: xp,
        caloriasEstimadas: calorias,
        objetivo: widget.treino.objetivo,
        nivel: widget.treino.nivel,
      ),
    );

    final resultadoXp = await StorageService.adicionarXp(xp);
    await widget.onXpAtualizado?.call();

    if (!mounted) return;

    setState(() {
      finalizandoTreino = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Treino concluído!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _resumoDialogItem(
                icon: Icons.timer,
                label: "Tempo total",
                value: tempoTotal,
              ),
              _resumoDialogItem(
                icon: Icons.check_circle,
                label: "Exercícios concluídos",
                value: "$concluidos/$totalExercicios",
              ),
              _resumoDialogItem(
                icon: Icons.local_fire_department,
                label: "Calorias estimadas",
                value: "$calorias kcal",
              ),
              _resumoDialogItem(
                icon: Icons.bolt,
                label: "XP ganho",
                value: "+$xp XP",
              ),
              _resumoDialogItem(
                icon: Icons.workspace_premium,
                label: "Nível atual",
                value: "${resultadoXp.nivel}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Concluir"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget _miniChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _resumoDialogItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treino = widget.treino;
    final proximo = proximoExercicio;
    final proximoTexto = treino.exercicios.isEmpty
        ? "Nenhum exercício cadastrado"
        : proximo?.nome ?? "Todos concluídos";
    final proximoIcon = treino.exercicios.isEmpty
        ? Icons.info_outline_rounded
        : proximo == null
        ? Icons.verified_rounded
        : Icons.arrow_forward_rounded;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(treino.nome)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppGradientCard(
            gradient: AppColors.gradientPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TREINO EM ANDAMENTO",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tempoFormatado,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progresso,
                    backgroundColor: Colors.black26,
                    color: Colors.black,
                    minHeight: 9,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${exerciciosConcluidos.length}/${treino.exercicios.length} exercícios concluídos",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(proximoIcon, color: Colors.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Próximo exercício",
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              proximoTexto,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Column(
            children: [
              ElevatedButton.icon(
                onPressed: iniciarOuPausarTreino,
                icon: Icon(treinoIniciado ? Icons.pause : Icons.play_arrow),
                label: Text(treinoIniciado ? "Pausar" : "Iniciar"),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: finalizandoTreino ? null : finalizarTreino,
                icon: const Icon(Icons.flag),
                label: Text(
                  finalizandoTreino ? "Finalizando..." : "Finalizar treino",
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text("Exercícios", style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(height: 12),

          ...treino.exercicios.map((exercicio) {
            final concluido = exerciciosConcluidos.contains(exercicio.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  final concluidoAgora = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExercicioDetalhePage(
                        exercicio: exercicio,
                        concluido: concluido,
                        onConcluir: () {
                          concluirExercicio(exercicio);
                        },
                      ),
                    ),
                  );

                  if (!mounted) return;

                  if (concluidoAgora == true) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text("${exercicio.nome} concluído!")),
                    );
                  }
                },
                child: AppGradientCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: concluido
                              ? AppColors.primary.withAlpha(40)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          concluido
                              ? Icons.check_rounded
                              : Icons.fitness_center_rounded,
                          color: concluido ? AppColors.primary : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercicio.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercicio.categoria,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _miniChip(exercicio.dificuldade),
                                _miniChip(exercicio.objetivo),
                                if (exercicio.equipamentos.isNotEmpty)
                                  _miniChip(exercicio.equipamentos.first),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 34,
                        child: Icon(
                          concluido
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: concluido ? AppColors.primary : Colors.white54,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ExercicioDetalhePage extends StatelessWidget {
  final ExercicioModel exercicio;
  final bool concluido;
  final VoidCallback onConcluir;

  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    required this.concluido,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final temImagem = exercicio.imagem.trim().isNotEmpty;
    final temVideo = exercicio.video.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(exercicio.nome)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _topoDetalhe(),

          if (temImagem) ...[const SizedBox(height: 16), _imagemPreview()],

          if (temVideo) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _mostrarVideo(context),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text("Assistir vídeo"),
            ),
          ],

          const SizedBox(height: 24),

          _secao(
            titulo: "Descrição",
            texto: exercicio.descricao.isEmpty
                ? "Descrição ainda não cadastrada."
                : exercicio.descricao,
          ),

          _secao(
            titulo: "Como executar",
            texto: exercicio.comoExecutar.isEmpty
                ? "Instruções ainda não cadastradas."
                : exercicio.comoExecutar,
          ),

          _secao(
            titulo: "Cuidados",
            texto: exercicio.cuidados.isEmpty
                ? "Cuidados ainda não cadastrados."
                : exercicio.cuidados,
          ),

          _chips(
            titulo: "Músculos principais",
            itens: exercicio.musculos,
            vazio: "Músculos principais não cadastrados.",
          ),

          _chips(
            titulo: "Músculos secundários",
            itens: exercicio.musculosSecundarios,
            vazio: "Músculos secundários não cadastrados.",
          ),

          _chips(
            titulo: "Equipamentos",
            itens: exercicio.equipamentos,
            vazio: "Equipamentos não cadastrados.",
          ),

          _chips(
            titulo: "Local",
            itens: exercicio.locais,
            vazio: "Local não cadastrado.",
          ),

          _chips(
            titulo: "Tags",
            itens: exercicio.tags,
            vazio: "Tags não cadastradas.",
          ),

          const SizedBox(height: 25),

          ElevatedButton.icon(
            onPressed: concluido
                ? null
                : () {
                    onConcluir();
                    Navigator.pop(context, true);
                  },
            icon: Icon(
              concluido ? Icons.check_circle : Icons.check_circle_outline,
            ),
            label: Text(
              concluido ? "Exercício concluído" : "Concluir exercício",
            ),
          ),
        ],
      ),
    );
  }

  Widget _topoDetalhe() {
    final chips = [
      exercicio.dificuldade,
      exercicio.objetivo,
      if (exercicio.caloriasHora > 0) "${exercicio.caloriasHora} kcal/h",
    ].where((item) => item.trim().isNotEmpty).toList();

    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(26),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.nome,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exercicio.categoria,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map(_topoChip).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _topoChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(26),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _imagemPreview() {
    final imagem = exercicio.imagem.trim();

    return AppGradientCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(aspectRatio: 16 / 9, child: _imagemContent(imagem)),
      ),
    );
  }

  Widget _imagemContent(String imagem) {
    final isNetworkImage =
        imagem.startsWith("http://") || imagem.startsWith("https://");

    if (isNetworkImage) {
      return Image.network(
        imagem,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagemFallback(),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imagemFallback(),
    );
  }

  Widget _imagemFallback() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white54,
          size: 42,
        ),
      ),
    );
  }

  void _mostrarVideo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Assistir vídeo"),
          content: Text(
            exercicio.video,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  Widget _secao({required String titulo, required String texto}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              texto,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips({
    required String titulo,
    required List<String> itens,
    required String vazio,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              Text(
                vazio,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: itens.map((item) {
                  return Chip(
                    label: Text(item),
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
