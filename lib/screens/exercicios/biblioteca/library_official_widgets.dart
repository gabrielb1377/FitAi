import 'package:flutter/material.dart';

import '../../../design_system/components/fit_search_field.dart';
import '../../../design_system/tokens/fit_colors.dart';
import '../../../design_system/tokens/fit_radius.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import '../../../models/exercicio_model.dart';
import '../../../widgets/exercicio_gif_viewer.dart';
import 'library_catalog_controller.dart';

const librarySurface = Color(0xFF101619);
const librarySurfaceMuted = Color(0xFF0D1215);
const libraryBorder = Color(0xFF202A2E);

class LibraryContentFrame extends StatelessWidget {
  const LibraryContentFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class LibraryCenteredHeader extends StatelessWidget {
  const LibraryCenteredHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: Alignment.centerLeft, child: leading),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: FitColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}

class LibrarySearchRow extends StatelessWidget {
  const LibrarySearchRow({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilter,
    this.hintText = 'Buscar exercícios...',
    this.filterCount = 0,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  final String hintText;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: FitSearchField(
                controller: controller,
                onChanged: onChanged,
                hintText: hintText,
                semanticLabel: hintText,
              ),
            ),
          ),
          const SizedBox(width: FitSpacing.s8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              LibraryIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Filtros',
                onPressed: onFilter,
              ),
              if (filterCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: FitColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$filterCount',
                      style: const TextStyle(
                        color: FitColors.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class LibraryIconButton extends StatelessWidget {
  const LibraryIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected ? FitColors.primaryContainer : librarySurface,
          shape: RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
            side: BorderSide(
              color: selected ? FitColors.primary : libraryBorder,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: FitRadius.mediumBorder,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                color: selected ? FitColors.primary : FitColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LibrarySectionHeader extends StatelessWidget {
  const LibrarySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: FitColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            key: actionKey,
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s4),
              foregroundColor: FitColors.primary,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class LibraryMuscleTile extends StatelessWidget {
  const LibraryMuscleTile({
    super.key,
    required this.group,
    required this.onTap,
    this.count,
  });

  final LibraryMuscleGroup group;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir exercícios de ${group.label}',
      child: Material(
        color: librarySurface,
        shape: const RoundedRectangleBorder(
          borderRadius: FitRadius.smallBorder,
          side: BorderSide(color: libraryBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.smallBorder,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 7, 4, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: LibraryMuscleGlyph(group: group)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    group.label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: FitColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    maxLines: 1,
                    style: const TextStyle(
                      color: FitColors.textHint,
                      fontSize: 9,
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

class LibraryMuscleGlyph extends StatelessWidget {
  const LibraryMuscleGlyph({
    super.key,
    required this.group,
    this.large = false,
  });

  final LibraryMuscleGroup group;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 116.0 : 42.0;
    final markerSize = large ? 25.0 : 10.0;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: .72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.accessibility_new_rounded,
              size: iconSize,
              color: const Color(0xFF738087),
            ),
            Align(
              alignment: group.highlight,
              child: Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  color: FitColors.primary.withAlpha(210),
                  borderRadius: BorderRadius.circular(markerSize),
                  boxShadow: [
                    BoxShadow(
                      color: FitColors.primary.withAlpha(80),
                      blurRadius: large ? 12 : 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryExerciseTile extends StatelessWidget {
  const LibraryExerciseTile({
    super.key,
    required this.exercise,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    this.compact = false,
  });

  final ExercicioModel exercise;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final difficulty = exercise.dificuldade.trim().isEmpty
        ? 'Iniciante'
        : exercise.dificuldade;
    final muscle = exercise.categoria.trim().isEmpty
        ? exercise.musculos.firstOrNull ?? 'Geral'
        : exercise.categoria;
    final expandedForText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final height = expandedForText
        ? (compact ? 88.0 : 96.0)
        : (compact ? 62.0 : 68.0);
    return Semantics(
      button: true,
      label: '${exercise.nome}, $muscle, $difficulty',
      child: Material(
        color: librarySurface,
        shape: const RoundedRectangleBorder(
          borderRadius: FitRadius.smallBorder,
          side: BorderSide(color: libraryBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaWidth = (constraints.maxWidth * .23).clamp(
                  64.0,
                  96.0,
                );
                return Row(
                  children: [
                    SizedBox(
                      width: mediaWidth,
                      height: double.infinity,
                      child: LibraryExerciseMedia(exercise: exercise),
                    ),
                    const SizedBox(width: FitSpacing.s12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FitColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            muscle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FitColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            difficulty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: libraryDifficultyColor(difficulty),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: favorite ? 'Remover dos favoritos' : 'Favoritar',
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: favorite
                            ? FitColors.warning
                            : FitColors.textSecondary,
                        size: 21,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryExerciseMedia extends StatelessWidget {
  const LibraryExerciseMedia({
    super.key,
    required this.exercise,
    this.fit = BoxFit.cover,
  });

  final ExercicioModel exercise;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF080B0D),
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF566064),
          BlendMode.multiply,
        ),
        child: ExercicioGifImage(
          imagem: exercise.imagem,
          gifPath: exercise.gifPath,
          titulo: exercise.nome,
          fit: fit,
          cacheHeight: 420,
          placeholder: const Center(
            child: Icon(
              Icons.fitness_center_rounded,
              color: FitColors.primary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class LibrarySegmentTabs<T> extends StatelessWidget {
  const LibrarySegmentTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final value in values)
          Expanded(
            child: Semantics(
              button: true,
              selected: value == selected,
              child: InkWell(
                onTap: () => onSelected(value),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            labelFor(value),
                            maxLines: 1,
                            style: TextStyle(
                              color: value == selected
                                  ? FitColors.primary
                                  : FitColors.textSecondary,
                              fontSize: 11,
                              fontWeight: value == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 2,
                      color: value == selected
                          ? FitColors.primary
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LibraryOfflineBanner extends StatelessWidget {
  const LibraryOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Biblioteca disponível offline',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s12,
          vertical: FitSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: FitColors.aiContainer,
          borderRadius: FitRadius.smallBorder,
          border: Border.all(color: FitColors.info.withAlpha(55)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_done_outlined, color: FitColors.info, size: 17),
            SizedBox(width: FitSpacing.s8),
            Expanded(
              child: Text(
                'Exercícios salvos no dispositivo.',
                style: TextStyle(
                  color: FitColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color libraryDifficultyColor(String value) {
  final normalized = normalizeLibraryText(value);
  if (normalized.contains('avanc')) return FitColors.danger;
  if (normalized.contains('inter')) return FitColors.primary;
  return const Color(0xFF52D273);
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
