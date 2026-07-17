import 'package:shared_preferences/shared_preferences.dart';

import 'dev_config.dart';

/// Indica quais fixtures podem aparecer sem substituir dados locais reais.
class DevRuntimeData {
  const DevRuntimeData({
    required this.useFakeUser,
    required this.useFakeProgress,
    required this.useFakeWorkout,
    required this.useFakeCoach,
    required this.useFakeSteps,
    required this.useFakeRunning,
    required this.useFakeGoals,
    required this.useFakeAchievements,
    required this.useFakeNotifications,
    required this.useFakeNutrition,
    required this.useFakePremium,
  });

  const DevRuntimeData.disabled()
    : useFakeUser = false,
      useFakeProgress = false,
      useFakeWorkout = false,
      useFakeCoach = false,
      useFakeSteps = false,
      useFakeRunning = false,
      useFakeGoals = false,
      useFakeAchievements = false,
      useFakeNotifications = false,
      useFakeNutrition = false,
      useFakePremium = false;

  final bool useFakeUser;
  final bool useFakeProgress;
  final bool useFakeWorkout;
  final bool useFakeCoach;
  final bool useFakeSteps;
  final bool useFakeRunning;
  final bool useFakeGoals;
  final bool useFakeAchievements;
  final bool useFakeNotifications;
  final bool useFakeNutrition;
  final bool useFakePremium;

  bool get useFixtureHome =>
      useFakeWorkout ||
      useFakeCoach ||
      useFakeGoals ||
      useFakeAchievements ||
      useFakeNotifications;
}

/// Le apenas a presenca de dados locais. Nunca grava fixtures no dispositivo.
class DevDataService {
  const DevDataService();

  Future<DevRuntimeData> resolve() async {
    if (!DevConfig.enabled) return const DevRuntimeData.disabled();

    final prefs = await SharedPreferences.getInstance();
    final hasUser = _hasAny(prefs, const [
      'perfilNome',
      'perfilPeso',
      'perfilAltura',
      'perfilIdade',
    ]);
    final hasProgress = _hasAny(prefs, const ['xp', 'nivel']);
    final hasWorkout = _hasEntries(prefs, 'treinos');
    final hasWorkoutHistory = _hasEntries(prefs, 'historicoTreinos');
    final hasRuns = _hasEntries(prefs, 'historicoCorridas');
    final hasSteps =
        prefs.containsKey('passos') ||
        _hasEntries(prefs, 'dailyStepsHistory') ||
        _hasEntries(prefs, 'historicoPassosDiarios');
    final hasAchievements = _hasEntries(prefs, 'conquistas');
    final hasNotifications = _hasEntries(prefs, 'fitaiNotificacoes');
    final hasFitnessData =
        hasWorkout || hasWorkoutHistory || hasRuns || hasSteps;

    return DevRuntimeData(
      useFakeUser: DevConfig.fakeUser && !hasUser,
      useFakeProgress: DevConfig.fakeUser && !hasProgress,
      useFakeWorkout: DevConfig.fakeWorkout && !hasWorkout,
      useFakeCoach: DevConfig.fakeCoach && !hasFitnessData,
      useFakeSteps: DevConfig.fakeSteps && !hasSteps,
      useFakeRunning: DevConfig.fakeRunning && !hasRuns,
      useFakeGoals: DevConfig.fakeWorkout && !hasFitnessData,
      useFakeAchievements:
          DevConfig.fakeWorkout && !hasAchievements && !hasFitnessData,
      useFakeNotifications:
          DevConfig.fakeWorkout && !hasNotifications && !hasFitnessData,
      useFakeNutrition: DevConfig.fakeNutrition,
      useFakePremium: DevConfig.fakePremium,
    );
  }

  bool _hasAny(SharedPreferences prefs, List<String> keys) {
    return keys.any(prefs.containsKey);
  }

  bool _hasEntries(SharedPreferences prefs, String key) {
    return (prefs.getStringList(key) ?? const <String>[]).isNotEmpty;
  }
}
