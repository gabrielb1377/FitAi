import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../progression/progression.dart';
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
    return FitCard(
      semanticLabel: 'Resumo do perfil de $name',
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
          const FitDivider(verticalSpacing: FitSpacing.s12),
          Text('Experiencia', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: FitSpacing.s4),
          Text(
            '${xp.xpIntoCurrentLevel}/${xp.xpForNextLevel} XP',
            style: Theme.of(context).textTheme.titleMedium,
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
