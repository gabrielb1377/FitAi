import 'package:flutter/material.dart';

import '../../../../../design_system/components/components.dart'
    show FitChip, FitDifficulty, FitDifficultyChip;
import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Linha compacta de exercício.
class FitExerciseCompactRow extends StatelessWidget {
  const FitExerciseCompactRow({
    super.key,
    required this.name,
    this.subtitle,
    this.media,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final Widget? media;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: name,
      subtitle: subtitle,
      leading:
          media ??
          Icon(FitIcons.exercise, color: context.colors.onSurfaceVariant),
      trailing: trailing ?? const Icon(FitIcons.forward),
      onTap: onTap,
      semanticLabel: 'Exercício $name',
    );
  }
}

/// Card de exercício para grades responsivas.
class FitExerciseGridCard extends StatelessWidget {
  const FitExerciseGridCard({
    super.key,
    required this.name,
    this.category,
    this.media,
    this.badge,
    this.onTap,
  });

  final String name;
  final String? category;
  final Widget? media;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      onTap: onTap,
      variant: onTap == null
          ? FitCardVariant.outlined
          : FitCardVariant.clickable,
      semanticLabel: 'Exercício $name',
      padding: const EdgeInsets.all(FitSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FitDomainMedia(
            aspectRatio: FitLayout.domainCompactMediaAspectRatio,
            semanticLabel: 'Execução de $name',
            child: media,
          ),
          const SizedBox(height: FitSpacing.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    if (category != null)
                      Text(
                        category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: FitSpacing.s8),
                badge!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Categoria navegável da biblioteca.
class FitExerciseCategoryCard extends StatelessWidget {
  const FitExerciseCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.countLabel,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final String? countLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: countLabel == null
          ? const Icon(FitIcons.forward)
          : Text(countLabel!, style: context.textTheme.labelMedium),
      onTap: onTap,
    );
  }
}

/// Grupo muscular navegável.
class FitMuscleGroupCard extends StatelessWidget {
  const FitMuscleGroupCard({
    super.key,
    required this.name,
    this.description,
    this.media,
    this.onTap,
  });

  final String name;
  final String? description;
  final Widget? media;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: description,
      icon: FitIcons.muscles,
      media: media,
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}

/// Equipamento navegável da biblioteca.
class FitEquipmentCard extends StatelessWidget {
  const FitEquipmentCard({
    super.key,
    required this.name,
    this.description,
    this.countLabel,
    this.onTap,
  });

  final String name;
  final String? description;
  final String? countLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: name,
      subtitle: description,
      icon: FitIcons.equipment,
      trailing: countLabel == null
          ? const Icon(FitIcons.forward)
          : Text(countLabel!, style: context.textTheme.labelMedium),
      onTap: onTap,
    );
  }
}

/// Chip de filtro específico da biblioteca.
class FitExerciseFilterChip extends StatelessWidget {
  const FitExerciseFilterChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.onSelected,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FitChip(
      label: label,
      icon: icon,
      selected: selected,
      enabled: enabled,
      onSelected: onSelected,
    );
  }
}

/// Resultado de busca de exercício.
class FitExerciseSearchResult extends StatelessWidget {
  const FitExerciseSearchResult({
    super.key,
    required this.name,
    this.matchContext,
    this.media,
    this.favorite,
    this.onTap,
  });

  final String name;
  final String? matchContext;
  final Widget? media;
  final Widget? favorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitExerciseCompactRow(
      name: name,
      subtitle: matchContext,
      media: media,
      trailing: favorite,
      onTap: onTap,
    );
  }
}

/// Botão de favorito controlado externamente.
class FitExerciseFavoriteButton extends StatelessWidget {
  const FitExerciseFavoriteButton({
    super.key,
    required this.favorite,
    this.onPressed,
  });

  final bool favorite;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FitIconButton(
      icon: favorite ? FitIcons.favoriteSelected : FitIcons.favorite,
      tooltip: favorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      onPressed: onPressed,
      semanticLabel: favorite ? 'Exercício favorito' : 'Exercício não favorito',
    );
  }
}

/// Badge de dificuldade do exercício.
class FitExerciseDifficultyBadge extends StatelessWidget {
  const FitExerciseDifficultyBadge({
    super.key,
    required this.difficulty,
    this.selected = false,
    this.onSelected,
  });

  final FitDifficulty difficulty;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FitDifficultyChip(
      difficulty: difficulty,
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Container visual para visualizador muscular fornecido pelo chamador.
class FitMuscleViewerContainer extends StatelessWidget {
  const FitMuscleViewerContainer({
    super.key,
    this.child,
    this.loading = false,
    this.fallbackLabel = 'Mapa muscular indisponível',
  });

  final Widget? child;
  final bool loading;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return FitDomainMedia(
      loading: loading,
      fallbackLabel: fallbackLabel,
      fallbackIcon: FitIcons.muscles,
      semanticLabel: 'Visualização muscular',
      child: child,
    );
  }
}

/// Passo numerado de instrução de execução.
class FitExerciseInstructionStep extends StatelessWidget {
  const FitExerciseInstructionStep({
    super.key,
    required this.index,
    required this.description,
    this.title,
  }) : assert(index > 0);

  final int index;
  final String? title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title ?? 'Passo $index',
      subtitle: description,
      leading: FitDomainStatusBadge(
        label: '$index',
        tone: FitDomainTone.primary,
      ),
    );
  }
}

/// Alerta sobre erro frequente de execução.
class FitExerciseMistakeCard extends StatelessWidget {
  const FitExerciseMistakeCard({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return FitInfoCard(
      title: title,
      description: description,
      icon: FitIcons.warning,
      tone: FitInfoCardTone.warning,
    );
  }
}

/// Alternativa segura de um exercício.
class FitExerciseAlternativeCard extends StatelessWidget {
  const FitExerciseAlternativeCard({
    super.key,
    required this.name,
    this.reason,
    this.media,
    this.onTap,
  });

  final String name;
  final String? reason;
  final Widget? media;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitExerciseCompactRow(
      name: name,
      subtitle: reason,
      media: media,
      onTap: onTap,
    );
  }
}

/// Coleção curada de exercícios.
class FitExerciseCollectionCard extends StatelessWidget {
  const FitExerciseCollectionCard({
    super.key,
    required this.title,
    this.description,
    this.media,
    this.countLabel,
    this.onTap,
  });

  final String title;
  final String? description;
  final Widget? media;
  final String? countLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: description,
      icon: FitIcons.library,
      media: media,
      tags: countLabel == null
          ? const []
          : [
              FitDomainStatusBadge(
                label: countLabel!,
                tone: FitDomainTone.neutral,
              ),
            ],
      trailing: const Icon(FitIcons.forward),
      onTap: onTap,
    );
  }
}
