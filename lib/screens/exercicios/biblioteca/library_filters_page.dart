import 'package:flutter/material.dart';

import '../../../design_system/components/fit_button.dart';
import '../../../design_system/tokens/fit_colors.dart';
import '../../../design_system/tokens/fit_radius.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import 'library_catalog_controller.dart';
import 'library_official_widgets.dart';

class LibraryFiltersPage extends StatefulWidget {
  const LibraryFiltersPage({super.key, required this.initialValue});

  final LibraryFilterSelection initialValue;

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
    return Scaffold(
      backgroundColor: FitColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: LibraryContentFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LibraryCenteredHeader(
                        title: 'Filtros',
                        leading: IconButton(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        trailing: TextButton(
                          onPressed: _clearAll,
                          child: const Text('Limpar'),
                        ),
                      ),
                      const SizedBox(height: FitSpacing.s8),
                      _section(
                        title: 'Grupo muscular',
                        onClear: () => setState(
                          () =>
                              selection = selection.copyWith(muscleGroup: null),
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
                                () => selection = selection.copyWith(
                                  level: level,
                                ),
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
                        title: 'Ordenar por',
                        showClear: false,
                        children: [
                          _FilterOption(
                            label: 'A-Z',
                            selected:
                                selection.sort == LibrarySort.alphabetical,
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
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 648),
                child: FitButton(
                  label: 'Aplicar filtros',
                  onPressed: () => Navigator.of(context).pop(selection),
                  expand: true,
                ),
              ),
            ),
          ],
        ),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: libraryBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: FitColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
        color: selected ? FitColors.primaryDark : librarySurface,
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
                      ? FitColors.onPrimary
                      : FitColors.textSecondary,
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
