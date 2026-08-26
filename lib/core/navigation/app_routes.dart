/// Rotas raiz nomeadas do aplicativo.
///
/// Rotas internas de cada seção vivem no módulo correspondente. O shell só é
/// aberto depois que o fluxo de autenticação o autoriza.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/auth/register';
  static const passwordRecovery = '/auth/password-recovery';
  static const permissions = '/auth/permissions';
  static const appShell = '/app';

  /// Caminhos publicos do Core V1. O shell entrega o destino a navegacao da
  /// secao correspondente sem duplicar paginas raiz.
  static const home = '/home';
  static const plans = '/plans';
  static const plansCreate = '/plans/create';
  static const plansCreateWithAi = '/plans/create/ai';
  static const plansCreateManual = '/plans/create/manual';
  static const plansWeeks = '/plans/weeks';
  static const plansWorkoutDay = '/plans/workout-day';
  static const plansExercise = '/plans/exercise';
  static const plansStatistics = '/plans/statistics';
  static const activities = '/activities';
  static const activitiesTimeline = '/activities/timeline';
  static const activitiesCalendar = '/activities/calendar';
  static const activitiesRuns = '/activities/runs';
  static const activityRunDetail = '/activities/runs/detail';
  static const activitiesSteps = '/activities/steps';
  static const activityStepsByDate = '/activities/steps/date';

  /// Destinos internos usados para entregar os caminhos publicos do Core V1
  /// aos Navigators aninhados. Os IDs ficam em [RouteSettings.arguments].
  static const corePlanDetail = '/plans/detail';
  static const coreWorkout = '/plans/session';
  static const coreWorkoutSummary = '/plans/completion';
  static const corePlanHistory = '/plans/history';
  static const corePlanWorkoutHistory = '/plans/history/detail';

  /// Caminho publico legado. O parser o entrega explicitamente a Planos.
  static const legacyActivitiesWorkoutHistory = '/activities/workout';

  @Deprecated('Use corePlanWorkoutHistory; musculacao pertence a Planos.')
  static const coreWorkoutHistory = corePlanWorkoutHistory;

  static bool isCoreJourneyPath(String? value) =>
      value == home ||
      value == plans ||
      value == activities ||
      (value?.startsWith('$plans/') ?? false) ||
      (value?.startsWith('$activities/') ?? false) ||
      (value?.startsWith('/workout/') ?? false) ||
      (value?.startsWith('$legacyActivitiesWorkoutHistory/') ?? false);

  /// Rota de prova tecnica, protegida por `kDebugMode` no [RootRouter].
  static const debugWorkoutVerticalSlice = '/debug/offline-workout-slice';
}
