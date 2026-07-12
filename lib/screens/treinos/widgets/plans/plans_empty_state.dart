import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class PlansEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onCreateWithAi;
  final VoidCallback onCreateManually;
  final VoidCallback onExploreReadyPlans;

  const PlansEmptyState({
    super.key,
    required this.hasFilters,
    required this.onCreateWithAi,
    required this.onCreateManually,
    required this.onExploreReadyPlans,
  });

  @override
  Widget build(BuildContext context) {
    if (hasFilters) {
      return const FitEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Nenhum plano encontrado',
        description: 'Tente ajustar sua busca ou seus filtros.',
      );
    }
    return Column(
      children: [
        const FitEmptyState(
          icon: Icons.fitness_center_rounded,
          title: 'Voce ainda nao criou nenhum plano.',
          description:
              'Comece por uma criacao guiada ou escolha um plano pronto.',
        ),
        const SizedBox(height: FitSpacing.s12),
        FitButton(
          label: 'Criar com IA',
          icon: Icons.auto_awesome_rounded,
          onPressed: onCreateWithAi,
          expand: true,
        ),
        const SizedBox(height: FitSpacing.s8),
        FitButton(
          label: 'Criar manualmente',
          icon: Icons.edit_note_rounded,
          onPressed: onCreateManually,
          variant: FitButtonVariant.outlined,
          expand: true,
        ),
        const SizedBox(height: FitSpacing.s8),
        FitButton(
          label: 'Explorar planos prontos',
          icon: Icons.library_books_rounded,
          onPressed: onExploreReadyPlans,
          variant: FitButtonVariant.ghost,
          expand: true,
        ),
      ],
    );
  }
}
