import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/exercicios/exercicios.dart';
import '../../theme/app_theme.dart';
import '../ai_workout_page.dart';
import '../../services/storage_service.dart';
import '../../services/treino_service.dart';
import '../../models/historico_treino_model.dart';
import '../../models/progresso_exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../models/exercicio_model.dart';
import '../../widgets/app_components.dart';
import '../../widgets/exercicio_gif_viewer.dart';
import 'criar_treino_page.dart';
import 'historico_treinos_page.dart';
import 'treino_profissional_page.dart';
import 'widgets/create_plan_bottomsheet.dart';
import 'widgets/plan_card.dart';
import 'widgets/plan_summary_card.dart';
import 'widgets/rest_timer_widget.dart';

class TreinosPage extends StatefulWidget {
  final Future<void> Function()? onXpAtualizado;

  const TreinosPage({super.key, this.onXpAtualizado});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  final treinoService = TreinoService.instance;
  List<HistoricoTreinoModel> historicoTreinos = [];

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    await treinoService.carregarTreinos();
    final historico = await StorageService.carregarHistoricoTreinos();

    if (!mounted) return;

    setState(() {
      historicoTreinos = historico;
    });
  }

  Future<void> _abrirGeradorIa() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIWorkoutPage()),
    );

    if (!mounted) return;

    await _carregarTreinos();
  }

  Future<void> _abrirCriarManual() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarTreinoPage()),
    );

    if (!mounted) return;

    await _carregarTreinos();
  }

  Future<void> _abrirHistorico() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoricoTreinosPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _abrirCriarPlanoSheet() async {
    final action = await showModalBottomSheet<CreatePlanAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CreatePlanBottomSheet(),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case CreatePlanAction.ia:
        await _abrirGeradorIa();
        break;
      case CreatePlanAction.manual:
        await _abrirCriarManual();
        break;
    }
  }

  Future<void> _abrirDetalhePlano(TreinoModel treino) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanoTreinoDetalhePage(
          treino: treino,
          ultimaExecucao: _ultimaExecucaoTexto(treino),
          onXpAtualizado: widget.onXpAtualizado,
        ),
      ),
    );

    if (!mounted) return;

    await _carregarTreinos();
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
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                0,
                _horizontalPadding(context),
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _buildPlanos(),
                  const SizedBox(height: 14),
                  _buildCriarNovoPlanoCard(),
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
        _horizontalPadding(context),
        MediaQuery.of(context).padding.top + 20,
        _horizontalPadding(context),
        24,
      ),
      child: AppPremiumHeader(
        eyebrow: "Planos",
        title: "Meus Planos",
        subtitle: "Escolha um plano para treinar hoje.",
        icon: Icons.assignment_rounded,
        trailing: IconButton.filledTonal(
          onPressed: _abrirHistorico,
          icon: const Icon(Icons.history_rounded),
          tooltip: "Historico de treinos",
        ),
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }

  // ignore: unused_element
  Widget _buildHistoricoTreinosCard(BuildContext context) {
    return GestureDetector(
      onTap: _abrirHistorico,
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
                    "HistÃ³rico de treinos",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "SessÃµes finalizadas, XP e calorias",
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _categoriaCard(
            titulo: "Hipertrofia",
            icon: Icons.fitness_center,
            gradient: AppColors.gradientWorkout,
          ),
          _categoriaCard(
            titulo: "Cardio",
            icon: Icons.directions_run,
            gradient: AppColors.gradientRun,
          ),
        ];

        if (constraints.maxWidth < 380) {
          return Column(
            children: [cards[0], const SizedBox(height: 12), cards[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  Widget _buildTreinosVazio() {
    return AppGradientCard(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nenhum treino criado ainda",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Crie uma ficha manual ou gere uma ficha inteligente para comeÃ§ar.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          AppButton.primary(
            onPressed: _abrirCriarManual,
            icon: Icons.add_rounded,
            label: "Criar treino manual",
          ),
          const SizedBox(height: 10),
          AppButton.secondary(
            onPressed: _abrirGeradorIa,
            icon: Icons.auto_awesome_rounded,
            label: "Gerar com IA",
          ),
        ],
      ),
    );
  }

  Widget _treinoChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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

  // ignore: unused_element
  Widget _buildTreinos() {
    final treinos = treinoService.treinos;

    if (treinos.isEmpty) {
      return _buildTreinosVazio();
    }

    return Column(
      children: treinos.map((treino) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TreinoProfissionalPage(
                    treino: treino,
                    onXpAtualizado: widget.onXpAtualizado,
                  ),
                ),
              );

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
                      Icons.fitness_center,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          treino.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${treino.exercicios.length} exercÃ­cios â€¢ ${treino.tempoEstimado} min",
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
                            _treinoChip(treino.objetivo),
                            _treinoChip(treino.nivel),
                            if (treino.criadoPorIA) _treinoChip("IA"),
                          ],
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanos() {
    final treinos = treinoService.treinos;

    if (treinos.isEmpty) {
      return _buildPlanosVazio();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      onReorderItem: _reordenarPlanos,
      itemCount: treinos.length,
      itemBuilder: (context, index) {
        final treino = treinos[index];

        return Padding(
          key: ValueKey(treino.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: PlanCard(
            treino: treino,
            ultimaExecucao: _ultimaExecucaoTexto(treino),
            onTap: () => _abrirDetalhePlano(treino),
            onDelete: () => _confirmarApagarPlano(treino),
          ),
        );
      },
    );
  }

  Future<void> _reordenarPlanos(int oldIndex, int newIndex) async {
    await treinoService.reordenarTreinos(oldIndex, newIndex);

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _confirmarApagarPlano(TreinoModel treino) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Apagar plano?"),
          content: Text(
            "O plano \"${treino.nome}\" sera removido dos seus planos.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Apagar"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await treinoService.removerTreino(treino.id);

    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Plano ${treino.nome} apagado.")));
  }

  Widget _buildPlanosVazio() {
    return AppGradientCard(
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nenhum plano criado ainda",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Crie um plano manual ou gere uma ficha inteligente para comecar.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCriarNovoPlanoCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _abrirCriarPlanoSheet,
        child: AppGradientCard(
          gradient: AppColors.gradientPrimary,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(24),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Criar Novo Plano",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "IA ou manual, voce escolhe.",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
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

  String _ultimaExecucaoTexto(TreinoModel treino) {
    final nomeTreino = _normalizarTexto(treino.nome);
    final registros = historicoTreinos.where((item) {
      return _normalizarTexto(item.nomeTreino) == nomeTreino;
    }).toList();

    if (registros.isEmpty) return "Nunca executado";

    registros.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final data = registros.first.dataHora.toLocal();
    final hoje = DateTime.now();
    final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final dataTreino = DateTime(data.year, data.month, data.day);
    final diferenca = dataHoje.difference(dataTreino).inDays;

    if (diferenca == 0) return "Hoje";
    if (diferenca == 1) return "Ontem";

    final dia = data.day.toString().padLeft(2, "0");
    final mes = data.month.toString().padLeft(2, "0");

    return "$dia/$mes/${data.year}";
  }

  String _normalizarTexto(String texto) {
    var valor = texto.toLowerCase().trim();
    final substituicoes = {
      "Ã¡": "a",
      "Ã ": "a",
      "Ã¢": "a",
      "Ã£": "a",
      "Ã©": "e",
      "Ãª": "e",
      "Ã­": "i",
      "Ã³": "o",
      "Ã´": "o",
      "Ãµ": "o",
      "Ãº": "u",
      "Ã¼": "u",
      "Ã§": "c",
      "ÃƒÂ¡": "a",
      "ÃƒÂ ": "a",
      "ÃƒÂ¢": "a",
      "ÃƒÂ£": "a",
      "ÃƒÂ©": "e",
      "ÃƒÂª": "e",
      "ÃƒÂ­": "i",
      "ÃƒÂ³": "o",
      "ÃƒÂ´": "o",
      "ÃƒÂµ": "o",
      "ÃƒÂº": "u",
      "ÃƒÂ¼": "u",
      "ÃƒÂ§": "c",
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }
}

class DetalhePlanoPage extends StatefulWidget {
  final TreinoModel treino;
  final String ultimaExecucao;
  final Future<void> Function()? onXpAtualizado;

  const DetalhePlanoPage({
    super.key,
    required this.treino,
    required this.ultimaExecucao,
    this.onXpAtualizado,
  });

  @override
  State<DetalhePlanoPage> createState() => _DetalhePlanoPageState();
}

class PlanoTreinoDetalhePage extends DetalhePlanoPage {
  const PlanoTreinoDetalhePage({
    super.key,
    required super.treino,
    required super.ultimaExecucao,
    super.onXpAtualizado,
  });
}

class _DetalhePlanoPageState extends State<DetalhePlanoPage> {
  late TreinoModel treinoAtual;

  TreinoModel get treino => treinoAtual;

  @override
  void initState() {
    super.initState();
    treinoAtual = widget.treino;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Detalhe do Plano")),
      body: FutureBuilder<List<ProgressoExercicioModel>>(
        future: StorageService.carregarProgressos(),
        builder: (context, snapshot) {
          final progressos = snapshot.data ?? const <ProgressoExercicioModel>[];
          final cargas = _ultimosProgressosPorExercicio(progressos);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              20,
              _horizontalPadding(context),
              32,
            ),
            children: [
              PlanSummaryCard(
                treino: treino,
                ultimaExecucao: widget.ultimaExecucao,
              ),
              const SizedBox(height: 24),
              Text(
                "Exercicios",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              if (treino.exercicios.isEmpty)
                const AppEmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: "Plano sem exercicios",
                  message: "Edite ou crie um novo plano com exercicios.",
                )
              else
                _buildExerciciosReordenaveis(cargas),
              const SizedBox(height: 12),
              AppButton.primary(
                onPressed: () => _iniciarTreino(context),
                icon: Icons.play_arrow_rounded,
                label: "Iniciar Treino",
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _iniciarTreino(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreinoProfissionalPage(
          treino: treino,
          onXpAtualizado: widget.onXpAtualizado,
        ),
      ),
    );
  }

  Widget _buildExerciciosReordenaveis(
    Map<String, ProgressoExercicioModel> cargas,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      onReorderItem: _reordenarExercicios,
      itemCount: treino.exercicios.length,
      itemBuilder: (context, index) {
        final exercicio = treino.exercicios[index];
        final progresso = cargas[_normalizarTexto(exercicio.nome)];

        return Padding(
          key: ValueKey("${treino.id}_${exercicio.id}_$index"),
          padding: const EdgeInsets.only(bottom: 12),
          child: _PlanoExercicioCard(
            exercicio: exercicio,
            progresso: progresso,
            onDelete: () => _confirmarExcluirExercicio(exercicio),
          ),
        );
      },
    );
  }

  Future<void> _reordenarExercicios(int oldIndex, int newIndex) async {
    final exercicios = [...treino.exercicios];

    var destino = newIndex;
    if (destino < 0) destino = 0;
    if (destino > exercicios.length - 1) destino = exercicios.length - 1;

    final exercicio = exercicios.removeAt(oldIndex);
    exercicios.insert(destino, exercicio);

    await _salvarExercicios(exercicios);
  }

  Future<void> _confirmarExcluirExercicio(ExercicioModel exercicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Excluir exercicio?"),
          content: Text("Remover \"${exercicio.nome}\" deste plano de treino?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final exercicios = [...treino.exercicios]
      ..removeWhere((item) => item.id == exercicio.id);

    await _salvarExercicios(exercicios);
  }

  Future<void> _salvarExercicios(List<ExercicioModel> exercicios) async {
    final atualizado = TreinoModel(
      id: treino.id,
      nome: treino.nome,
      descricao: treino.descricao,
      objetivo: treino.objetivo,
      nivel: treino.nivel,
      tempoEstimado: treino.tempoEstimado,
      criadoPorIA: treino.criadoPorIA,
      exercicios: exercicios,
      dataCriacao: treino.dataCriacao,
    );

    await TreinoService.instance.editarTreino(atualizado);

    if (!mounted) return;

    setState(() {
      treinoAtual = atualizado;
    });
  }

  Map<String, ProgressoExercicioModel> _ultimosProgressosPorExercicio(
    List<ProgressoExercicioModel> progressos,
  ) {
    final mapa = <String, ProgressoExercicioModel>{};
    final ordenados = [...progressos]..sort((a, b) => b.data.compareTo(a.data));

    for (final progresso in ordenados) {
      mapa.putIfAbsent(
        _normalizarTexto(progresso.nomeExercicio),
        () => progresso,
      );
    }

    return mapa;
  }

  String _normalizarTexto(String texto) {
    var valor = texto.toLowerCase().trim();
    final substituicoes = {
      "Ã¡": "a",
      "Ã ": "a",
      "Ã¢": "a",
      "Ã£": "a",
      "Ã©": "e",
      "Ãª": "e",
      "Ã­": "i",
      "Ã³": "o",
      "Ã´": "o",
      "Ãµ": "o",
      "Ãº": "u",
      "Ã¼": "u",
      "Ã§": "c",
      "ÃƒÂ¡": "a",
      "ÃƒÂ ": "a",
      "ÃƒÂ¢": "a",
      "ÃƒÂ£": "a",
      "ÃƒÂ©": "e",
      "ÃƒÂª": "e",
      "ÃƒÂ­": "i",
      "ÃƒÂ³": "o",
      "ÃƒÂ´": "o",
      "ÃƒÂµ": "o",
      "ÃƒÂº": "u",
      "ÃƒÂ¼": "u",
      "ÃƒÂ§": "c",
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class _PlanoExercicioCard extends StatelessWidget {
  final ExercicioModel exercicio;
  final ProgressoExercicioModel? progresso;
  final VoidCallback? onDelete;

  const _PlanoExercicioCard({
    required this.exercicio,
    required this.progresso,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final series = progresso?.series ?? 3;
    final repeticoes = progresso?.repeticoes ?? 10;
    final carga = progresso == null || progresso!.peso <= 0
        ? null
        : "${_formatarPeso(progresso!.peso)} kg";
    final ultimo = progresso == null
        ? "Sem progresso registrado"
        : "Ultimo: ${_formatarPeso(progresso!.peso)} kg - ${progresso!.series}x${progresso!.repeticoes}";

    return AppGradientCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => mostrarGifExercicioTelaCheia(
                context,
                imagem: exercicio.imagem,
                titulo: exercicio.nome,
                subtitulo: exercicio.categoria,
              ),
              child: SizedBox(
                width: 56,
                height: 56,
                child: _imagemPlanoExercicio(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  exercicio.categoria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  ultimo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppChip(
                      label: "$series x $repeticoes",
                      icon: Icons.format_list_numbered_rounded,
                    ),
                    if (carga != null)
                      AppChip(
                        label: carga,
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.accent2,
                      ),
                    if (carga == null)
                      const AppChip(
                        label: "Carga sugerida livre",
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.accent2,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              height: 38,
              child: IconButton(
                onPressed: onDelete,
                tooltip: "Excluir exercicio",
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imagemPlanoExercicio() {
    final imagem = exercicio.imagem.trim();

    if (imagem.isEmpty) return _fallbackImagem();

    final network =
        imagem.startsWith("http://") || imagem.startsWith("https://");

    if (network) {
      return Container(
        color: Colors.black12,
        child: Image.network(
          imagem,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => _fallbackImagem(),
        ),
      );
    }

    return Container(
      color: Colors.black12,
      child: Image.asset(
        imagem,
        fit: BoxFit.contain,
        cacheWidth: 640,
        filterQuality: FilterQuality.low,
        semanticLabel: exercicio.nome,
        errorBuilder: (_, _, _) => _fallbackImagem(),
      ),
    );
  }

  Widget _fallbackImagem() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          exercicio.nome.isEmpty ? "?" : exercicio.nome[0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  String _formatarPeso(double peso) {
    if (peso == peso.roundToDouble()) return peso.round().toString();
    return peso.toStringAsFixed(1).replaceAll(".", ",");
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
  final Map<String, int> seriesRegistradas = {};
  final Map<String, int> seriesMeta = {};

  Timer? timer;
  Timer? descansoTimer;
  late List<ExercicioModel> exerciciosTreino;
  int indiceAtual = 0;
  int segundos = 0;
  int descansoTotal = 0;
  int descansoRestante = 0;
  bool treinoIniciado = false;
  bool finalizandoTreino = false;
  bool descansoAtivo = false;
  bool descansoEntreExercicios = false;
  String descansoTitulo = "";
  String descansoDescricao = "";

  @override
  void initState() {
    super.initState();
    exerciciosTreino = [...widget.treino.exercicios];
  }

  double get progresso {
    if (exerciciosTreino.isEmpty) return 0;
    return exerciciosConcluidos.length / exerciciosTreino.length;
  }

  List<ExercicioModel> get exerciciosConcluidosLista {
    return exerciciosTreino
        .where((exercicio) => exerciciosConcluidos.contains(exercicio.id))
        .toList();
  }

  ExercicioModel? get exercicioAtual {
    if (exerciciosTreino.isEmpty) return null;
    return exerciciosTreino[indiceAtual.clamp(0, exerciciosTreino.length - 1)];
  }

  ExercicioModel? get proximoExercicio => exercicioAtual;

  String get tempoFormatado {
    final minutos = segundos ~/ 60;
    final seg = segundos % 60;

    return "${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}";
  }

  int get caloriasEstimadas {
    final exerciciosBase = exerciciosConcluidosLista.isEmpty
        ? exerciciosTreino
        : exerciciosConcluidosLista;

    if (exerciciosBase.isEmpty) return 0;

    final caloriasValidas = exerciciosBase
        .map((exercicio) => exercicio.caloriasHora)
        .where((calorias) => calorias > 0)
        .toList();

    if (caloriasValidas.isEmpty) return 0;

    final mediaCaloriasHora =
        caloriasValidas.reduce((a, b) => a + b) / caloriasValidas.length;
    final minutosEstimadosPorExercicio = exerciciosTreino.isEmpty
        ? 0.0
        : widget.treino.tempoEstimado / exerciciosTreino.length;
    final minutosEstimadosConcluidos =
        minutosEstimadosPorExercicio * exerciciosConcluidos.length;
    final horas = segundos > 0
        ? segundos / 3600
        : minutosEstimadosConcluidos / 60;

    return (mediaCaloriasHora * horas).round();
  }

  int get xpGanho {
    final bonusTreinoCompleto =
        exerciciosTreino.isNotEmpty &&
            exerciciosConcluidos.length == exerciciosTreino.length
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

  Future<void> registrarSerie(ExercicioModel exercicio) async {
    final progresso = await showModalBottomSheet<ProgressoExercicioModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RegistroProgressoSheet(
        exercicio: exercicio,
        titulo: "Registrar Serie",
        acaoLabel: "Salvar serie",
      ),
    );

    if (progresso == null) return;

    await StorageService.salvarProgresso(progresso);

    if (!mounted) return;

    final registradas = (seriesRegistradas[exercicio.id] ?? 0) + 1;
    final metaSeries = progresso.series <= 0 ? 1 : progresso.series;
    final todasSeriesConcluidas = registradas >= metaSeries;
    final temProximo = indiceAtual < exerciciosTreino.length - 1;

    setState(() {
      seriesRegistradas[exercicio.id] = registradas;
      seriesMeta[exercicio.id] = metaSeries;
    });

    if (todasSeriesConcluidas) {
      concluirExercicio(exercicio);

      if (temProximo) {
        _iniciarDescanso(
          totalSegundos: progresso.tempoDescanso ?? 120,
          titulo: "Descanso entre exercicios",
          descricao:
              "Todas as series foram registradas. Recupere antes do proximo exercicio.",
          entreExercicios: true,
        );
      }
    } else {
      _iniciarDescanso(
        totalSegundos: progresso.tempoDescanso ?? 90,
        titulo: "Descanso entre series",
        descricao: "Serie $registradas de $metaSeries registrada.",
        entreExercicios: false,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Serie de ${exercicio.nome} registrada.")),
    );
  }

  void _iniciarDescanso({
    required int totalSegundos,
    required String titulo,
    required String descricao,
    required bool entreExercicios,
  }) {
    final total = totalSegundos <= 0
        ? (entreExercicios ? 120 : 90)
        : totalSegundos;

    descansoTimer?.cancel();

    setState(() {
      descansoAtivo = true;
      descansoEntreExercicios = entreExercicios;
      descansoTotal = total;
      descansoRestante = total;
      descansoTitulo = titulo;
      descansoDescricao = descricao;
    });

    descansoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (descansoRestante <= 1) {
        descansoTimer?.cancel();

        if (descansoEntreExercicios) {
          setState(() {
            descansoRestante = 0;
          });
        } else {
          _encerrarDescanso();
        }

        return;
      }

      setState(() {
        descansoRestante--;
      });
    });
  }

  void _pularDescanso() {
    descansoTimer?.cancel();

    if (descansoEntreExercicios) {
      setState(() {
        descansoRestante = 0;
      });
      return;
    }

    _encerrarDescanso();
  }

  void _encerrarDescanso() {
    descansoTimer?.cancel();

    if (!mounted) return;

    setState(() {
      descansoAtivo = false;
      descansoEntreExercicios = false;
      descansoTotal = 0;
      descansoRestante = 0;
      descansoTitulo = "";
      descansoDescricao = "";
    });
  }

  void _proximoExercicioDepoisDoDescanso() {
    _encerrarDescanso();

    if (indiceAtual < exerciciosTreino.length - 1) {
      setState(() {
        indiceAtual++;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Todos os exercicios concluidos. Finalize o treino."),
      ),
    );
  }

  void avancarParaProximoExercicio() {
    final atual = exercicioAtual;
    if (atual == null) return;

    concluirExercicio(atual);

    if (indiceAtual < exerciciosTreino.length - 1) {
      _iniciarDescanso(
        totalSegundos: 120,
        titulo: "Descanso entre exercicios",
        descricao: "Respire, hidrate-se e prepare-se para o proximo movimento.",
        entreExercicios: true,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Todos os exercicios concluidos. Finalize o treino."),
      ),
    );
  }

  Future<void> trocarExercicioAtual() async {
    final atual = exercicioAtual;
    if (atual == null) return;

    final similares = _exerciciosSemelhantes(atual);

    final escolhido = await showModalBottomSheet<ExercicioModel>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _TrocarExercicioSheet(exercicioAtual: atual, similares: similares),
    );

    if (escolhido == null || !mounted) return;

    setState(() {
      exerciciosConcluidos.remove(atual.id);
      exerciciosTreino[indiceAtual] = escolhido;
    });
  }

  Future<void> abrirInformacoesExercicio(ExercicioModel exercicio) async {
    final concluido = exerciciosConcluidos.contains(exercicio.id);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${exercicio.nome} concluido.")));
    }
  }

  List<ExercicioModel> _exerciciosSemelhantes(ExercicioModel exercicio) {
    final usados = exerciciosTreino.map((item) => item.id).toSet();
    final candidatos = bancoExercicios.where((item) {
      if (item.id == exercicio.id) return false;
      if (usados.contains(item.id)) return false;
      return _scoreExercicioSemelhante(exercicio, item) > 0;
    }).toList();

    candidatos.sort(
      (a, b) => _scoreExercicioSemelhante(
        exercicio,
        b,
      ).compareTo(_scoreExercicioSemelhante(exercicio, a)),
    );

    return candidatos.take(12).toList();
  }

  int _scoreExercicioSemelhante(ExercicioModel base, ExercicioModel candidato) {
    var score = 0;

    if (_normalizarTreinoTexto(base.categoria) ==
        _normalizarTreinoTexto(candidato.categoria)) {
      score += 3;
    }

    score +=
        _intersecoesTreino(_musculosTreino(base), _musculosTreino(candidato)) *
        2;

    score += _intersecoesTreino(
      base.equipamentos.map(_normalizarTreinoTexto).toSet(),
      candidato.equipamentos.map(_normalizarTreinoTexto).toSet(),
    );

    return score;
  }

  Set<String> _musculosTreino(ExercicioModel exercicio) {
    return {
      ...exercicio.musculos.map(_normalizarTreinoTexto),
      ...exercicio.musculosSecundarios.map(_normalizarTreinoTexto),
    }..removeWhere((item) => item.isEmpty);
  }

  int _intersecoesTreino(Set<String> a, Set<String> b) {
    return a.where(b.contains).length;
  }

  String _normalizarTreinoTexto(String texto) {
    var valor = texto.toLowerCase().trim();
    final substituicoes = {
      "Ã¡": "a",
      "Ã ": "a",
      "Ã¢": "a",
      "Ã£": "a",
      "Ã©": "e",
      "Ãª": "e",
      "Ã­": "i",
      "Ã³": "o",
      "Ã´": "o",
      "Ãµ": "o",
      "Ãº": "u",
      "Ã¼": "u",
      "Ã§": "c",
      "ÃƒÂ¡": "a",
      "ÃƒÂ ": "a",
      "ÃƒÂ¢": "a",
      "ÃƒÂ£": "a",
      "ÃƒÂ©": "e",
      "ÃƒÂª": "e",
      "ÃƒÂ­": "i",
      "ÃƒÂ³": "o",
      "ÃƒÂ´": "o",
      "ÃƒÂµ": "o",
      "ÃƒÂº": "u",
      "ÃƒÂ¼": "u",
      "ÃƒÂ§": "c",
    };

    for (final entrada in substituicoes.entries) {
      valor = valor.replaceAll(entrada.key, entrada.value);
    }

    return valor;
  }

  Future<void> finalizarTreino() async {
    if (finalizandoTreino) return;

    timer?.cancel();
    final tempoTotal = tempoFormatado;
    final concluidos = exerciciosConcluidos.length;
    final totalExercicios = exerciciosTreino.length;
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
          title: const Text("Treino concluÃ­do!"),
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
                label: "ExercÃ­cios concluÃ­dos",
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
                label: "NÃ­vel atual",
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
    descansoTimer?.cancel();
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

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }

  Widget _heroMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black, size: 16),
          const SizedBox(width: 7),
          Text(
            "$label: $value",
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

  Widget _botoesTreino(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ladoALado = constraints.maxWidth >= 560;
        final iniciar = AppButton.primary(
          onPressed: iniciarOuPausarTreino,
          icon: treinoIniciado ? Icons.pause : Icons.play_arrow,
          label: treinoIniciado ? "Pausar" : "Iniciar treino",
        );
        final finalizar = AppButton.secondary(
          onPressed: finalizandoTreino ? null : finalizarTreino,
          loading: finalizandoTreino,
          icon: Icons.flag,
          label: finalizandoTreino ? "Finalizando..." : "Finalizar",
        );

        if (!ladoALado) {
          return Column(
            children: [iniciar, const SizedBox(height: 12), finalizar],
          );
        }

        return Row(
          children: [
            Expanded(child: iniciar),
            const SizedBox(width: 12),
            Expanded(child: finalizar),
          ],
        );
      },
    );
  }

  Widget _exerciciosVazio() {
    return AppGradientCard(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Nenhum exercicio neste treino",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Adicione exercicios na ficha para acompanhar sua execucao.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final atual = exercicioAtual;
    final total = exerciciosTreino.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.treino.nome),
        actions: [
          IconButton(
            onPressed: iniciarOuPausarTreino,
            icon: Icon(treinoIniciado ? Icons.pause_rounded : Icons.play_arrow),
            tooltip: treinoIniciado ? "Pausar" : "Iniciar",
          ),
          IconButton(
            onPressed: finalizandoTreino ? null : finalizarTreino,
            icon: const Icon(Icons.flag_rounded),
            tooltip: "Finalizar treino",
          ),
        ],
      ),
      body: atual == null
          ? ListView(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                20,
                _horizontalPadding(context),
                32,
              ),
              children: [
                _exerciciosVazio(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: finalizandoTreino ? null : finalizarTreino,
                  icon: const Icon(Icons.flag_rounded),
                  label: Text(
                    finalizandoTreino ? "Finalizando..." : "Finalizar treino",
                  ),
                ),
              ],
            )
          : descansoAtivo
          ? _buildDescansoView()
          : FutureBuilder<List<ProgressoExercicioModel>>(
              future: StorageService.carregarHistoricoExercicio(atual.nome),
              builder: (context, snapshot) {
                final historico =
                    snapshot.data ?? const <ProgressoExercicioModel>[];
                final ultimo = historico.isEmpty ? null : historico.first;
                final recorde = historico.isEmpty
                    ? null
                    : historico.reduce(
                        (maior, item) => item.peso > maior.peso ? item : maior,
                      );

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    _horizontalPadding(context),
                    16,
                    _horizontalPadding(context),
                    32,
                  ),
                  children: [
                    AppGradientCard(
                      gradient: AppColors.gradientPrimary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "EXERCICIO ${indiceAtual + 1}/$total",
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              _heroMetric(
                                icon: Icons.timer_rounded,
                                label: "Tempo",
                                value: tempoFormatado,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progresso,
                              backgroundColor: Colors.black26,
                              color: Colors.black,
                              minHeight: 9,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${exerciciosConcluidos.length}/$total concluidos",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _imagemGrande(atual),
                    const SizedBox(height: 16),
                    AppGradientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            atual.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _textoMusculos(atual),
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppChip(
                                label: "Meta ${_metaRepeticoes(ultimo)}",
                                icon: Icons.format_list_numbered_rounded,
                              ),
                              AppChip(
                                label: _seriesTexto(atual, ultimo),
                                icon: Icons.add_task_rounded,
                                color: AppColors.primary,
                              ),
                              AppChip(
                                label: "Descanso ${_descansoTexto(ultimo)}",
                                icon: Icons.hourglass_bottom_rounded,
                                color: AppColors.accent1,
                              ),
                              AppChip(
                                label: atual.categoria,
                                icon: Icons.category_rounded,
                                color: AppColors.accent3,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _dadoCarga(
                                  icon: Icons.history_rounded,
                                  label: "Ultima carga",
                                  value: _cargaTexto(ultimo),
                                  color: AppColors.accent1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dadoCarga(
                                  icon: Icons.emoji_events_rounded,
                                  label: "Recorde",
                                  value: _cargaTexto(recorde),
                                  color: AppColors.accent2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => registrarSerie(atual),
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text("Registrar Serie"),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: avancarParaProximoExercicio,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text(
                        indiceAtual >= total - 1
                            ? "Concluir Exercicio"
                            : "Proximo Exercicio",
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final ladoALado = constraints.maxWidth >= 520;
                        final trocar = OutlinedButton.icon(
                          onPressed: trocarExercicioAtual,
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text("Trocar exercicio"),
                        );
                        final info = OutlinedButton.icon(
                          onPressed: () => abrirInformacoesExercicio(atual),
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text("Informacoes"),
                        );

                        if (!ladoALado) {
                          return Column(
                            children: [
                              trocar,
                              const SizedBox(height: 10),
                              info,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: trocar),
                            const SizedBox(width: 10),
                            Expanded(child: info),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    TextButton.icon(
                      onPressed: finalizandoTreino ? null : finalizarTreino,
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(
                        finalizandoTreino
                            ? "Finalizando..."
                            : "Finalizar treino",
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDescansoView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        20,
        _horizontalPadding(context),
        32,
      ),
      children: [
        RestTimerWidget(
          title: descansoTitulo,
          subtitle: descansoDescricao,
          totalSeconds: descansoTotal,
          remainingSeconds: descansoRestante,
          showNextButton: descansoEntreExercicios,
          onSkip: _pularDescanso,
          onNext: descansoEntreExercicios
              ? _proximoExercicioDepoisDoDescanso
              : null,
        ),
        const SizedBox(height: 16),
        AppGradientCard(
          child: Row(
            children: [
              const Icon(Icons.timer_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  descansoEntreExercicios
                      ? "O proximo exercicio sera liberado ao final do descanso."
                      : "Prepare-se para registrar a proxima serie.",
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagemGrande(ExercicioModel exercicio) {
    final imagem = exercicio.imagem.trim();

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, minHeight: 160),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: imagem.isEmpty
                  ? _imagemTreinoFallback(exercicio)
                  : _imagemTreino(imagem),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagemTreino(String imagem) {
    final network =
        imagem.startsWith("http://") || imagem.startsWith("https://");

    if (network) {
      return Image.network(
        imagem,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _imagemTreinoFallback(null),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.contain,
      cacheWidth: 900,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => _imagemTreinoFallback(null),
    );
  }

  Widget _imagemTreinoFallback(ExercicioModel? exercicio) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientWorkout),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 46,
            ),
            if (exercicio != null) ...[
              const SizedBox(height: 10),
              Text(
                exercicio.categoria,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dadoCarga({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _textoMusculos(ExercicioModel exercicio) {
    final musculos = [
      ...exercicio.musculos,
      ...exercicio.musculosSecundarios.take(2),
    ].where((item) => item.trim().isNotEmpty).toList();

    if (musculos.isEmpty) return "Musculos nao cadastrados";

    return musculos.join(" â€¢ ");
  }

  String _metaRepeticoes(ProgressoExercicioModel? ultimo) {
    if (ultimo == null || ultimo.series <= 0 || ultimo.repeticoes <= 0) {
      return "3 x 10";
    }

    return "${ultimo.series} x ${ultimo.repeticoes}";
  }

  String _seriesTexto(
    ExercicioModel exercicio,
    ProgressoExercicioModel? ultimo,
  ) {
    final registradas = seriesRegistradas[exercicio.id] ?? 0;
    final meta = seriesMeta[exercicio.id] ?? ultimo?.series ?? 3;

    return "Series $registradas/$meta";
  }

  String _descansoTexto(ProgressoExercicioModel? ultimo) {
    final descanso = ultimo?.tempoDescanso;
    if (descanso == null || descanso <= 0) return "60s";
    return "${descanso}s";
  }

  String _cargaTexto(ProgressoExercicioModel? progresso) {
    if (progresso == null || progresso.peso <= 0) return "Sem registro";
    return "${_formatarPesoTreino(progresso.peso)} kg";
  }

  String _formatarPesoTreino(double peso) {
    if (peso == peso.roundToDouble()) return peso.round().toString();
    return peso.toStringAsFixed(1).replaceAll(".", ",");
  }

  // ignore: unused_element
  Widget _buildListaLegada(BuildContext context) {
    final treino = widget.treino;
    final proximo = proximoExercicio;
    final proximoTexto = treino.exercicios.isEmpty
        ? "Nenhum exercÃ­cio cadastrado"
        : proximo?.nome ?? "Todos concluÃ­dos";
    final proximoIcon = treino.exercicios.isEmpty
        ? Icons.info_outline_rounded
        : proximo == null
        ? Icons.verified_rounded
        : Icons.arrow_forward_rounded;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(treino.nome)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          20,
          _horizontalPadding(context),
          32,
        ),
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _heroMetric(
                      icon: Icons.fitness_center_rounded,
                      label: "Exercicios",
                      value: "${treino.exercicios.length}",
                    ),
                    _heroMetric(
                      icon: Icons.local_fire_department_rounded,
                      label: "Kcal",
                      value: "$caloriasEstimadas",
                    ),
                    _heroMetric(
                      icon: Icons.bolt_rounded,
                      label: "XP",
                      value: "+$xpGanho",
                    ),
                  ],
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
                  "${exerciciosConcluidos.length}/${treino.exercicios.length} exercÃ­cios concluÃ­dos",
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
                              "PrÃ³ximo exercÃ­cio",
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

          _botoesTreino(context),

          const SizedBox(height: 28),

          Text("ExercÃ­cios", style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(height: 12),

          if (treino.exercicios.isEmpty)
            _exerciciosVazio()
          else
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
                        SnackBar(
                          content: Text("${exercicio.nome} concluÃ­do!"),
                        ),
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
                            color: concluido
                                ? AppColors.primary
                                : Colors.white70,
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
                            color: concluido
                                ? AppColors.primary
                                : Colors.white54,
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

class _TrocarExercicioSheet extends StatelessWidget {
  final ExercicioModel exercicioAtual;
  final List<ExercicioModel> similares;

  const _TrocarExercicioSheet({
    required this.exercicioAtual,
    required this.similares,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Trocar exercicio",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "Sugestoes parecidas com ${exercicioAtual.nome}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (similares.isEmpty)
              const AppEmptyState(
                icon: Icons.search_off_rounded,
                title: "Nenhuma substituicao encontrada",
                message: "Nao encontramos exercicios parecidos no banco atual.",
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: similares.length,
                  itemBuilder: (context, index) {
                    final exercicio = similares[index];
                    final equipamento = exercicio.equipamentos.isEmpty
                        ? "Sem equipamento"
                        : exercicio.equipamentos.first;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context, exercicio),
                        child: AppGradientCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercicio.nome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${exercicio.categoria} - $equipamento",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
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
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          20,
          _horizontalPadding(context),
          32,
        ),
        children: [
          _topoDetalhe(),
          const SizedBox(height: 16),
          _progressoCard(),

          if (temImagem) ...[
            const SizedBox(height: 16),
            _imagemPreview(context),
          ],

          if (temVideo) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _mostrarVideo(context),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text("Assistir vÃ­deo"),
            ),
          ],

          const SizedBox(height: 24),

          _secao(
            titulo: "DescriÃ§Ã£o",
            texto: exercicio.descricao.isEmpty
                ? "DescriÃ§Ã£o ainda nÃ£o cadastrada."
                : exercicio.descricao,
          ),

          _secao(
            titulo: "Como executar",
            texto: exercicio.comoExecutar.isEmpty
                ? "InstruÃ§Ãµes ainda nÃ£o cadastradas."
                : exercicio.comoExecutar,
          ),

          _secao(
            titulo: "Cuidados",
            texto: exercicio.cuidados.isEmpty
                ? "Cuidados ainda nÃ£o cadastrados."
                : exercicio.cuidados,
          ),

          _chips(
            titulo: "MÃºsculos principais",
            itens: exercicio.musculos,
            vazio: "MÃºsculos principais nÃ£o cadastrados.",
          ),

          _chips(
            titulo: "MÃºsculos secundÃ¡rios",
            itens: exercicio.musculosSecundarios,
            vazio: "MÃºsculos secundÃ¡rios nÃ£o cadastrados.",
          ),

          _chips(
            titulo: "Equipamentos",
            itens: exercicio.equipamentos,
            vazio: "Equipamentos nÃ£o cadastrados.",
          ),

          _chips(
            titulo: "Local",
            itens: exercicio.locais,
            vazio: "Local nÃ£o cadastrado.",
          ),

          _chips(
            titulo: "Tags",
            itens: exercicio.tags,
            vazio: "Tags nÃ£o cadastradas.",
          ),

          _exerciciosRelacionados(
            titulo: "Exercicios similares",
            vazio: "Ainda nao encontramos exercicios similares.",
            itens: _exerciciosSimilares(),
            icon: Icons.hub_rounded,
          ),

          _exerciciosRelacionados(
            titulo: "Substituicoes sugeridas",
            vazio: "Sem substituicoes claras para este exercicio.",
            itens: _substituicoesSugeridas(),
            icon: Icons.swap_horiz_rounded,
          ),

          const SizedBox(height: 25),

          ElevatedButton.icon(
            onPressed: concluido ? null : () => _concluirComRegistro(context),
            icon: Icon(
              concluido ? Icons.check_circle : Icons.check_circle_outline,
            ),
            label: Text(
              concluido ? "ExercÃ­cio concluÃ­do" : "Concluir exercÃ­cio",
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _concluirComRegistro(BuildContext context) async {
    final progresso = await showModalBottomSheet<ProgressoExercicioModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RegistroProgressoSheet(exercicio: exercicio),
    );

    if (progresso == null) return;

    await StorageService.salvarProgresso(progresso);

    onConcluir();

    if (!context.mounted) return;

    Navigator.pop(context, true);
  }

  Widget _progressoCard() {
    return FutureBuilder<List<ProgressoExercicioModel>>(
      future: StorageService.carregarHistoricoExercicio(exercicio.nome),
      builder: (context, snapshot) {
        final historico = snapshot.data ?? const <ProgressoExercicioModel>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading(message: "Carregando progressao...");
        }

        if (historico.isEmpty) {
          return AppGradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SecaoTituloProgresso(),
                SizedBox(height: 10),
                Text(
                  "Nenhum registro de carga para este exercicio ainda.",
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          );
        }

        final ultimo = historico.first;
        final recorde = historico.reduce(
          (atual, item) => item.peso > atual.peso ? item : atual,
        );
        final evolucao = _textoEvolucao(historico);

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SecaoTituloProgresso(),
              const SizedBox(height: 12),
              AppInfoRow(
                icon: Icons.history_rounded,
                label: "Ultimo treino",
                value:
                    "${_formatarPeso(ultimo.peso)} kg â€¢ ${ultimo.series}x${ultimo.repeticoes}",
                color: AppColors.accent1,
              ),
              const SizedBox(height: 12),
              AppInfoRow(
                icon: Icons.emoji_events_rounded,
                label: "Recorde pessoal",
                value:
                    "${_formatarPeso(recorde.peso)} kg â€¢ ${_formatarDataCurta(recorde.data)}",
                color: AppColors.accent2,
              ),
              const SizedBox(height: 12),
              AppInfoRow(
                icon: Icons.trending_up_rounded,
                label: "Evolucao recente",
                value: evolucao,
                color: AppColors.primary,
              ),
              if (ultimo.observacao.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  ultimo.observacao,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _textoEvolucao(List<ProgressoExercicioModel> historico) {
    if (historico.length < 2) return "Primeiro registro";

    final atual = historico[0].peso;
    final anterior = historico[1].peso;
    final diferenca = atual - anterior;

    if (diferenca > 0) return "+${_formatarPeso(diferenca)} kg";
    if (diferenca < 0) return "${_formatarPeso(diferenca)} kg";

    return "Carga mantida";
  }

  String _formatarPeso(double peso) {
    if (peso == peso.roundToDouble()) return peso.round().toString();
    return peso.toStringAsFixed(1).replaceAll(".", ",");
  }

  String _formatarDataCurta(DateTime data) {
    final dia = data.day.toString().padLeft(2, "0");
    final mes = data.month.toString().padLeft(2, "0");

    return "$dia/$mes";
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

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
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

  Widget _imagemPreview(BuildContext context) {
    final imagem = exercicio.imagem.trim();

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, minHeight: 160),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: _imagemContent(imagem),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagemContent(String imagem) {
    final isNetworkImage =
        imagem.startsWith("http://") || imagem.startsWith("https://");

    if (isNetworkImage) {
      return Image.network(
        imagem,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _imagemFallback(),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.contain,
      cacheWidth: 900,
      filterQuality: FilterQuality.low,
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
          title: const Text("Assistir vÃ­deo"),
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

  List<ExercicioModel> _exerciciosSimilares() {
    final candidatos = bancoExercicios
        .where((item) => item.id != exercicio.id)
        .where((item) => _scoreSimilar(item) > 0)
        .toList();

    candidatos.sort((a, b) => _scoreSimilar(b).compareTo(_scoreSimilar(a)));

    return candidatos.take(6).toList();
  }

  List<ExercicioModel> _substituicoesSugeridas() {
    final candidatos = bancoExercicios
        .where((item) => item.id != exercicio.id)
        .where((item) => _scoreSubstituicao(item) > 0)
        .toList();

    candidatos.sort(
      (a, b) => _scoreSubstituicao(b).compareTo(_scoreSubstituicao(a)),
    );

    return candidatos.take(6).toList();
  }

  int _scoreSimilar(ExercicioModel candidato) {
    var score = 0;

    if (_normalizar(candidato.categoria) == _normalizar(exercicio.categoria)) {
      score += 3;
    }

    score += _intersecoes(
      _musculosNormalizados(candidato),
      _musculosNormalizados(exercicio),
    );

    score += _intersecoes(
      candidato.tags.map(_normalizar).toSet(),
      exercicio.tags.map(_normalizar).toSet(),
    );

    return score;
  }

  int _scoreSubstituicao(ExercicioModel candidato) {
    var score = 0;

    if (_normalizar(candidato.categoria) == _normalizar(exercicio.categoria)) {
      score += 2;
    }

    score +=
        _intersecoes(
          candidato.equipamentos.map(_normalizar).toSet(),
          exercicio.equipamentos.map(_normalizar).toSet(),
        ) *
        2;

    if (_intersecoes(
          _musculosNormalizados(candidato),
          _musculosNormalizados(exercicio),
        ) >
        0) {
      score++;
    }

    return score;
  }

  Set<String> _musculosNormalizados(ExercicioModel item) {
    return {
      ...item.musculos.map(_normalizar),
      ...item.musculosSecundarios.map(_normalizar),
    }..removeWhere((valor) => valor.isEmpty);
  }

  int _intersecoes(Set<String> a, Set<String> b) {
    return a.where(b.contains).length;
  }

  Widget _exerciciosRelacionados({
    required String titulo,
    required String vazio,
    required List<ExercicioModel> itens,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              Text(
                vazio,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              )
            else
              Column(children: itens.map(_exercicioRelacionadoCard).toList()),
          ],
        ),
      ),
    );
  }

  Widget _exercicioRelacionadoCard(ExercicioModel item) {
    final equipamento = item.equipamentos.isEmpty
        ? null
        : item.equipamentos.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniInfoChip(item.categoria),
                    _miniInfoChip(item.dificuldade),
                    if (equipamento != null) _miniInfoChip(equipamento),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfoChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
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

  String _normalizar(String texto) {
    return texto.toLowerCase().trim();
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

class _SecaoTituloProgresso extends StatelessWidget {
  const _SecaoTituloProgresso();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.trending_up_rounded,
            color: AppColors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            "PROGRESSAO DE CARGA",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegistroProgressoSheet extends StatefulWidget {
  final ExercicioModel exercicio;
  final String titulo;
  final String acaoLabel;

  const _RegistroProgressoSheet({
    required this.exercicio,
    this.titulo = "Registrar carga",
    this.acaoLabel = "Salvar e concluir exercicio",
  });

  @override
  State<_RegistroProgressoSheet> createState() =>
      _RegistroProgressoSheetState();
}

class _RegistroProgressoSheetState extends State<_RegistroProgressoSheet> {
  final pesoController = TextEditingController();
  final seriesController = TextEditingController();
  final repeticoesController = TextEditingController();
  final descansoController = TextEditingController();
  final observacaoController = TextEditingController();

  ProgressoExercicioModel? ultimoProgresso;
  bool carregandoUltimo = true;

  @override
  void initState() {
    super.initState();
    _carregarUltimoProgresso();
  }

  @override
  void dispose() {
    pesoController.dispose();
    seriesController.dispose();
    repeticoesController.dispose();
    descansoController.dispose();
    observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarUltimoProgresso() async {
    final ultimo = await StorageService.carregarUltimoProgresso(
      widget.exercicio.nome,
    );

    if (!mounted) return;

    setState(() {
      ultimoProgresso = ultimo;
      carregandoUltimo = false;

      if (ultimo != null) {
        pesoController.text = _formatarPeso(ultimo.peso);
        seriesController.text = ultimo.series.toString();
        repeticoesController.text = ultimo.repeticoes.toString();
        if (ultimo.tempoDescanso != null && ultimo.tempoDescanso! > 0) {
          descansoController.text = ultimo.tempoDescanso.toString();
        }
      } else {
        seriesController.text = "3";
        repeticoesController.text = "10";
      }
    });
  }

  void _salvar() {
    final peso = _doubleFromController(pesoController);
    final series = int.tryParse(seriesController.text.trim()) ?? 0;
    final repeticoes = int.tryParse(repeticoesController.text.trim()) ?? 0;
    final descanso = int.tryParse(descansoController.text.trim()) ?? 0;

    if (series <= 0 || repeticoes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe series e repeticoes para salvar."),
        ),
      );
      return;
    }

    final agora = DateTime.now();

    Navigator.pop(
      context,
      ProgressoExercicioModel(
        id: "progresso_${agora.microsecondsSinceEpoch}",
        nomeExercicio: widget.exercicio.nome,
        peso: peso,
        series: series,
        repeticoes: repeticoes,
        tempoDescanso: descanso > 0 ? descanso : null,
        observacao: observacaoController.text.trim(),
        data: agora,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.titulo,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              widget.exercicio.nome,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (carregandoUltimo)
              const AppLoading(message: "Buscando ultimo registro...")
            else if (ultimoProgresso != null)
              AppGradientCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Ultimo: ${_formatarPeso(ultimoProgresso!.peso)} kg â€¢ "
                        "${ultimoProgresso!.series}x${ultimoProgresso!.repeticoes}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _campoNumero(
                    controller: pesoController,
                    label: "Peso (kg)",
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _campoNumero(
                    controller: seriesController,
                    label: "Series",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _campoNumero(controller: repeticoesController, label: "Repeticoes"),
            const SizedBox(height: 12),
            _campoNumero(
              controller: descansoController,
              label: "Descanso (segundos)",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: observacaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Observacoes",
                hintText: "Ex: boa tecnica, ultima serie dificil...",
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save_rounded),
              label: Text(widget.acaoLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoNumero({
    required TextEditingController controller,
    required String label,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
    );
  }

  double _doubleFromController(TextEditingController controller) {
    final texto = controller.text.trim().replaceAll(",", ".");
    return double.tryParse(texto) ?? 0;
  }

  String _formatarPeso(double peso) {
    if (peso == peso.roundToDouble()) return peso.round().toString();
    return peso.toStringAsFixed(1).replaceAll(".", ",");
  }
}
