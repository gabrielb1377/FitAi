import 'package:flutter/material.dart';

import '../../../design_system/components/fit_empty_state.dart';
import '../../../design_system/tokens/fit_layout.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import '../../../models/exercicio_model.dart';
import 'library_catalog_controller.dart';
import 'library_official_widgets.dart';

typedef LibraryExerciseCallback = void Function(ExercicioModel exercise);

class LibraryHomeView extends StatelessWidget {
  const LibraryHomeView({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onOpenFilters,
    required this.onOpenExercise,
    required this.onToggleFavorite,
  });

  final LibraryCatalogController controller;
  final TextEditingController searchController;
  final VoidCallback onOpenFilters;
  final LibraryExerciseCallback onOpenExercise;
  final LibraryExerciseCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final featuredDetailsHeight = usesLargeText
        ? FitLayout.skeletonListItemHeight + FitSpacing.s24
        : FitLayout.skeletonListItemHeight;
    return SafeArea(
      bottom: false,
      child: LibraryContentFrame(
        child: CustomScrollView(
          key: const PageStorageKey('LIB-001'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: LibraryCenteredHeader(
                title: 'Biblioteca',
                subtitle: 'Encontre o exercicio certo para o seu treino.',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: FitSpacing.s12),
                child: LibrarySearchRow(
                  key: const ValueKey('library-home-search'),
                  controller: searchController,
                  onChanged: controller.updateQuery,
                  onFilter: onOpenFilters,
                  filterCount: controller.activeFilterCount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: FitSpacing.s12),
                child: LibraryQuickAccessRow(
                  favoriteCount: controller.favoriteIds.length,
                  recentCount: controller.recentExercises.length,
                  onFavorites: controller.showFavorites,
                  onRecent: controller.showRecent,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: FitSpacing.s20),
                child: LibrarySectionHeader(
                  title: 'Grupos musculares',
                  actionLabel: 'Ver todos',
                  actionKey: const ValueKey('library-groups-see-all'),
                  onAction: controller.showExplore,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: FitLayout.domainLibraryMuscleStripHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: LibraryCatalogController.muscleGroups.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: FitSpacing.s8),
                  itemBuilder: (context, index) {
                    final group = LibraryCatalogController.muscleGroups[index];
                    return SizedBox(
                      width: FitLayout.domainLibraryMuscleTileWidth,
                      child: LibraryMuscleTile(
                        group: group,
                        count: controller.countForMuscleGroup(group.label),
                        onTap: () =>
                            controller.showExplore(muscleGroup: group.label),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: FitSpacing.s20),
                child: LibrarySectionHeader(
                  title: 'Exercícios em destaque',
                  actionLabel: 'Ver todos',
                  actionKey: const ValueKey('library-featured-see-all'),
                  onAction: controller.showExplore,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    FitLayout.domainLibraryFeaturedMediaHeight +
                    featuredDetailsHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.featuredExercises.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: FitSpacing.s12),
                  itemBuilder: (context, index) {
                    final exercise = controller.featuredExercises[index];
                    return SizedBox(
                      width: FitLayout.domainLibraryFeaturedCardWidth,
                      child: LibraryFeaturedExerciseCard(
                        exercise: exercise,
                        favorite: controller.isFavorite(exercise),
                        onTap: () => onOpenExercise(exercise),
                        onFavorite: () => onToggleFavorite(exercise),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (controller.mostUsedExercises.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LibrarySectionHeader(
                    title: 'Mais usados por voce',
                    actionLabel: 'Explorar',
                    onAction: () =>
                        controller.setExploreSort(LibrarySort.popular),
                  ),
                ),
              ),
            if (controller.mostUsedExercises.isNotEmpty)
              SliverList.separated(
                itemCount: controller.mostUsedExercises.take(3).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final exercise = controller.mostUsedExercises[index];
                  return LibraryExerciseTile(
                    exercise: exercise,
                    favorite: controller.isFavorite(exercise),
                    compact: true,
                    onTap: () => onOpenExercise(exercise),
                    onFavorite: () => onToggleFavorite(exercise),
                  );
                },
              ),
            if (controller.recentExercises.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LibrarySectionHeader(
                    title: 'Recentes',
                    actionLabel: 'Ver todos',
                    onAction: controller.showRecent,
                  ),
                ),
              ),
            if (controller.recentExercises.isNotEmpty)
              SliverList.separated(
                itemCount: controller.recentExercises.take(3).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final exercise = controller.recentExercises[index];
                  return LibraryExerciseTile(
                    exercise: exercise,
                    favorite: controller.isFavorite(exercise),
                    compact: true,
                    onTap: () => onOpenExercise(exercise),
                    onFavorite: () => onToggleFavorite(exercise),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: FitSpacing.s8)),
          ],
        ),
      ),
    );
  }
}

class LibraryExploreView extends StatelessWidget {
  const LibraryExploreView({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onOpenFilters,
    required this.onOpenExercise,
    required this.onToggleFavorite,
  });

  final LibraryCatalogController controller;
  final TextEditingController searchController;
  final VoidCallback onOpenFilters;
  final LibraryExerciseCallback onOpenExercise;
  final LibraryExerciseCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final exercises = controller.visibleExercises;
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                const LibraryCenteredHeader(title: 'Explorar'),
                const SizedBox(height: 8),
                LibrarySearchRow(
                  key: const ValueKey('library-explore-search'),
                  controller: searchController,
                  onChanged: controller.updateQuery,
                  onFilter: onOpenFilters,
                  filterCount: controller.activeFilterCount,
                ),
                const SizedBox(height: 8),
                LibrarySegmentTabs<LibrarySort>(
                  values: const [
                    LibrarySort.all,
                    LibrarySort.popular,
                    LibrarySort.recent,
                    LibrarySort.alphabetical,
                  ],
                  selected: controller.filters.sort,
                  labelFor: _sortLabel,
                  onSelected: controller.setExploreSort,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: exercises.isEmpty
                      ? FitEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Nenhum exercício encontrado',
                          description:
                              'Ajuste a busca ou limpe os filtros para continuar.',
                          actionLabel: 'Limpar filtros',
                          onAction: () {
                            searchController.clear();
                            controller.clearQuery();
                            controller.clearFilters();
                          },
                        )
                      : ListView.separated(
                          key: const PageStorageKey('LIB-002'),
                          physics: const BouncingScrollPhysics(),
                          itemCount: exercises.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
                            return LibraryExerciseTile(
                              exercise: exercise,
                              favorite: controller.isFavorite(exercise),
                              compact: true,
                              onTap: () => onOpenExercise(exercise),
                              onFavorite: () => onToggleFavorite(exercise),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _sortLabel(LibrarySort value) => switch (value) {
    LibrarySort.all => 'Todos',
    LibrarySort.popular => 'Populares',
    LibrarySort.recent => 'Recentes',
    LibrarySort.alphabetical => 'A-Z',
  };
}

class LibraryFavoritesView extends StatelessWidget {
  const LibraryFavoritesView({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onOpenExercise,
    required this.onToggleFavorite,
  });

  final LibraryCatalogController controller;
  final TextEditingController searchController;
  final LibraryExerciseCallback onOpenExercise;
  final LibraryExerciseCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final exercises = controller.visibleExercises;
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                const LibraryCenteredHeader(title: 'Favoritos'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: TextField(
                    controller: searchController,
                    onChanged: controller.updateQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar favoritos...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                searchController.clear();
                                controller.clearQuery();
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: FitSpacing.s12),
                Expanded(
                  child: exercises.isEmpty
                      ? FitEmptyState(
                          icon: Icons.star_border_rounded,
                          title: 'Nenhum favorito',
                          description:
                              'Marque exercícios com a estrela para encontrá-los aqui.',
                          actionLabel: 'Explorar exercícios',
                          onAction: controller.showExplore,
                        )
                      : ListView.separated(
                          key: const PageStorageKey('LIB-008'),
                          physics: const BouncingScrollPhysics(),
                          itemCount: exercises.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
                            return LibraryExerciseTile(
                              exercise: exercise,
                              favorite: true,
                              compact: true,
                              onTap: () => onOpenExercise(exercise),
                              onFavorite: () => onToggleFavorite(exercise),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryRecentView extends StatelessWidget {
  const LibraryRecentView({
    super.key,
    required this.controller,
    required this.onOpenExercise,
    required this.onToggleFavorite,
    required this.onClearRecents,
  });

  final LibraryCatalogController controller;
  final LibraryExerciseCallback onOpenExercise;
  final LibraryExerciseCallback onToggleFavorite;
  final Future<void> Function() onClearRecents;

  @override
  Widget build(BuildContext context) {
    final exercises = controller.visibleExercises;
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                LibraryCenteredHeader(
                  title: 'Recentes',
                  trailing: exercises.isEmpty
                      ? null
                      : TextButton(
                          onPressed: () async {
                            await onClearRecents();
                          },
                          child: const Text('Limpar'),
                        ),
                  leading: LibraryIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Voltar para biblioteca',
                    onPressed: controller.showHome,
                  ),
                ),
                const SizedBox(height: FitSpacing.s12),
                Expanded(
                  child: exercises.isEmpty
                      ? FitEmptyState(
                          icon: Icons.history_rounded,
                          title: 'Nenhum exercicio recente',
                          description:
                              'Os exercicios abertos ou usados aparecerao aqui.',
                          actionLabel: 'Explorar exercicios',
                          onAction: controller.showExplore,
                        )
                      : ListView.separated(
                          key: const PageStorageKey('LIB-RECENT'),
                          physics: const BouncingScrollPhysics(),
                          itemCount: exercises.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: FitSpacing.s8),
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
                            return LibraryExerciseTile(
                              exercise: exercise,
                              favorite: controller.isFavorite(exercise),
                              compact: true,
                              onTap: () => onOpenExercise(exercise),
                              onFavorite: () => onToggleFavorite(exercise),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
