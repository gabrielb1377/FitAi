import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../domain/profile_models.dart';

/// Objetivos e medidas que existem no snapshot local de Perfil.
class ProfileGoalsSection extends StatelessWidget {
  const ProfileGoalsSection({
    super.key,
    required this.snapshot,
    required this.onConfigure,
  });

  final ProfileSnapshot snapshot;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final useIconAction = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final profile = snapshot.profile;
    final goal = snapshot.goals.primaryGoal;
    final hasContent =
        profile.weightKg != null || profile.heightCm != null || goal != null;
    return FitSection(
      title: 'Objetivos',
      onViewAll: useIconAction ? null : onConfigure,
      viewAllLabel: 'Configurar',
      action: useIconAction
          ? FitIconButton(
              icon: FitIcons.edit,
              tooltip: 'Configurar objetivos',
              onPressed: onConfigure,
            )
          : null,
      child: FitCard(
        child: hasContent
            ? Column(
                children: [
                  FitHorizontalMetric(
                    label: 'Peso',
                    value: _weightLabel(profile.weightKg),
                    icon: FitIcons.weight,
                    unavailable: profile.weightKg == null,
                  ),
                  const FitDivider(verticalSpacing: FitSpacing.s12),
                  FitHorizontalMetric(
                    label: 'Altura',
                    value: _heightLabel(profile.heightCm),
                    icon: FitIcons.muscles,
                    unavailable: profile.heightCm == null,
                  ),
                  if (goal != null) ...[
                    const FitDivider(verticalSpacing: FitSpacing.s12),
                    FitHorizontalMetric(
                      label: 'Objetivo principal',
                      value: goal.titulo,
                      detail: goal.descricao,
                      icon: FitIcons.goal,
                    ),
                    const SizedBox(height: FitSpacing.s12),
                    FitProgress(
                      value: goal.progresso,
                      label: goal.categoriaLabel,
                      trailing: goal.progressoPercentual,
                      animate: true,
                    ),
                  ],
                ],
              )
            : FitEmptyState(
                icon: FitIcons.goal,
                title: 'Objetivos ainda nao definidos',
                description:
                    'Adicione suas medidas e um objetivo para acompanhar sua evolucao.',
                actionLabel: 'Configurar perfil',
                onAction: onConfigure,
              ),
      ),
    );
  }

  String _weightLabel(double? value) => value == null
      ? '--'
      : '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} kg';

  String _heightLabel(double? value) => value == null
      ? '--'
      : '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} cm';
}
