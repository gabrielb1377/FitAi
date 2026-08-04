import '../../../core/xp/xp_config.dart';
import 'progression_models.dart';

/// Politica explicita, central e configuravel de progressao do FitIA.
///
/// Os valores mantem os incentivos historicos ja presentes no produto e estao
/// marcados como provisorios na documentacao ate validacao de Produto.
abstract final class ProgressionRules {
  static const int workoutCompletionXp = XpConfig.treinoConcluido;
  static const int runCompletionXp = XpConfig.corridaConcluir;
  static const int dailyStepsGoalXp = XpConfig.passosMetaDiaria;
  static const int achievementXp = XpConfig.conquistaComum;

  static const List<GoalDefinition> defaultGoals = [
    GoalDefinition(
      type: GoalType.weeklyWorkouts,
      period: GoalPeriod.weekly,
      defaultTarget: 3,
      label: 'Treinos na semana',
    ),
    GoalDefinition(
      type: GoalType.weeklyRuns,
      period: GoalPeriod.weekly,
      defaultTarget: 3,
      label: 'Corridas na semana',
    ),
    GoalDefinition(
      type: GoalType.weeklyDistance,
      period: GoalPeriod.weekly,
      defaultTarget: 10,
      label: 'Distancia na semana',
    ),
    GoalDefinition(
      type: GoalType.dailySteps,
      period: GoalPeriod.daily,
      defaultTarget: 10000,
      label: 'Passos de hoje',
    ),
    GoalDefinition(
      type: GoalType.weeklyActiveDays,
      period: GoalPeriod.weekly,
      defaultTarget: 3,
      label: 'Dias ativos na semana',
    ),
    GoalDefinition(
      type: GoalType.monthlyFrequency,
      period: GoalPeriod.monthly,
      defaultTarget: 12,
      label: 'Atividades no mes',
    ),
  ];

  static const List<StreakDefinition> streaks = [
    StreakDefinition(type: StreakType.activeDays, label: 'Dias ativos'),
    StreakDefinition(type: StreakType.workouts, label: 'Treinos'),
    StreakDefinition(type: StreakType.stepsGoals, label: 'Metas de passos'),
    StreakDefinition(type: StreakType.runs, label: 'Corridas'),
  ];

  static const List<AchievementDefinition> achievements = [
    AchievementDefinition(
      id: 'first-workout',
      name: 'Primeiro treino',
      description: 'Conclua seu primeiro treino.',
      category: AchievementCategory.firstSteps,
      target: 1,
      xpReward: achievementXp,
      iconKey: 'workout',
    ),
    AchievementDefinition(
      id: 'workouts-10',
      name: 'Ritmo criado',
      description: 'Conclua 10 treinos.',
      category: AchievementCategory.workouts,
      target: 10,
      xpReward: achievementXp,
      iconKey: 'workout',
    ),
    AchievementDefinition(
      id: 'first-run',
      name: 'Primeira corrida',
      description: 'Conclua sua primeira corrida.',
      category: AchievementCategory.running,
      target: 1,
      xpReward: achievementXp,
      iconKey: 'running',
    ),
    AchievementDefinition(
      id: 'running-50km',
      name: '50 km acumulados',
      description: 'Acumule 50 km de corrida.',
      category: AchievementCategory.running,
      target: 50,
      xpReward: achievementXp,
      iconKey: 'running',
    ),
    AchievementDefinition(
      id: 'first-steps-goal',
      name: 'Meta de passos',
      description: 'Atinja uma meta diaria de passos.',
      category: AchievementCategory.steps,
      target: 1,
      xpReward: achievementXp,
      iconKey: 'steps',
    ),
    AchievementDefinition(
      id: 'active-streak-7',
      name: 'Sete dias ativos',
      description: 'Mantenha sete dias ativos seguidos.',
      category: AchievementCategory.consistency,
      target: 7,
      xpReward: achievementXp,
      iconKey: 'streak',
    ),
    AchievementDefinition(
      id: 'favorites-10',
      name: 'Biblioteca pessoal',
      description: 'Adicione 10 exercicios aos favoritos.',
      category: AchievementCategory.library,
      target: 10,
      xpReward: achievementXp,
      iconKey: 'library',
    ),
  ];

  /// Curva aberta equivalente aos limites historicos do `XpConfig`.
  static LevelDefinition levelForTotalXp(int totalXp) {
    var remaining = totalXp < 0 ? 0 : totalXp;
    var level = 1;
    while (remaining >= xpForNextLevel(level)) {
      remaining -= xpForNextLevel(level);
      level += 1;
    }
    return LevelDefinition(level: level, xpForNextLevel: xpForNextLevel(level));
  }

  static XpBalance balanceForTotalXp(int totalXp) {
    final definition = levelForTotalXp(totalXp);
    final previousTotal = totalXpForLevel(definition.level);
    return XpBalance(
      totalXp: totalXp < 0 ? 0 : totalXp,
      currentLevel: definition.level,
      xpIntoCurrentLevel: (totalXp - previousTotal).clamp(0, 1 << 31).toInt(),
      xpForNextLevel: definition.xpForNextLevel,
    );
  }

  static int totalXpForLevel(int level) {
    var total = 0;
    for (var item = 1; item < level; item += 1) {
      total += xpForNextLevel(item);
    }
    return total;
  }

  static int xpForNextLevel(int level) => XpConfig.xpParaProximoNivel(level);
}
