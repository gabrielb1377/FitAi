import 'package:fitai/core/config/dev_data.dart';
import 'package:fitai/features/home/presentation/controllers/home_controller.dart';
import 'package:fitai/models/achievement_model.dart';
import 'package:fitai/models/coach_insight_model.dart';
import 'package:fitai/models/fitai_meta_model.dart';
import 'package:fitai/models/fitai_notification_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('usa fixtures somente quando nao ha dados locais', () async {
    final empty = await const DevDataService().resolve();

    expect(empty.useFakeUser, isTrue);
    expect(empty.useFakeWorkout, isTrue);
    expect(empty.useFakeSteps, isTrue);

    SharedPreferences.setMockInitialValues({
      'perfilNome': 'Usuario real',
      'xp': 42,
      'nivel': 2,
      'passos': 3200,
      'treinos': ['{}'],
      'historicoCorridas': ['{}'],
    });
    final real = await const DevDataService().resolve();

    expect(real.useFakeUser, isFalse);
    expect(real.useFakeProgress, isFalse);
    expect(real.useFakeWorkout, isFalse);
    expect(real.useFakeSteps, isFalse);
    expect(real.useFakeRunning, isFalse);
  });

  test(
    'controller monta Home de desenvolvimento sem chamar fontes reais',
    () async {
      const fixtures = DevRuntimeData(
        useFakeUser: true,
        useFakeProgress: true,
        useFakeWorkout: true,
        useFakeCoach: true,
        useFakeSteps: true,
        useFakeRunning: true,
        useFakeGoals: true,
        useFakeAchievements: true,
        useFakeNotifications: true,
        useFakeNutrition: true,
        useFakePremium: true,
      );
      final controller = HomeController(
        historyLoader: () async => const [],
        workoutsLoader: () async => const [],
        devDataLoader: () async => fixtures,
        coachLoader: _unexpectedCoach,
        goalsLoader: _unexpectedGoals,
        achievementsLoader: _unexpectedAchievements,
        notificationsLoader: _unexpectedNotifications,
        networkCheck: _unexpectedNetwork,
      );
      addTearDown(controller.dispose);

      await controller.load(workouts: const [], xp: 0, level: 1);

      expect(controller.state.selection.treino?.id, 'dev-upper-a');
      expect(controller.state.coachInsights, isNotEmpty);
      expect(controller.state.goals.metas, isNotEmpty);
      expect(controller.state.achievements, isNotEmpty);
      expect(controller.state.notifications, isNotEmpty);
    },
  );
}

Future<List<CoachInsightModel>> _unexpectedCoach() =>
    Future.error(StateError('coach'));

Future<FitaiMetasResumo> _unexpectedGoals() =>
    Future.error(StateError('goals'));

Future<List<AchievementModel>> _unexpectedAchievements() =>
    Future.error(StateError('achievements'));

Future<List<FitaiNotificationModel>> _unexpectedNotifications() =>
    Future.error(StateError('notifications'));

Future<bool> _unexpectedNetwork() => Future.error(StateError('network'));
