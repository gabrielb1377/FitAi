import 'package:flutter/material.dart';

import '../../../design_system/components/fit_search_field.dart';
import '../../../design_system/tokens/fit_colors.dart';
import '../../../design_system/tokens/fit_duration.dart';
import '../../../design_system/tokens/fit_layout.dart';
import '../../../design_system/tokens/fit_opacity.dart';
import '../../../design_system/tokens/fit_radius.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import '../../../models/exercicio_model.dart';
import '../../../widgets/exercicio_gif_viewer.dart';
import 'library_catalog_controller.dart';

// Aliases de compatibilidade para telas do modulo que ainda estao migrando.
const librarySurface = FitColors.surface;
const librarySurfaceMuted = FitColors.backgroundSubtle;
const libraryBorder = FitColors.borderSubtle;

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
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FitLayout.topBarHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: FitSpacing.s8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: FitSpacing.s8),
            trailing!,
          ],
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
              height: FitLayout.minimumTouchTarget,
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
                  right: -FitSpacing.s2,
                  top: -FitSpacing.s2,
                  child: Container(
                    width: FitLayout.iconSizeCompact,
                    height: FitLayout.iconSizeCompact,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: FitColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$filterCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FitColors.onPrimary,
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
          color: selected
              ? FitColors.primaryContainer
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: FitRadius.mediumBorder,
            side: BorderSide(
              color: selected
                  ? FitColors.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: FitRadius.mediumBorder,
            child: SizedBox(
              width: FitLayout.minimumTouchTarget,
              height: FitLayout.minimumTouchTarget,
              child: Icon(
                icon,
                color: selected ? FitColors.primary : FitColors.textSecondary,
                size: FitLayout.iconSizeButton,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryQuickAccessRow extends StatelessWidget {
  const LibraryQuickAccessRow({
    super.key,
    required this.favoriteCount,
    required this.recentCount,
    required this.onFavorites,
    required this.onRecent,
  });

  final int favoriteCount;
  final int recentCount;
  final VoidCallback onFavorites;
  final VoidCallback onRecent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LibraryQuickAccess(
            icon: Icons.star_outline_rounded,
            label: 'Favoritos',
            count: favoriteCount,
            onTap: onFavorites,
          ),
        ),
        const SizedBox(width: FitSpacing.s8),
        Expanded(
          child: _LibraryQuickAccess(
            icon: Icons.history_rounded,
            label: 'Recentes',
            count: recentCount,
            onTap: onRecent,
          ),
        ),
      ],
    );
  }
}

class _LibraryQuickAccess extends StatelessWidget {
  const _LibraryQuickAccess({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$label, $count itens',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.mediumBorder,
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.mediumBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FitLayout.minimumTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FitSpacing.s12,
                vertical: FitSpacing.s8,
              ),
              child: Row(
                children: [
                  Icon(icon, size: FitLayout.iconSizeCompact),
                  const SizedBox(width: FitSpacing.s8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Text('$count', style: Theme.of(context).textTheme.labelSmall),
                ],
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
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Abrir exercícios de ${group.label}',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.smallBorder,
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.smallBorder,
          child: Padding(
            padding: const EdgeInsets.all(FitSpacing.s8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: LibraryMuscleGlyph(group: group)),
                const SizedBox(height: FitSpacing.s4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    group.label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: FitColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall,
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
    final iconSize = large
        ? FitLayout.domainProgressRingLarge
        : FitLayout.iconSizeState;
    final markerSize = large
        ? FitLayout.iconSizeMedium
        : FitLayout.iconSizeBadge;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: .72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.accessibility_new_rounded,
              size: iconSize,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Align(
              alignment: group.highlight,
              child: Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  color: FitColors.primary,
                  borderRadius: BorderRadius.circular(markerSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryFeaturedExerciseCard extends StatelessWidget {
  const LibraryFeaturedExerciseCard({
    super.key,
    required this.exercise,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
  });

  final ExercicioModel exercise;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muscle = exercise.categoria.trim().isEmpty
        ? exercise.musculos.firstOrNull ?? 'Geral'
        : exercise.categoria;
    final equipment = exercise.equipamentos.firstOrNull;
    return Semantics(
      button: true,
      label: '${exercise.nome}, $muscle',
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.largeBorder,
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: FitLayout.domainLibraryFeaturedMediaHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LibraryExerciseMedia(exercise: exercise),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(FitSpacing.s8),
                        child: Material(
                          color: colors.surface.withValues(
                            alpha: FitOpacity.scrim,
                          ),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: favorite
                                ? 'Remover dos favoritos'
                                : 'Favoritar',
                            onPressed: onFavorite,
                            icon: Icon(
                              favorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: favorite
                                  ? FitColors.warning
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(FitSpacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: FitSpacing.s4),
                    Text(
                      equipment == null ? muscle : '$muscle  •  $equipment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final colors = Theme.of(context).colorScheme;
    final difficulty = exercise.dificuldade.trim().isEmpty
        ? 'Iniciante'
        : exercise.dificuldade;
    final muscle = exercise.categoria.trim().isEmpty
        ? exercise.musculos.firstOrNull ?? 'Geral'
        : exercise.categoria;
    final expandedForText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final height = expandedForText
        ? (compact
              ? FitLayout.skeletonListItemHeight + FitSpacing.s16
              : FitLayout.skeletonListItemHeight + FitSpacing.s24)
        : (compact
              ? FitLayout.skeletonListItemHeight
              : FitLayout.skeletonListItemHeight + FitSpacing.s8);
    return Semantics(
      button: true,
      label: '${exercise.nome}, $muscle, $difficulty',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: FitRadius.smallBorder,
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaWidth = (constraints.maxWidth * .24).clamp(
                  FitLayout.avatarLarge,
                  FitLayout.domainMetricMinWidth,
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
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: FitSpacing.s4),
                          Text(
                            muscle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: FitSpacing.s2),
                          Text(
                            difficulty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: libraryDifficultyColor(difficulty),
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
                        size: FitLayout.iconSize,
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
      color: FitColors.backgroundSubtle,
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
            size: FitLayout.iconSizeMedium,
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
                      height: FitLayout.minimumTouchTarget,
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
                              fontWeight: value == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: FitDuration.fast,
                      height: FitLayout.borderFocused,
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
        child: Row(
          children: [
            const Icon(
              Icons.cloud_done_outlined,
              color: FitColors.info,
              size: FitLayout.iconSizeCompact,
            ),
            const SizedBox(width: FitSpacing.s8),
            Expanded(
              child: Text(
                'Exercícios salvos no dispositivo.',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
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
  return FitColors.success;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
