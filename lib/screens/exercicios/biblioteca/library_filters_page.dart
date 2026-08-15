import 'package:flutter/material.dart';

import '../../../design_system/components/fit_button.dart';
import '../../../design_system/tokens/fit_radius.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import 'library_catalog_controller.dart';
import 'library_official_widgets.dart';

class LibraryFiltersPage extends StatefulWidget {
  const LibraryFiltersPage({
    super.key,
    required this.initialValue,
    required this.resultCountFor,
  });

  final LibraryFilterSelection initialValue;
  final int Function(LibraryFilterSelection selection) resultCountFor;

  @override
  State<LibraryFiltersPage> createState() => _LibraryFiltersPageState();
}

class _LibraryFiltersPageState extends State<LibraryFiltersPage> {
  late LibraryFilterSelection selection;

  @override
  void initState() {
    super.initState();
    selection = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    // O container FitIA tambem reserva espaco para alca, titulo e safe area.
    // O corpo recebe uma altura menor e rolagem propria para evitar overflow.
    final height = MediaQuery.sizeOf(context).height * .48;
    final resultCount = widget.resultCountFor(selection);
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clearAll,
              child: const Text('Limpar'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('library-filters-scroll'),
              physics: const BouncingScrollPhysics(),
              child: LibraryContentFrame(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, FitSpacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(
                      title: 'Grupo muscular',
                      onClear: () => setState(
                        () => selection = selection.copyWith(muscleGroup: null),
                      ),
                      children: [
                        for (final group
                            in LibraryCatalogController.muscleGroups)
                          _FilterOption(
                            label: group.label,
                            selected: selection.muscleGroup == group.label,
                            onTap: () => setState(
                              () => selection = selection.copyWith(
                                muscleGroup: group.label,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _section(
                      title: 'Nível',
                      onClear: () => setState(
                        () => selection = selection.copyWith(level: null),
                      ),
                      children: [
                        for (final level in LibraryCatalogController.levels)
                          _FilterOption(
                            label: level,
                            selected: selection.level == level,
                            onTap: () => setState(
                              () =>
                                  selection = selection.copyWith(level: level),
                            ),
                          ),
                      ],
                    ),
                    _section(
                      title: 'Equipamento',
                      onClear: () => setState(
                        () => selection = selection.copyWith(equipment: null),
                      ),
                      children: [
                        for (final item in LibraryCatalogController.equipment)
                          _FilterOption(
                            label: item,
                            selected: selection.equipment == item,
                            onTap: () => setState(
                              () => selection = selection.copyWith(
                                equipment: item,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _section(
                      title: 'Categoria',
                      onClear: () => setState(
                        () => selection = selection.copyWith(category: null),
                      ),
                      children: [
                        for (final category
                            in LibraryCatalogController.categories)
                          _FilterOption(
                            label: category,
                            selected: selection.category == category,
                            onTap: () => setState(
                              () => selection = selection.copyWith(
                                category: category,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _section(
                      title: 'Movimento',
                      onClear: () => setState(
                        () => selection = selection.copyWith(movement: null),
                      ),
                      children: [
                        for (final movement
                            in LibraryCatalogController.movements)
                          _FilterOption(
                            label: movement,
                            selected: selection.movement == movement,
                            onTap: () => setState(
                              () => selection = selection.copyWith(
                                movement: movement,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _section(
                      title: 'Objetivo',
                      onClear: () => setState(
                        () => selection = selection.copyWith(objective: null),
                      ),
                      children: [
                        for (final objective
                            in LibraryCatalogController.objectives)
                          _FilterOption(
                            label: objective,
                            selected: selection.objective == objective,
                            onTap: () => setState(
                              () => selection = selection.copyWith(
                                objective: objective,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _section(
                      title: 'Ordenar por',
                      showClear: false,
                      children: [
                        _FilterOption(
                          label: 'A-Z',
                          selected: selection.sort == LibrarySort.alphabetical,
                          onTap: () => _setSort(LibrarySort.alphabetical),
                        ),
                        _FilterOption(
                          label: 'Mais populares',
                          selected:
                              selection.sort == LibrarySort.popular ||
                              selection.sort == LibrarySort.all,
                          onTap: () => _setSort(LibrarySort.popular),
                        ),
                        _FilterOption(
                          label: 'Recentes',
                          selected: selection.sort == LibrarySort.recent,
                          onTap: () => _setSort(LibrarySort.recent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(top: FitSpacing.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$resultCount resultados',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: FitSpacing.s8),
                FitButton(
                  label: 'Aplicar filtros',
                  onPressed: () => Navigator.of(context).pop(selection),
                  expand: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
    VoidCallback? onClear,
    bool showClear = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (showClear)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text('Todos', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: FitSpacing.s4),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }

  void _setSort(LibrarySort value) {
    setState(() => selection = selection.copyWith(sort: value));
  }

  void _clearAll() {
    setState(() => selection = const LibraryFilterSelection());
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: FitRadius.smallBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.smallBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38, minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
