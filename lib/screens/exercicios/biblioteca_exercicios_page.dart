import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/exercicios/exercicios.dart';
import '../../models/exercicio_model.dart';
import '../../models/exercise_history_model.dart';
import '../../models/progresso_exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../services/storage_service.dart';
import '../../services/exercise_history_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import '../../widgets/exercicio_gif_viewer.dart';
import '../treinos/treino_em_andamento_page.dart';

class _ExercicioBuscaIndex {
  final ExercicioModel exercicio;
  final String textoBusca;
  final String categoria;
  final Set<String> musculos;
  final Set<String> equipamentos;
  final Set<String> locais;

  const _ExercicioBuscaIndex({
    required this.exercicio,
    required this.textoBusca,
    required this.categoria,
    required this.musculos,
    required this.equipamentos,
    required this.locais,
  });
}

class _BibliotecaCategoria {
  final String nome;
  final List<String> aliases;
  final IconData icon;
  final Color color;

  const _BibliotecaCategoria({
    required this.nome,
    required this.aliases,
    required this.icon,
    required this.color,
  });
}

class _ImageHint extends StatelessWidget {
  const _ImageHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(105),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_full_rounded, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            "Ampliar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterCountCard extends StatelessWidget {
  final int quantidade;

  const _FilterCountCard({required this.quantidade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$quantidade exercícios encontrados",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _heroTagExercicio(ExercicioModel exercicio) {
  final id = exercicio.id.trim().isEmpty ? exercicio.nome : exercicio.id;
  return "exercicio-gif-$id";
}

String _chaveExercicio(ExercicioModel exercicio) {
  return exercicio.id.trim().isEmpty ? exercicio.nome : exercicio.id;
}

const _recentesExerciciosKey = "fitai_exercicios_recentemente_visualizados";

extension _RecentesExerciciosStorage on StorageService {
  Future<List<String>> carregarRecentesExercicios() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_recentesExerciciosKey) ?? const <String>[])
        .take(20)
        .toList(growable: false);
  }

  Future<List<String>> registrarExercicioVisualizado(String exercicioId) async {
    final prefs = await SharedPreferences.getInstance();

    final id = exercicioId.trim();
    if (id.isEmpty) {
      return carregarRecentesExercicios();
    }

    final atuais = prefs.getStringList(_recentesExerciciosKey) ?? <String>[];

    final atualizados = <String>[
      id,
      ...atuais.where((item) => item != id),
    ].take(20).toList(growable: false);

    await prefs.setStringList(_recentesExerciciosKey, atualizados);

    return atualizados;
  }
}

class BibliotecaExerciciosPage extends StatefulWidget {
  final void Function(ExercicioModel)? onSelecionar;
  final String? categoriaInicial;

  const BibliotecaExerciciosPage({
    super.key,
    this.onSelecionar,
    this.categoriaInicial,
  });

  @override
  State<BibliotecaExerciciosPage> createState() =>
      _BibliotecaExerciciosPageState();
}

class _BibliotecaExerciciosPageState extends State<BibliotecaExerciciosPage> {
  final pesquisaController = TextEditingController();
  final storageService = StorageService();

  static const categoriasPrincipais = [
    _BibliotecaCategoria(
      nome: "Todos",
      aliases: [],
      icon: Icons.apps_rounded,
      color: AppColors.primary,
    ),
    _BibliotecaCategoria(
      nome: "Peito",
      aliases: ["Peito"],
      icon: Icons.fitness_center_rounded,
      color: AppColors.primary,
    ),
    _BibliotecaCategoria(
      nome: "Costas",
      aliases: ["Costas"],
      icon: Icons.accessibility_new_rounded,
      color: AppColors.accent1,
    ),
    _BibliotecaCategoria(
      nome: "Ombros",
      aliases: ["Ombros"],
      icon: Icons.expand_less_rounded,
      color: AppColors.accent3,
    ),
    _BibliotecaCategoria(
      nome: "Bíceps",
      aliases: ["Biceps", "Bíceps"],
      icon: Icons.sports_martial_arts_rounded,
      color: Color(0xFF00BCD4),
    ),
    _BibliotecaCategoria(
      nome: "Tríceps",
      aliases: ["Triceps", "Tríceps"],
      icon: Icons.sports_gymnastics_rounded,
      color: Color(0xFF4DD0E1),
    ),
    _BibliotecaCategoria(
      nome: "Pernas",
      aliases: ["Pernas"],
      icon: Icons.directions_walk_rounded,
      color: AppColors.accent2,
    ),
    _BibliotecaCategoria(
      nome: "Glúteos",
      aliases: ["Gluteos", "Glúteos"],
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEC407A),
    ),
    _BibliotecaCategoria(
      nome: "Abdômen",
      aliases: ["Abdomen", "Abdômen"],
      icon: Icons.self_improvement_rounded,
      color: Color(0xFFFFD54F),
    ),
    _BibliotecaCategoria(
      nome: "Cardio",
      aliases: ["Cardio"],
      icon: Icons.directions_run_rounded,
      color: Color(0xFFFF6D00),
    ),
  ];

  Timer? buscaDebounce;
  late final List<_ExercicioBuscaIndex> indiceBusca;
  late final Map<String, int> totaisPorCategoria;

  Set<String> favoritosIds = {};
  List<String> recentesIds = [];
  List<ExercicioModel> exerciciosFiltrados = [];
  String termoBusca = "";
  String termoBuscaNormalizado = "";
  String? categoriaSelecionada;
  String? localSelecionado;
  String? tipoEquipamentoSelecionado;
  String? equipamentoSelecionado;
  String? objetivoSelecionado;
  String? dificuldadeSelecionada;
  bool apenasFavoritos = false;
  bool carregandoFavoritos = true;
  bool carregandoRecentes = true;

  @override
  void initState() {
    super.initState();
    categoriaSelecionada = widget.categoriaInicial;
    indiceBusca = bancoExercicios.map(_criarIndice).toList(growable: false);
    totaisPorCategoria = _montarTotaisPorCategoria();
    exerciciosFiltrados = _filtrarExercicios();
    pesquisaController.addListener(_onBuscaAlterada);
    _carregarFavoritos();
    _carregarRecentes();
  }

  @override
  void dispose() {
    buscaDebounce?.cancel();
    pesquisaController.removeListener(_onBuscaAlterada);
    pesquisaController.dispose();
    super.dispose();
  }

  void _onBuscaAlterada() {
    buscaDebounce?.cancel();
    buscaDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      _atualizarFiltros(() {
        termoBusca = pesquisaController.text.trim();
        termoBuscaNormalizado = _normalizar(termoBusca);
      });
    });
  }

  Future<void> _carregarFavoritos() async {
    final favoritos = await StorageService.carregarFavoritosExercicios();

    if (!mounted) return;

    _sincronizarFavoritos(favoritos);

    setState(() {
      favoritosIds = favoritos;
      carregandoFavoritos = false;
      exerciciosFiltrados = _filtrarExercicios();
    });
  }

  Future<void> _carregarRecentes() async {
    final recentes = await storageService.carregarRecentesExercicios();

    if (!mounted) return;

    setState(() {
      recentesIds = recentes;
      carregandoRecentes = false;
    });
  }

  Future<void> _registrarVisualizacao(ExercicioModel exercicio) async {
    final recentes = await storageService.registrarExercicioVisualizado(
      _chaveExercicio(exercicio),
    );

    if (!mounted) return;

    setState(() {
      recentesIds = recentes;
      carregandoRecentes = false;
    });
  }

  void _sincronizarFavoritos(Set<String> favoritos) {
    for (final exercicio in bancoExercicios) {
      exercicio.favorito = favoritos.contains(exercicio.id);
    }
  }

  Future<void> _alternarFavorito(ExercicioModel exercicio) async {
    final favoritado = await StorageService.alternarFavoritoExercicio(
      exercicio.id,
    );
    final atualizados = {...favoritosIds};

    if (favoritado) {
      atualizados.add(exercicio.id);
    } else {
      atualizados.remove(exercicio.id);
    }

    _sincronizarFavoritos(atualizados);

    if (!mounted) return;

    setState(() {
      favoritosIds = atualizados;
      exerciciosFiltrados = _filtrarExercicios();
    });
  }

  void _atualizarFiltros(VoidCallback atualizar) {
    if (!mounted) return;

    setState(() {
      atualizar();
      exerciciosFiltrados = _filtrarExercicios();
    });
  }

  _ExercicioBuscaIndex _criarIndice(ExercicioModel exercicio) {
    return _ExercicioBuscaIndex(
      exercicio: exercicio,
      textoBusca: _textoBusca(exercicio),
      categoria: _normalizar(exercicio.categoria),
      musculos: _musculosDoExercicio(exercicio),
      equipamentos: _equipamentosDoExercicio(exercicio),
      locais: exercicio.locais.map(_normalizar).toSet(),
    );
  }

  List<ExercicioModel> _filtrarExercicios({
    String? categoriaFiltro,
    String? localFiltro,
    String? tipoEquipamentoFiltro,
    String? equipamentoFiltro,
    String? objetivoFiltro,
    String? dificuldadeFiltro,
    bool? apenasFavoritosFiltro,
    bool usarEstadoAtual = true,
  }) {
    final busca = termoBuscaNormalizado;
    final categoria = usarEstadoAtual
        ? categoriaFiltro ?? categoriaSelecionada
        : categoriaFiltro;
    final localSelecionadoAtual = usarEstadoAtual
        ? localFiltro ?? localSelecionado
        : localFiltro;
    final tipoEquipamento = usarEstadoAtual
        ? tipoEquipamentoFiltro ?? tipoEquipamentoSelecionado
        : tipoEquipamentoFiltro;
    final equipamentoSelecionadoAtual = usarEstadoAtual
        ? equipamentoFiltro ?? equipamentoSelecionado
        : equipamentoFiltro;
    final objetivoSelecionadoAtual = usarEstadoAtual
        ? objetivoFiltro ?? objetivoSelecionado
        : objetivoFiltro;
    final dificuldadeSelecionadaAtual = usarEstadoAtual
        ? dificuldadeFiltro ?? dificuldadeSelecionada
        : dificuldadeFiltro;
    final favoritos = usarEstadoAtual
        ? apenasFavoritosFiltro ?? apenasFavoritos
        : apenasFavoritosFiltro ?? false;
    final local = localSelecionadoAtual == null
        ? null
        : _normalizar(localSelecionadoAtual);
    final equipamento = equipamentoSelecionadoAtual == null
        ? null
        : _normalizar(equipamentoSelecionadoAtual);
    final objetivo = objetivoSelecionadoAtual == null
        ? null
        : _normalizar(objetivoSelecionadoAtual);
    final dificuldade = dificuldadeSelecionadaAtual == null
        ? null
        : _normalizar(dificuldadeSelecionadaAtual);

    return indiceBusca
        .where((item) {
          if (!_pertenceCategoria(item, categoria)) {
            return false;
          }

          if (favoritos && !favoritosIds.contains(item.exercicio.id)) {
            return false;
          }

          if (local != null && !item.locais.contains(local)) {
            return false;
          }

          if (tipoEquipamento != null &&
              !_combinaTipoEquipamento(item, tipoEquipamento)) {
            return false;
          }

          if (equipamento != null &&
              !item.equipamentos.any((valor) => valor.contains(equipamento))) {
            return false;
          }

          if (objetivo != null &&
              _normalizar(item.exercicio.objetivo) != objetivo &&
              !item.exercicio.tags.map(_normalizar).contains(objetivo)) {
            return false;
          }

          if (dificuldade != null &&
              _normalizar(item.exercicio.dificuldade) != dificuldade) {
            return false;
          }

          if (busca.isEmpty) return true;

          return item.textoBusca.contains(busca);
        })
        .map((item) => item.exercicio)
        .toList(growable: false);
  }

  Map<String, int> _montarTotaisPorCategoria() {
    final totais = <String, int>{};

    for (final categoria in categoriasPrincipais) {
      totais[categoria.nome] = categoria.nome == "Todos"
          ? indiceBusca.length
          : indiceBusca
                .where((item) => _pertenceCategoria(item, categoria.nome))
                .length;
    }

    return totais;
  }

  Future<void> _abrirDetalhe(ExercicioModel exercicio) async {
    await _registrarVisualizacao(exercicio);

    if (!mounted) return;

    final selecionado = await Navigator.push<ExercicioModel>(
      context,
      MaterialPageRoute(
        builder: (_) => BibliotecaExercicioDetalhePage(
          exercicio: exercicio,
          permitirSelecao: widget.onSelecionar != null,
        ),
      ),
    );

    await _carregarFavoritos();

    if (selecionado != null) {
      _selecionarExercicio(selecionado);
    }
  }

  void _selecionarExercicio(ExercicioModel exercicio) {
    final callback = widget.onSelecionar;
    if (callback == null) return;

    callback(exercicio);
    Navigator.pop(context);
  }

  void _limparFiltros() {
    buscaDebounce?.cancel();
    pesquisaController.removeListener(_onBuscaAlterada);
    pesquisaController.clear();
    pesquisaController.addListener(_onBuscaAlterada);

    _atualizarFiltros(() {
      termoBusca = "";
      termoBuscaNormalizado = "";
      localSelecionado = null;
      tipoEquipamentoSelecionado = null;
      equipamentoSelecionado = null;
      objetivoSelecionado = null;
      dificuldadeSelecionada = null;
      apenasFavoritos = false;
    });
  }

  void _limparFiltrosFavoritos() {
    buscaDebounce?.cancel();
    pesquisaController.removeListener(_onBuscaAlterada);
    pesquisaController.clear();
    pesquisaController.addListener(_onBuscaAlterada);

    _atualizarFiltros(() {
      termoBusca = "";
      termoBuscaNormalizado = "";
      categoriaSelecionada = null;
      localSelecionado = null;
      tipoEquipamentoSelecionado = null;
      equipamentoSelecionado = null;
      objetivoSelecionado = null;
      dificuldadeSelecionada = null;
      apenasFavoritos = true;
    });
  }

  void _limparBusca() {
    buscaDebounce?.cancel();
    pesquisaController.removeListener(_onBuscaAlterada);
    pesquisaController.clear();
    pesquisaController.addListener(_onBuscaAlterada);

    _atualizarFiltros(() {
      termoBusca = "";
      termoBuscaNormalizado = "";
    });
  }

  void _abrirCategoria(String categoria) {
    _atualizarFiltros(() {
      categoriaSelecionada = categoria == "Todos" ? null : categoria;
    });
  }

  void _selecionarAbaBiblioteca(bool favoritos) {
    _atualizarFiltros(() {
      apenasFavoritos = favoritos;
      if (favoritos) categoriaSelecionada = null;
    });
  }

  void _voltarParaCategorias() {
    _atualizarFiltros(() {
      categoriaSelecionada = null;
      localSelecionado = null;
      tipoEquipamentoSelecionado = null;
      equipamentoSelecionado = null;
      objetivoSelecionado = null;
      dificuldadeSelecionada = null;
      apenasFavoritos = false;
    });
  }

  bool get _temFiltroAtivo {
    return termoBusca.isNotEmpty ||
        apenasFavoritos ||
        localSelecionado != null ||
        tipoEquipamentoSelecionado != null ||
        equipamentoSelecionado != null ||
        objetivoSelecionado != null ||
        dificuldadeSelecionada != null;
  }

  // ignore: unused_element
  bool get _mostrandoResultados {
    return categoriaSelecionada != null || _temFiltroAtivo;
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = _horizontalPadding(context);
    final titulo = apenasFavoritos
        ? "Favoritos"
        : categoriaSelecionada ?? "Biblioteca";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titulo),
        leading: categoriaSelecionada != null && widget.categoriaInicial == null
            ? IconButton(
                onPressed: _voltarParaCategorias,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: "Voltar para categorias",
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarFavoritos,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBusca(),
                    const SizedBox(height: 16),
                    _buildAbasBiblioteca(),
                    const SizedBox(height: 16),
                    _buildRecentementeVisualizados(),
                    const SizedBox(height: 16),
                    _buildCategorias(),
                    const SizedBox(height: 14),
                    _buildResumoCategoria(),
                  ],
                ),
              ),
            ),
            if (carregandoFavoritos)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 32),
                sliver: SliverToBoxAdapter(child: _loadingCard()),
              )
            else if (exerciciosFiltrados.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 32),
                sliver: SliverToBoxAdapter(child: _estadoVazio()),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 32),
                sliver: _buildLista(),
              ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHero() {
    final totalTexto = _mostrandoResultados
        ? "${exerciciosFiltrados.length} encontrados"
        : "${bancoExercicios.length} exercícios";
    final subtitulo = categoriaSelecionada == null
        ? "Explore por grupos, equipamentos e objetivos."
        : "Descubra variações para $categoriaSelecionada.";

    return AppGradientCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.view_carousel_rounded,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BIBLIOTECA",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalTexto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subtitulo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(
                label: "${categoriasPrincipais.length} categorias",
                icon: Icons.grid_view_rounded,
              ),
              AppChip(
                label: "${favoritosIds.length} favoritos",
                icon: Icons.star_rounded,
                color: AppColors.accent2,
              ),
              const AppChip(
                label: "GIFs guiados",
                icon: Icons.play_circle_outline_rounded,
                color: AppColors.accent1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusca() {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(45),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: pesquisaController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Buscar exercício",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: termoBusca.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _limparBusca,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: "Limpar busca",
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _topActionButton(
          icon: Icons.tune_rounded,
          tooltip: "Filtros",
          selected: _temFiltroAtivo,
          onTap: _abrirFiltrosPremium,
        ),
        const SizedBox(width: 10),
        _topActionButton(
          icon: apenasFavoritos
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          tooltip: "Favoritos",
          selected: apenasFavoritos,
          onTap: () => _selecionarAbaBiblioteca(!apenasFavoritos),
        ),
      ],
    );
  }

  Widget _buildAbasBiblioteca() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _abaBiblioteca(
              label: "Todos",
              count: bancoExercicios.length,
              icon: Icons.grid_view_rounded,
              selected: !apenasFavoritos,
              onTap: () => _selecionarAbaBiblioteca(false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _abaBiblioteca(
              label: "Favoritos",
              count: favoritosIds.length,
              icon: Icons.star_rounded,
              selected: apenasFavoritos,
              onTap: () => _selecionarAbaBiblioteca(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _abaBiblioteca({
    required String label,
    required int count,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.black : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  "$label ($count)",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentementeVisualizados() {
    final recentes = _exerciciosRecentes();

    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recentemente visualizados",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Os últimos 20 exercícios que você abriu.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (recentes.isNotEmpty) _miniChip("${recentes.length}/20"),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: carregandoRecentes
                ? _recentesLoading()
                : recentes.isEmpty
                ? _recentesVazio()
                : SizedBox(
                    key: const ValueKey("recentes-lista"),
                    height: 156,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: recentes.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return _recenteCard(recentes[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _recentesLoading() {
    return Container(
      key: const ValueKey("recentes-loading"),
      height: 92,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
    );
  }

  Widget _recentesVazio() {
    return Container(
      key: const ValueKey("recentes-vazio"),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility_outlined, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Abra um exercício para montar seu histórico de visualização.",
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recenteCard(ExercicioModel exercicio) {
    final equipamento = exercicio.equipamentos.isEmpty
        ? "Peso corporal"
        : exercicio.equipamentos.first;

    return SizedBox(
      width: 190,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirDetalhe(exercicio),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withAlpha(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 72,
                    width: double.infinity,
                    child: _imagemExercicio(exercicio),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  exercicio.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  "${exercicio.categoria} • $equipamento",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ExercicioModel> _exerciciosRecentes() {
    final porChave = {
      for (final exercicio in bancoExercicios)
        _chaveExercicio(exercicio): exercicio,
    };

    return recentesIds
        .map((id) => porChave[id])
        .whereType<ExercicioModel>()
        .take(20)
        .toList(growable: false);
  }

  Widget _topActionButton({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 56,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withAlpha(42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(34),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: selected ? Colors.black : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFiltrosPremium() async {
    var grupoTemp = categoriaSelecionada;
    var equipamentoTemp = equipamentoSelecionado;
    var tipoEquipamentoTemp = tipoEquipamentoSelecionado;
    var objetivoTemp = objetivoSelecionado;
    var dificuldadeTemp = dificuldadeSelecionada;
    var localTemp = localSelecionado;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final quantidade = _filtrarExercicios(
              categoriaFiltro: grupoTemp,
              localFiltro: localTemp,
              tipoEquipamentoFiltro: tipoEquipamentoTemp,
              equipamentoFiltro: equipamentoTemp,
              objetivoFiltro: objetivoTemp,
              dificuldadeFiltro: dificuldadeTemp,
              apenasFavoritosFiltro: apenasFavoritos,
              usarEstadoAtual: false,
            ).length;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Filtros premium",
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Refine a biblioteca por treino, local e nível.",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _FilterCountCard(quantidade: quantidade),
                      const SizedBox(height: 18),
                      _filterSection(
                        title: "Grupo muscular",
                        options: categoriasPrincipais
                            .map((categoria) => categoria.nome)
                            .toList(),
                        selected: grupoTemp ?? "Todos",
                        onSelected: (value) {
                          modalSetState(() {
                            grupoTemp = value == "Todos" ? null : value;
                          });
                        },
                      ),
                      _filterSection(
                        title: "Equipamento",
                        options: const [
                          "Todos",
                          "Peso corporal",
                          "Halteres",
                          "Barra",
                          "Polia",
                          "Máquina",
                          "Peso livre",
                          "Banco",
                          "Elástico",
                        ],
                        selected:
                            tipoEquipamentoTemp ?? equipamentoTemp ?? "Todos",
                        onSelected: (value) {
                          modalSetState(() {
                            if (value == "Todos") {
                              equipamentoTemp = null;
                              tipoEquipamentoTemp = null;
                            } else if (value == "Máquina") {
                              equipamentoTemp = null;
                              tipoEquipamentoTemp = "Maquina";
                            } else if (value == "Peso livre") {
                              equipamentoTemp = null;
                              tipoEquipamentoTemp = "Peso Livre";
                            } else {
                              equipamentoTemp = value;
                              tipoEquipamentoTemp = null;
                            }
                          });
                        },
                      ),
                      _filterSection(
                        title: "Objetivo",
                        options: const [
                          "Todos",
                          "Hipertrofia",
                          "Força",
                          "Emagrecimento",
                          "Resistência",
                          "Mobilidade",
                        ],
                        selected: objetivoTemp ?? "Todos",
                        onSelected: (value) {
                          modalSetState(() {
                            objetivoTemp = value == "Todos" ? null : value;
                          });
                        },
                      ),
                      _filterSection(
                        title: "Dificuldade",
                        options: const [
                          "Todos",
                          "Iniciante",
                          "Intermediário",
                          "Avançado",
                        ],
                        selected: dificuldadeTemp ?? "Todos",
                        onSelected: (value) {
                          modalSetState(() {
                            dificuldadeTemp = value == "Todos" ? null : value;
                          });
                        },
                      ),
                      _filterSection(
                        title: "Local",
                        options: const [
                          "Todos",
                          "Casa",
                          "Academia",
                          "Ar livre",
                        ],
                        selected: localTemp ?? "Todos",
                        onSelected: (value) {
                          modalSetState(() {
                            localTemp = value == "Todos" ? null : value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                modalSetState(() {
                                  grupoTemp = null;
                                  equipamentoTemp = null;
                                  tipoEquipamentoTemp = null;
                                  objetivoTemp = null;
                                  dificuldadeTemp = null;
                                  localTemp = null;
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text("Limpar"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _atualizarFiltros(() {
                                  categoriaSelecionada = grupoTemp;
                                  equipamentoSelecionado = equipamentoTemp;
                                  tipoEquipamentoSelecionado =
                                      tipoEquipamentoTemp;
                                  objetivoSelecionado = objetivoTemp;
                                  dificuldadeSelecionada = dificuldadeTemp;
                                  localSelecionado = localTemp;
                                });
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: Text("Ver $quantidade"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterSection({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = _normalizar(option) == _normalizar(selected);

              return ChoiceChip(
                selected: isSelected,
                label: Text(option),
                onSelected: (_) => onSelected(option),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withAlpha(18),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoriasPrincipais.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria = categoriasPrincipais[index];
          final selected =
              (categoria.nome == "Todos" && categoriaSelecionada == null) ||
              categoriaSelecionada == categoria.nome;

          return _categoriaPill(categoria, selected: selected);
        },
      ),
    );
  }

  Widget _categoriaPill(
    _BibliotecaCategoria categoria, {
    required bool selected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _abrirCategoria(categoria.nome),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withAlpha(35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                categoria.icon,
                size: 16,
                color: selected ? Colors.black : categoria.color,
              ),
              const SizedBox(width: 7),
              Text(
                categoria.nome,
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _categoriaCard(_BibliotecaCategoria categoria) {
    final total = totaisPorCategoria[categoria.nome] ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _abrirCategoria(categoria.nome),
      child: AppGradientCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: categoria.color.withAlpha(28),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(categoria.icon, color: categoria.color, size: 24),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withAlpha(90),
                ),
              ],
            ),
            const Spacer(),
            Text(
              categoria.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$total exercícios",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAcessoRapido() {
    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Acesso rápido",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip(
                  label: "Favoritos",
                  selected: apenasFavoritos,
                  icon: Icons.star_rounded,
                  onTap: () {
                    _atualizarFiltros(() {
                      apenasFavoritos = !apenasFavoritos;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Casa",
                  selected: localSelecionado == "Casa",
                  icon: Icons.home_rounded,
                  onTap: () => _selecionarLocal("Casa"),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Academia",
                  selected: localSelecionado == "Academia",
                  icon: Icons.apartment_rounded,
                  onTap: () => _selecionarLocal("Academia"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCategoria() {
    final categoria = categoriaSelecionada;
    final texto = apenasFavoritos
        ? categoria == null
              ? "Favoritos"
              : "Favoritos em $categoria"
        : categoria == null
        ? "Resultados da busca"
        : "Explorando $categoria";
    final categoriaConfig = categoria == null
        ? null
        : _categoriaPorNome(categoria);
    final resumo = apenasFavoritos
        ? "${exerciciosFiltrados.length} favoritos salvos"
        : "${exerciciosFiltrados.length} exercícios disponíveis";
    final icon = apenasFavoritos
        ? Icons.star_rounded
        : categoriaConfig?.icon ?? Icons.inventory_2_rounded;
    final color = apenasFavoritos
        ? AppColors.accent2
        : categoriaConfig?.color ?? AppColors.primary;

    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
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
                  resumo,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (categoriaSelecionada != null && widget.categoriaInicial == null)
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: _voltarParaCategorias,
                tooltip: "Categorias",
                icon: const Icon(Icons.grid_view_rounded),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFiltros() {
    final filtrosAtivos = _temFiltroAtivo;

    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Filtros",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (filtrosAtivos)
                TextButton(
                  onPressed: _limparFiltros,
                  child: const Text("Limpar"),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip(
                  label: "Favoritos",
                  selected: apenasFavoritos,
                  icon: Icons.star_rounded,
                  onTap: () {
                    _atualizarFiltros(() {
                      apenasFavoritos = !apenasFavoritos;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Casa",
                  selected: localSelecionado == "Casa",
                  icon: Icons.home_rounded,
                  onTap: () => _selecionarLocal("Casa"),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Academia",
                  selected: localSelecionado == "Academia",
                  icon: Icons.apartment_rounded,
                  onTap: () => _selecionarLocal("Academia"),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Máquina",
                  selected: tipoEquipamentoSelecionado == "Maquina",
                  icon: Icons.precision_manufacturing_rounded,
                  onTap: () => _selecionarTipoEquipamento("Maquina"),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Peso livre",
                  selected: tipoEquipamentoSelecionado == "Peso Livre",
                  icon: Icons.fitness_center_rounded,
                  onTap: () => _selecionarTipoEquipamento("Peso Livre"),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Iniciante",
                  selected: dificuldadeSelecionada == "Iniciante",
                  icon: Icons.looks_one_rounded,
                  onTap: () => _selecionarDificuldade("Iniciante"),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Intermediário",
                  selected: dificuldadeSelecionada == "Intermediario",
                  icon: Icons.looks_two_rounded,
                  onTap: () => _selecionarDificuldade("Intermediario"),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: "Avançado",
                  selected: dificuldadeSelecionada == "Avancado",
                  icon: Icons.workspace_premium_rounded,
                  onTap: () => _selecionarDificuldade("Avancado"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return ChoiceChip(
      selected: selected,
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? Colors.black : Colors.white70,
            ),
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : const Color(0xFF2A2A2A),
      ),
    );
  }

  Widget _buildLista() {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.crossAxisExtent >= 1180
            ? 3
            : constraints.crossAxisExtent >= 760
            ? 2
            : 1;
        final linhas = (exerciciosFiltrados.length / colunas).ceil();

        return SliverList.builder(
          itemCount: linhas,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLinhaExercicio(index * colunas, colunas),
            );
          },
        );
      },
    );
  }

  Widget _buildLinhaExercicio(int inicio, int colunas) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var offset = 0; offset < colunas; offset++) ...[
          Expanded(
            child: inicio + offset < exerciciosFiltrados.length
                ? _exercicioCard(
                    exerciciosFiltrados[inicio + offset],
                    inicio + offset,
                  )
                : const SizedBox.shrink(),
          ),
          if (offset < colunas - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _exercicioCard(ExercicioModel exercicio, int index) {
    final favorito = favoritosIds.contains(exercicio.id);
    final equipamento = exercicio.equipamentos.isEmpty
        ? "Peso corporal"
        : exercicio.equipamentos.first;
    final locais = exercicio.locais.isEmpty
        ? "Local livre"
        : exercicio.locais.join(" / ");

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.normal + Duration(milliseconds: (index % 6) * 25),
      curve: AppMotion.curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirDetalhe(exercicio),
        child: AppGradientCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: _heroTagExercicio(exercicio),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => mostrarGifExercicioTelaCheia(
                      context,
                      imagem: exercicio.imagem,
                      titulo: exercicio.nome,
                      subtitulo: exercicio.categoria,
                    ),
                    child: SizedBox(
                      height: 198,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _imagemExercicio(exercicio),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _overlayPill(exercicio.categoria),
                          ),
                          const Positioned(
                            right: 12,
                            bottom: 12,
                            child: _ImageHint(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        exercicio.nome.isEmpty ? "?" : exercicio.nome[0],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
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
                          exercicio.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${exercicio.categoria} • ${exercicio.dificuldade}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: IconButton(
                      onPressed: () => _alternarFavorito(exercicio),
                      tooltip: favorito ? "Remover favorito" : "Favoritar",
                      icon: Icon(
                        favorito
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                      ),
                      color: favorito ? AppColors.accent2 : Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                exercicio.descricao.isEmpty
                    ? "$equipamento • ${exercicio.dificuldade}"
                    : exercicio.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _miniChip(equipamento),
                  _miniChip(locais),
                  _miniChip(exercicio.dificuldade),
                  if (exercicio.caloriasHora > 0)
                    _miniChip("${exercicio.caloriasHora} kcal/h"),
                ],
              ),
              if (exercicio.musculos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  exercicio.musculos.take(3).join(" • "),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
              if (widget.onSelecionar != null) ...[
                const SizedBox(height: 14),
                AppButton.secondary(
                  onPressed: () => _selecionarExercicio(exercicio),
                  icon: Icons.add_rounded,
                  label: "Adicionar",
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayPill(String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170, minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(32)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _miniChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2A2A2A)),
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

  Widget _imagemExercicio(ExercicioModel exercicio) {
    final imagem = exercicio.imagem.trim();
    if (imagem.isEmpty) return _imagemFallback(exercicio);

    final network =
        imagem.startsWith("http://") || imagem.startsWith("https://");

    if (network) {
      return Container(
        color: Colors.black12,
        child: Image.network(
          imagem,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => _imagemFallback(exercicio),
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
        errorBuilder: (_, _, _) => _imagemFallback(exercicio),
      ),
    );
  }

  Widget _imagemFallback(ExercicioModel exercicio) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withAlpha(55), AppColors.surfaceVariant],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 34,
            ),
            const SizedBox(height: 8),
            Text(
              exercicio.categoria,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoVazio() {
    if (apenasFavoritos && favoritosIds.isEmpty) {
      return AppEmptyState(
        icon: Icons.star_border_rounded,
        title: "Nenhum favorito ainda",
        message:
            "Toque na estrela de um exercício para guardar seus movimentos preferidos aqui.",
        action: AppButton.secondary(
          onPressed: () => _selecionarAbaBiblioteca(false),
          icon: Icons.explore_rounded,
          label: "Explorar exercícios",
        ),
      );
    }

    if (apenasFavoritos) {
      return AppEmptyState(
        icon: Icons.star_half_rounded,
        title: "Nenhum favorito encontrado",
        message:
            "Seus favoritos existem, mas os filtros atuais esconderam os resultados.",
        action: AppButton.secondary(
          onPressed: _limparFiltrosFavoritos,
          icon: Icons.refresh_rounded,
          label: "Limpar filtros",
        ),
      );
    }

    return AppEmptyState(
      icon: Icons.search_off_rounded,
      title: "Nada encontrado",
      message:
          "Tente outro músculo, equipamento ou remova filtros para ampliar a descoberta.",
      action: AppButton.secondary(
        onPressed: _limparFiltros,
        icon: Icons.refresh_rounded,
        label: "Limpar filtros",
      ),
    );
  }

  Widget _loadingCard() {
    return const AppLoading(message: "Carregando biblioteca...");
  }

  void _selecionarLocal(String local) {
    _atualizarFiltros(() {
      localSelecionado = localSelecionado == local ? null : local;
    });
  }

  void _selecionarTipoEquipamento(String tipo) {
    _atualizarFiltros(() {
      tipoEquipamentoSelecionado = tipoEquipamentoSelecionado == tipo
          ? null
          : tipo;
    });
  }

  void _selecionarDificuldade(String dificuldade) {
    _atualizarFiltros(() {
      dificuldadeSelecionada = dificuldadeSelecionada == dificuldade
          ? null
          : dificuldade;
    });
  }

  bool _pertenceCategoria(_ExercicioBuscaIndex item, String? categoria) {
    if (categoria == null) return true;

    final config = _categoriaPorNome(categoria);
    final aliases = config?.aliases ?? [categoria];

    for (final alias in aliases.map(_normalizar)) {
      if (item.categoria == alias) return true;
      if (item.musculos.contains(alias)) return true;
    }

    return false;
  }

  _BibliotecaCategoria? _categoriaPorNome(String nome) {
    final normalizado = _normalizar(nome);

    for (final categoria in categoriasPrincipais) {
      if (_normalizar(categoria.nome) == normalizado) return categoria;
    }

    return null;
  }

  bool _combinaTipoEquipamento(_ExercicioBuscaIndex item, String tipo) {
    if (tipo == "Maquina") return _usaMaquina(item.equipamentos);
    if (tipo == "Peso Livre") return _usaPesoLivre(item.equipamentos);
    return true;
  }

  bool _usaMaquina(Set<String> equipamentos) {
    const termos = [
      "maquina",
      "polia",
      "cabo",
      "cabos",
      "smith",
      "cadeira",
      "leg press",
      "hack",
      "cross",
    ];

    return equipamentos.any(
      (equipamento) => termos.any((termo) => equipamento.contains(termo)),
    );
  }

  bool _usaPesoLivre(Set<String> equipamentos) {
    const termos = [
      "halter",
      "halteres",
      "barra",
      "anilha",
      "anilhas",
      "kettlebell",
      "peso corporal",
      "elastico",
      "faixa",
    ];

    return equipamentos.any(
      (equipamento) => termos.any((termo) => equipamento.contains(termo)),
    );
  }

  Set<String> _musculosDoExercicio(ExercicioModel exercicio) {
    return {
      ...exercicio.musculos.map(_normalizar),
      ...exercicio.musculosSecundarios.map(_normalizar),
    };
  }

  Set<String> _equipamentosDoExercicio(ExercicioModel exercicio) {
    if (exercicio.equipamentos.isEmpty) {
      return {_normalizar("Peso corporal")};
    }

    return exercicio.equipamentos.map(_normalizar).toSet();
  }

  String _textoBusca(ExercicioModel exercicio) {
    return [
      exercicio.nome,
      exercicio.categoria,
      exercicio.descricao,
      exercicio.comoExecutar,
      exercicio.dificuldade,
      exercicio.objetivo,
      ...exercicio.musculos,
      ...exercicio.musculosSecundarios,
      ...exercicio.equipamentos,
      ...exercicio.locais,
      ...exercicio.tags,
    ].map(_normalizar).join(" ");
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

class BibliotecaExercicioDetalhePage extends StatefulWidget {
  final ExercicioModel exercicio;
  final bool permitirSelecao;

  const BibliotecaExercicioDetalhePage({
    super.key,
    required this.exercicio,
    this.permitirSelecao = false,
  });

  @override
  State<BibliotecaExercicioDetalhePage> createState() =>
      _BibliotecaExercicioDetalhePageState();
}

class _BibliotecaExercicioDetalhePageState
    extends State<BibliotecaExercicioDetalhePage> {
  bool favorito = false;
  bool carregandoFavorito = true;
  late final Future<ExerciseHistorySnapshot> historicoExercicioFuture;
  late final Future<List<ProgressoExercicioModel>> progressoFuture;

  ExercicioModel get exercicio => widget.exercicio;

  @override
  void initState() {
    super.initState();
    historicoExercicioFuture = const ExerciseHistoryService()
        .loadExerciseHistory(exercicio);
    progressoFuture = _carregarProgresso(historicoExercicioFuture);
    _carregarFavorito();
  }

  Future<List<ProgressoExercicioModel>> _carregarProgresso(
    Future<ExerciseHistorySnapshot> historyFuture,
  ) async {
    final history = await historyFuture;
    return history.executions
        .expand((execution) => execution.sets)
        .map(
          (set) => ProgressoExercicioModel(
            id: set.id,
            nomeExercicio: set.nomeExercicio,
            peso: set.peso,
            series: set.serieNumero,
            repeticoes: set.repeticoes,
            tempoDescanso: set.descansoSegundos,
            observacao: set.nomeTreino,
            data: set.dataHora,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _carregarFavorito() async {
    final favoritos = await StorageService.carregarFavoritosExercicios();

    if (!mounted) return;

    setState(() {
      favorito = favoritos.contains(exercicio.id);
      exercicio.favorito = favorito;
      carregandoFavorito = false;
    });
  }

  Future<void> _alternarFavorito() async {
    final novoEstado = await StorageService.alternarFavoritoExercicio(
      exercicio.id,
    );

    if (!mounted) return;

    setState(() {
      favorito = novoEstado;
      exercicio.favorito = novoEstado;
    });
  }

  List<ExercicioModel> get semelhantes {
    final candidatos = bancoExercicios.where((item) {
      if (item.id == exercicio.id) return false;

      return _scoreSemelhanca(item) > 0;
    }).toList();

    candidatos.sort(
      (a, b) => _scoreSemelhanca(b).compareTo(_scoreSemelhanca(a)),
    );

    return candidatos.take(6).toList();
  }

  int _scoreSemelhanca(ExercicioModel candidato) {
    var score = 0;

    if (_normalizar(candidato.categoria) == _normalizar(exercicio.categoria)) {
      score += 3;
    }

    score += _intersecoes(
      _musculosDoExercicio(candidato),
      _musculosDoExercicio(exercicio),
    );

    score += _intersecoes(
      candidato.equipamentos.map(_normalizar).toSet(),
      exercicio.equipamentos.map(_normalizar).toSet(),
    );

    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(exercicio.nome)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          20,
          _horizontalPadding(context),
          32,
        ),
        children: [
          _imagemHero(),
          const SizedBox(height: 16),
          _topoDetalhe(),
          const SizedBox(height: 16),
          _acoes(),
          const SizedBox(height: 16),
          _progressoCard(),
          const SizedBox(height: 16),
          _historicoDetalhadoCard(),
          const SizedBox(height: 16),
          _secaoTexto(
            titulo: "Descrição",
            texto: exercicio.descricao.isEmpty
                ? "Descrição ainda não cadastrada."
                : exercicio.descricao,
            icon: Icons.notes_rounded,
          ),
          _secaoTexto(
            titulo: "Como executar",
            texto: exercicio.comoExecutar.isEmpty
                ? "Instruções ainda não cadastradas."
                : exercicio.comoExecutar,
            icon: Icons.playlist_add_check_rounded,
          ),
          _passosCard(),
          _secaoTexto(
            titulo: "Cuidados",
            texto: exercicio.cuidados.isEmpty
                ? "Cuidados específicos ainda nao cadastrados."
                : exercicio.cuidados,
            icon: Icons.health_and_safety_rounded,
          ),
          _chips(
            titulo: "Grupo muscular",
            itens: [_grupoMuscularPrincipal()],
            vazio: "Grupo muscular nao cadastrado.",
            icon: Icons.accessibility_new_rounded,
          ),
          _chips(
            titulo: "Equipamentos",
            itens: exercicio.equipamentos.isEmpty
                ? const ["Peso corporal"]
                : exercicio.equipamentos,
            vazio: "Equipamentos nao cadastrados.",
            icon: Icons.fitness_center_rounded,
          ),
          _chips(
            titulo: "Músculos",
            itens: [...exercicio.musculos, ...exercicio.musculosSecundarios],
            vazio: "Músculos nao cadastrados.",
            icon: Icons.hub_rounded,
          ),
          _chips(
            titulo: "Tags",
            itens: exercicio.tags,
            vazio: "Tags ainda não cadastradas.",
            icon: Icons.sell_rounded,
          ),
          _chips(
            titulo: "Dificuldade e locais",
            itens: [
              exercicio.dificuldade,
              exercicio.objetivo,
              ...exercicio.locais,
            ],
            vazio: "Dados adicionais nao cadastrados.",
            icon: Icons.tune_rounded,
          ),
          _semelhantesCard(),
        ],
      ),
    );
  }

  Widget _imagemHero() {
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
        child: Hero(
          tag: _heroTagExercicio(exercicio),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, minHeight: 180),
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imagem.isEmpty
                        ? _imagemFallbackDetalhe()
                        : _imagemDetalhe(imagem),
                    const Positioned(
                      right: 14,
                      bottom: 14,
                      child: _ImageHint(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagemDetalhe(String imagem) {
    final network =
        imagem.startsWith("http://") || imagem.startsWith("https://");

    if (network) {
      return Image.network(
        imagem,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _imagemFallbackDetalhe(),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.contain,
      cacheWidth: 900,
      filterQuality: FilterQuality.low,
      semanticLabel: exercicio.nome,
      errorBuilder: (_, _, _) => _imagemFallbackDetalhe(),
    );
  }

  Widget _imagemFallbackDetalhe() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientWorkout),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 52,
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

  Widget _topoDetalhe() {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Center(
                  child: Text(
                    exercicio.nome.isEmpty ? "?" : exercicio.nome[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GUIA DO EXERCÍCIO",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      exercicio.nome,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w900, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _grupoMuscularPrincipal(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipEscuro(exercicio.categoria),
              _chipEscuro(exercicio.dificuldade),
              _chipEscuro(
                exercicio.equipamentos.isEmpty
                    ? "Peso corporal"
                    : exercicio.equipamentos.first,
              ),
              if (exercicio.caloriasHora > 0)
                _chipEscuro("${exercicio.caloriasHora} kcal/h"),
            ],
          ),
          if (exercicio.descricao.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              exercicio.descricao,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _acoes() {
    final favoritoLabel = favorito ? "Remover favorito" : "Favoritar";

    return LayoutBuilder(
      builder: (context, constraints) {
        final ladoALado = constraints.maxWidth >= 620;
        final favoritoButton = AppButton.secondary(
          onPressed: _alternarFavorito,
          loading: carregandoFavorito,
          icon: favorito ? Icons.star_rounded : Icons.star_border_rounded,
          label: favoritoLabel,
        );
        final executarButton = AppButton.primary(
          onPressed: _executarAgora,
          icon: Icons.play_arrow_rounded,
          label: "Executar Agora",
        );
        final voltarButton = AppButton.ghost(
          onPressed: () => Navigator.pop(context),
          icon: Icons.arrow_back_rounded,
          label: "Voltar",
        );
        final adicionarButton = AppButton.primary(
          onPressed: () => Navigator.pop(context, exercicio),
          icon: Icons.add_rounded,
          label: "Adicionar a ficha",
        );

        if (widget.permitirSelecao) {
          return Column(
            children: [
              adicionarButton,
              const SizedBox(height: 10),
              executarButton,
              const SizedBox(height: 10),
              if (ladoALado)
                Row(
                  children: [
                    Expanded(child: favoritoButton),
                    const SizedBox(width: 10),
                    Expanded(child: voltarButton),
                  ],
                )
              else ...[
                favoritoButton,
                const SizedBox(height: 10),
                voltarButton,
              ],
            ],
          );
        }

        if (!ladoALado) {
          return Column(
            children: [
              executarButton,
              const SizedBox(height: 10),
              favoritoButton,
              const SizedBox(height: 10),
              voltarButton,
            ],
          );
        }

        return Column(
          children: [
            executarButton,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: favoritoButton),
                const SizedBox(width: 10),
                Expanded(child: voltarButton),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _executarAgora() async {
    final agora = DateTime.now();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreinoEmAndamentoPage(
          treino: TreinoModel(
            id: "execucao_${exercicio.id}_${agora.microsecondsSinceEpoch}",
            nome: "Treino rápido - ${exercicio.nome}",
            descricao: "Execução rápida criada pela Biblioteca de Exercícios.",
            objetivo: exercicio.objetivo,
            nivel: exercicio.dificuldade,
            tempoEstimado: 8,
            criadoPorIA: false,
            exercicios: [exercicio],
            dataCriacao: agora.toIso8601String(),
          ),
        ),
      ),
    );
  }

  Widget _historicoDetalhadoCard() {
    return FutureBuilder<ExerciseHistorySnapshot>(
      future: historicoExercicioFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading(message: 'Carregando historico...');
        }

        if (snapshot.hasError) {
          return AppGradientCard(
            child: const AppInfoRow(
              icon: Icons.error_outline_rounded,
              label: 'Historico indisponivel',
              value: 'Nao foi possivel carregar as execucoes salvas.',
              color: AppColors.accent2,
            ),
          );
        }

        final history = snapshot.data ?? const ExerciseHistorySnapshot.empty();
        if (history.executions.isEmpty) {
          return AppGradientCard(
            child: const AppInfoRow(
              icon: Icons.history_rounded,
              label: 'Nenhuma serie registrada para este exercicio.',
              value: 'Conclua series para acompanhar sua evolucao.',
              color: AppColors.accent1,
            ),
          );
        }

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _secaoTitulo('Historico', Icons.history_rounded),
              const SizedBox(height: 12),
              for (final execution in history.executions.take(5)) ...[
                AppInfoRow(
                  icon: Icons.fitness_center_rounded,
                  label:
                      '${_formatarDataCurta(execution.date)} - ${execution.workoutName}',
                  value:
                      '${execution.sets.length} series | ${_formatarPeso(execution.volume)} kg | melhor ${_formatarPeso(execution.bestSet?.peso ?? 0)} kg x ${execution.bestSet?.repeticoes ?? 0}',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _progressoCard() {
    return FutureBuilder<List<ProgressoExercicioModel>>(
      future: progressoFuture,
      builder: (context, snapshot) {
        final historico = snapshot.data ?? const <ProgressoExercicioModel>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading(message: "Carregando progressão...");
        }

        if (historico.isEmpty) {
          return AppGradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _secaoTitulo("Progressão de carga", Icons.trending_up_rounded),
                const SizedBox(height: 12),
                const AppInfoRow(
                  icon: Icons.history_rounded,
                  label: "Última carga registrada",
                  value: "Sem registro",
                  color: AppColors.accent1,
                ),
                const SizedBox(height: 12),
                const AppInfoRow(
                  icon: Icons.emoji_events_rounded,
                  label: "Recorde pessoal",
                  value: "Sem registro",
                  color: AppColors.accent2,
                ),
              ],
            ),
          );
        }

        final ultimo = historico.first;
        final recorde = historico.reduce(
          (atual, item) => item.peso > atual.peso ? item : atual,
        );

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _secaoTitulo("Progressão de carga", Icons.trending_up_rounded),
              const SizedBox(height: 12),
              AppInfoRow(
                icon: Icons.history_rounded,
                label: "Última carga registrada",
                value:
                    "${_formatarPeso(ultimo.peso)} kg • ${ultimo.series}x${ultimo.repeticoes}",
                color: AppColors.accent1,
              ),
              const SizedBox(height: 12),
              AppInfoRow(
                icon: Icons.emoji_events_rounded,
                label: "Recorde pessoal",
                value:
                    "${_formatarPeso(recorde.peso)} kg • ${_formatarDataCurta(recorde.data)}",
                color: AppColors.accent2,
              ),
              const SizedBox(height: 12),
              AppInfoRow(
                icon: Icons.trending_up_rounded,
                label: "Evolução recente",
                value: _textoEvolucao(historico),
                color: AppColors.primary,
              ),
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

  Widget _secaoTexto({
    required String titulo,
    required String texto,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secaoTitulo(titulo, icon),
            const SizedBox(height: 12),
            Text(
              texto,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passosCard() {
    final passos = _passosExecucao();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secaoTitulo("Passo a passo", Icons.format_list_numbered_rounded),
            const SizedBox(height: 14),
            for (var i = 0; i < passos.length; i++) ...[
              _passoItem(numero: i + 1, texto: passos[i]),
              if (i < passos.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _passoItem({required int numero, required String texto}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(90)),
          ),
          child: Center(
            child: Text(
              "$numero",
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
                "Passo $numero",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                texto,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _passosExecucao() {
    final partes = exercicio.comoExecutar
        .split(RegExp(r"[\n.;]+"))
        .map((item) => item.trim())
        .where((item) => item.length > 8)
        .toList();
    final fallback = [
      "Ajuste a postura inicial e prepare a amplitude do movimento.",
      "Execute o movimento de forma controlada, sem perder alinhamento.",
      "Retorne devagar a posição inicial, mantendo tensão no músculo alvo.",
      "Respire de forma constante e pare se sentir dor articular.",
    ];

    return List.generate(4, (index) {
      if (index < partes.length) return partes[index];
      return fallback[index];
    });
  }

  String _grupoMuscularPrincipal() {
    if (exercicio.musculos.isNotEmpty) {
      return exercicio.musculos.take(2).join(" / ");
    }

    return exercicio.categoria;
  }

  Widget _chips({
    required String titulo,
    required List<String> itens,
    required String vazio,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secaoTitulo(titulo, icon),
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
                children: itens.map(_chipEscuro).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _semelhantesCard() {
    final lista = semelhantes;

    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secaoTitulo("Exercícios semelhantes", Icons.auto_awesome_rounded),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            const Text(
              "Nenhum exercício semelhante encontrado.",
              style: TextStyle(color: Colors.white70),
            )
          else
            SizedBox(
              height: 146,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = lista[index];

                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(28),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withAlpha(80),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          item.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${item.categoria} • ${item.dificuldade}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _secaoTitulo(String titulo, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
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
    );
  }

  Widget _chipEscuro(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Set<String> _musculosDoExercicio(ExercicioModel exercicio) {
    return {
      ...exercicio.musculos.map(_normalizar),
      ...exercicio.musculosSecundarios.map(_normalizar),
    };
  }

  int _intersecoes(Set<String> a, Set<String> b) {
    return a.where(b.contains).length;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}

String _normalizar(String texto) {
  var valor = texto.toLowerCase().trim();
  final substituicoes = {
    "\u00e1": "a",
    "\u00e0": "a",
    "\u00e2": "a",
    "\u00e3": "a",
    "\u00e4": "a",
    "\u00e9": "e",
    "\u00ea": "e",
    "\u00e8": "e",
    "\u00eb": "e",
    "\u00ed": "i",
    "\u00ec": "i",
    "\u00ee": "i",
    "\u00ef": "i",
    "\u00f3": "o",
    "\u00f2": "o",
    "\u00f4": "o",
    "\u00f5": "o",
    "\u00f6": "o",
    "\u00fa": "u",
    "\u00f9": "u",
    "\u00fb": "u",
    "\u00fc": "u",
    "\u00e7": "c",
  };

  for (final entrada in substituicoes.entries) {
    valor = valor.replaceAll(entrada.key, entrada.value);
  }

  return valor;
}
