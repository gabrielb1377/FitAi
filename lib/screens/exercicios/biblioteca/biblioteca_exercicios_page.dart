import 'package:flutter/material.dart';

import '../../../design_system/components/fit_empty_state.dart';
import '../../../design_system/components/fit_error_state.dart';
import '../../../design_system/components/fit_skeleton.dart';
import '../../../design_system/tokens/fit_colors.dart';
import '../../../design_system/tokens/fit_radius.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import '../../../models/exercicio_model.dart';
import '../../../core/design_system/components/navigation/fit_containers.dart';
import 'library_catalog_controller.dart';
import 'library_catalog_views.dart';
import 'library_exercise_detail_page.dart';
import 'library_filters_page.dart';
import 'library_official_widgets.dart';

class BibliotecaExerciciosPage extends StatefulWidget {
  const BibliotecaExerciciosPage({
    super.key,
    this.onSelecionar,
    this.categoriaInicial,
    this.controller,
    this.offline = false,
  });

  final void Function(ExercicioModel)? onSelecionar;
  final String? categoriaInicial;

  /// Injeção opcional para testes de loading, erro e catálogo vazio.
  final LibraryCatalogController? controller;

  /// Exibe um aviso discreto sem bloquear o catálogo local.
  final bool offline;

  @override
  State<BibliotecaExerciciosPage> createState() =>
      _BibliotecaExerciciosPageState();
}

class _BibliotecaExerciciosPageState extends State<BibliotecaExerciciosPage> {
  late LibraryCatalogController _controller;
  late bool _ownsController;
  final _searchController = TextEditingController();

  bool get _isRootLibrary =>
      widget.onSelecionar == null && widget.categoriaInicial == null;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        LibraryCatalogController(initialCategory: widget.categoriaInicial);
    _controller.initialize();
  }

  @override
  void didUpdateWidget(covariant BibliotecaExerciciosPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;
    final categoryChanged =
        oldWidget.categoriaInicial != widget.categoriaInicial;
    if (!controllerChanged && !categoryChanged) return;

    if (_ownsController) _controller.dispose();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        LibraryCatalogController(initialCategory: widget.categoriaInicial);
    _controller.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        _syncSearchController();
        final interceptBack =
            _isRootLibrary && _controller.section != LibrarySection.home;
        return PopScope<void>(
          canPop: !interceptBack,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && interceptBack) {
              _searchController.clear();
              _controller.showHome();
            }
          },
          child: Scaffold(
            backgroundColor: FitColors.background,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _contentForStatus(),
            ),
          ),
        );
      },
    );
  }

  Widget _contentForStatus() {
    return switch (_controller.status) {
      LibraryLoadStatus.loading => const _LibraryCatalogSkeleton(),
      LibraryLoadStatus.error => SafeArea(
        child: FitErrorState(
          title: 'Biblioteca indisponível',
          error: 'Não foi possível carregar os exercícios.',
          details: _controller.error?.toString(),
          onRetry: _controller.retry,
        ),
      ),
      LibraryLoadStatus.empty => SafeArea(
        child: FitEmptyState(
          icon: Icons.fitness_center_rounded,
          title: 'Biblioteca vazia',
          description: 'Nenhum exercício está disponível neste dispositivo.',
          actionLabel: 'Tentar novamente',
          onAction: _controller.retry,
        ),
      ),
      LibraryLoadStatus.ready => Stack(
        children: [
          Positioned.fill(child: _readyContent()),
          if (widget.offline)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 8,
              child: LibraryOfflineBanner(),
            ),
        ],
      ),
    };
  }

  Widget _readyContent() {
    return switch (_controller.section) {
      LibrarySection.home => LibraryHomeView(
        key: const ValueKey('library-home'),
        controller: _controller,
        searchController: _searchController,
        onOpenFilters: _openFilters,
        onOpenExercise: _openExercise,
        onToggleFavorite: _toggleFavorite,
      ),
      LibrarySection.explore => LibraryExploreView(
        key: const ValueKey('library-explore'),
        controller: _controller,
        searchController: _searchController,
        onOpenFilters: _openFilters,
        onOpenExercise: _openExercise,
        onToggleFavorite: _toggleFavorite,
      ),
      LibrarySection.favorites => LibraryFavoritesView(
        key: const ValueKey('library-favorites'),
        controller: _controller,
        searchController: _searchController,
        onOpenExercise: _openExercise,
        onToggleFavorite: _toggleFavorite,
      ),
      LibrarySection.recent => LibraryRecentView(
        key: const ValueKey('library-recent'),
        controller: _controller,
        onOpenExercise: _openExercise,
        onToggleFavorite: _toggleFavorite,
      ),
    };
  }

  Future<void> _openFilters() async {
    final selected = await FitBottomSheetContainer.show<LibraryFilterSelection>(
      context: context,
      title: 'Filtros',
      subtitle: 'Refine os exercicios exibidos no dispositivo.',
      isScrollControlled: true,
      child: LibraryFiltersPage(
        initialValue: _controller.filters,
        resultCountFor: _controller.countForFilters,
      ),
    );
    if (selected != null) _controller.applyFilters(selected);
  }

  Future<void> _openExercise(ExercicioModel exercise) async {
    await _controller.registerViewed(exercise);
    if (!mounted) return;
    final selected = await Navigator.of(context).push<ExercicioModel>(
      MaterialPageRoute(
        builder: (_) => BibliotecaExercicioDetalhePage(
          exercicio: exercise,
          permitirSelecao: widget.onSelecionar != null,
          initialFavorite: _controller.isFavorite(exercise),
          onToggleFavorite: _controller.toggleFavorite,
          onOpenFavorites: _controller.showFavorites,
          relatedExercises: _controller.relatedExercises(exercise),
          onOpenRelated: _openExercise,
          onToggleRelated: _toggleFavorite,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    widget.onSelecionar?.call(selected);
    Navigator.of(context).pop();
  }

  Future<void> _toggleFavorite(ExercicioModel exercise) async {
    final favorite = await _controller.toggleFavorite(exercise);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          favorite
              ? 'Exercício adicionado aos favoritos.'
              : 'Exercício removido dos favoritos.',
        ),
        action: favorite
            ? SnackBarAction(
                label: 'Ver favoritos',
                onPressed: _controller.showFavorites,
              )
            : null,
      ),
    );
  }

  void _syncSearchController() {
    if (_searchController.text == _controller.query) return;
    _searchController.value = TextEditingValue(
      text: _controller.query,
      selection: TextSelection.collapsed(offset: _controller.query.length),
    );
  }
}

class _LibraryCatalogSkeleton extends StatelessWidget {
  const _LibraryCatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LibraryContentFrame(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 10),
            const Center(child: FitSkeleton(width: 92, height: 18)),
            const SizedBox(height: 22),
            const FitSkeleton(height: 44, borderRadius: FitRadius.mediumBorder),
            const SizedBox(height: 20),
            const FitSkeleton(width: 126, height: 14),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: .92,
              ),
              itemBuilder: (_, _) => const FitSkeleton(
                height: 72,
                borderRadius: FitRadius.smallBorder,
              ),
            ),
            const SizedBox(height: FitSpacing.s20),
            const FitSkeleton(width: 150, height: 14),
            const SizedBox(height: FitSpacing.s12),
            const FitSkeleton(height: 62, borderRadius: FitRadius.smallBorder),
            const SizedBox(height: FitSpacing.s8),
            const FitSkeleton(height: 62, borderRadius: FitRadius.smallBorder),
          ],
        ),
      ),
    );
  }
}
