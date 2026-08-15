import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../progression/progression.dart';
import '../../../settings/settings.dart';
import '../../domain/profile_models.dart';

/// Identidade, objetivo e progresso local do usuario em uma unica superficie.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.snapshot,
    required this.onEdit,
  });

  final ProfileSnapshot snapshot;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = snapshot.profile.name ?? 'Complete seu perfil';
    final primaryGoal = snapshot.progression.activeGoals.firstOrNull;
    final goal = primaryGoal == null
        ? 'Defina seu objetivo principal'
        : _goalLabel(primaryGoal.type);
    final xp = snapshot.progression.balance;
    return ListenableBuilder(
      listenable: SettingsRuntime.controller,
      builder: (context, _) {
        final units = WorkoutSettingsRuntime.units;
        final showsAlternateUnits =
            units.weight != WeightUnit.kilogram ||
            units.height != HeightUnit.centimeter;
        return Semantics(
          container: true,
          label: 'Resumo do perfil de $name',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitProfileHeader(
                name: name,
                subtitle: goal,
                padding: EdgeInsets.zero,
                avatar: Hero(
                  tag: 'fitia-profile-avatar',
                  child: FitProfileAvatar(
                    name: snapshot.profile.name,
                    onTap: onEdit,
                    semanticLabel: 'Foto de perfil de $name',
                  ),
                ),
                badge: FitLevelBadge(label: 'Nivel ${xp.currentLevel}'),
                action: FitIconButton(
                  icon: FitIcons.edit,
                  tooltip: 'Editar perfil',
                  semanticLabel: 'Editar perfil',
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(height: FitSpacing.s20),
              if (showsAlternateUnits &&
                  (snapshot.profile.weightKg != null ||
                      snapshot.profile.heightCm != null))
                Padding(
                  padding: const EdgeInsets.only(bottom: FitSpacing.s12),
                  child: Wrap(
                    spacing: FitSpacing.s12,
                    runSpacing: FitSpacing.s4,
                    children: [
                      if (snapshot.profile.weightKg case final weight?)
                        Text(
                          'Peso: ${UnitConversion.formatWeightKg(weight, units)}',
                        ),
                      if (snapshot.profile.heightCm case final height?)
                        Text(
                          'Altura: ${UnitConversion.heightFromCentimeters(height, units.height).label}',
                        ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: FitSpacing.s12,
                  runSpacing: FitSpacing.s4,
                  children: [
                    Text(
                      'Experiencia',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      '${xp.xpIntoCurrentLevel}/${xp.xpForNextLevel} XP',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FitSpacing.s8),
              FitProgress(
                value: xp.progress,
                label: 'Progresso para o proximo nivel',
                trailing: '${(xp.progress * 100).round()}%',
                animate: true,
              ),
            ],
          ),
        );
      },
    );
  }

  String _goalLabel(GoalType type) => switch (type) {
    GoalType.weeklyWorkouts => 'Treinos na semana',
    GoalType.weeklyRuns => 'Corridas na semana',
    GoalType.weeklyDistance => 'Distancia na semana',
    GoalType.dailySteps => 'Passos de hoje',
    GoalType.weeklyActiveDays => 'Dias ativos na semana',
    GoalType.monthlyFrequency => 'Atividades no mes',
  };
}
