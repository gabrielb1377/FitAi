import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

/// Lista horizontal dos IDs favoritos vindos da Biblioteca local.
class ProfileFavoritesSection extends StatelessWidget {
  const ProfileFavoritesSection({
    super.key,
    required this.favoriteIds,
    required this.onViewAll,
  });

  final Set<String> favoriteIds;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final useIconAction = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    if (favoriteIds.isEmpty) {
      return FitSection(
        title: 'Favoritos',
        child: FitCard(
          child: FitEmptyState(
            icon: FitIcons.favorite,
            title: 'Nenhum exercicio favorito',
            description: 'Os exercicios salvos na Biblioteca aparecerao aqui.',
            actionLabel: 'Abrir Biblioteca',
            onAction: onViewAll,
          ),
        ),
      );
    }
    final visible = favoriteIds.take(8).toList(growable: false);
    if (useIconAction) {
      return FitSection(
        title: 'Favoritos',
        action: FitIconButton(
          icon: FitIcons.forward,
          tooltip: 'Abrir favoritos',
          onPressed: onViewAll,
        ),
        child: Column(
          children: [
            for (final favoriteId in visible) ...[
              FitCard(
                semanticLabel: 'Exercicio favorito ${_labelFor(favoriteId)}',
                child: FitHorizontalMetric(
                  label: 'Favorito',
                  value: _labelFor(favoriteId),
                  detail: 'Biblioteca',
                  icon: FitIcons.favoriteSelected,
                ),
              ),
              if (favoriteId != visible.last)
                const SizedBox(height: FitSpacing.s12),
            ],
          ],
        ),
      );
    }
    return FitSection(
      title: 'Favoritos',
      onViewAll: onViewAll,
      child: SizedBox(
        height: FitLayout.domainQuickActionMinHeight + FitSpacing.s24,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(width: FitSpacing.s12),
          itemBuilder: (context, index) {
            final favoriteId = visible[index];
            return SizedBox(
              width: FitLayout.domainMetricMaxWidth,
              child: FitCard(
                semanticLabel: 'Exercicio favorito ${_labelFor(favoriteId)}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      FitIcons.favoriteSelected,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Text(
                      _labelFor(favoriteId),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Biblioteca',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _labelFor(String value) {
    final words = value
        .trim()
        .split(RegExp(r'[-_\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        );
    final label = words.join(' ');
    return label.isEmpty ? 'Exercicio' : label;
  }
}
