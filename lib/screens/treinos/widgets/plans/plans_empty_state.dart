import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import 'plans_entrance.dart';

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
      return const PlansEntrance(
        child: FitEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Nenhum plano encontrado',
          description: 'Tente ajustar sua busca ou seus filtros.',
        ),
      );
    }
    return PlansEntrance(
      child: Semantics(
        label: 'Nenhum plano criado. Escolha como comecar.',
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: FitRadius.xLargeBorder,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: FitSpacing.s20),
            Text(
              'Seu proximo plano comeca aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: FitSpacing.s8),
            Text(
              'Crie uma rotina personalizada ou explore uma opcao pronta.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: FitSpacing.s24),
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
              label: 'Explorar biblioteca',
              icon: Icons.library_books_rounded,
              onPressed: onExploreReadyPlans,
              variant: FitButtonVariant.ghost,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}
