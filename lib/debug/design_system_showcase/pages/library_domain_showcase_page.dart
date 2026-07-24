import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Biblioteca.
class LibraryDomainShowcasePage extends StatelessWidget {
  const LibraryDomainShowcasePage({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return DomainShowcaseScaffold(
      title: 'Biblioteca',
      children: [
        const FitExerciseCard(
          name: 'Supino reto',
          category: 'Peito',
          onTap: _noop,
        ),
        const FitExerciseCompactRow(
          name: 'Remada baixa',
          subtitle: 'Costas · Máquina',
          onTap: _noop,
        ),
        const FitExerciseGridCard(
          name: 'Agachamento livre',
          category: 'Pernas',
          onTap: _noop,
        ),
        const FitExerciseCategoryCard(
          title: 'Exercícios compostos',
          icon: FitIcons.workout,
          countLabel: '48',
          onTap: _noop,
        ),
        const FitMuscleGroupCard(
          name: 'Peito',
          description: '32 exercícios',
          onTap: _noop,
        ),
        const FitEquipmentCard(
          name: 'Halteres',
          countLabel: '64',
          onTap: _noop,
        ),
        const Wrap(
          spacing: FitSpacing.s8,
          children: [
            FitExerciseFilterChip(label: 'Peito', selected: true),
            FitExerciseFilterChip(label: 'Máquinas'),
          ],
        ),
        const FitExerciseSearchResult(
          name: 'Supino inclinado',
          matchContext: 'Peito · Halteres',
          favorite: FitExerciseFavoriteButton(favorite: true, onPressed: _noop),
          onTap: _noop,
        ),
        const FitExerciseFavoriteButton(favorite: false, onPressed: _noop),
        const Wrap(
          spacing: FitSpacing.s8,
          children: [
            FitExerciseDifficultyBadge(difficulty: FitDifficulty.beginner),
            FitExerciseDifficultyBadge(
              difficulty: FitDifficulty.intermediate,
              selected: true,
            ),
            FitExerciseDifficultyBadge(difficulty: FitDifficulty.advanced),
          ],
        ),
        const FitMuscleViewerContainer(),
        const FitExerciseInstructionStep(
          index: 1,
          description: 'Posicione os pés firmes e estabilize as escápulas.',
        ),
        const FitExerciseMistakeCard(
          title: 'Evite abrir os cotovelos',
          description: 'Mantenha o movimento controlado e confortável.',
        ),
        const FitExerciseAlternativeCard(
          name: 'Supino com halteres',
          reason: 'Alternativa sem barra',
          onTap: _noop,
        ),
        const FitExerciseCollectionCard(
          title: 'Favoritos para Upper',
          description: 'Coleção pessoal',
          countLabel: '12 exercícios',
          onTap: _noop,
        ),
        const DomainShowcaseStates(emptyTitle: 'Biblioteca vazia'),
      ],
    );
  }
}
