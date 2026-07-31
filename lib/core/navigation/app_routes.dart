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
  static const activities = '/activities';

  /// Destinos internos usados para entregar os caminhos publicos do Core V1
  /// aos Navigators aninhados. Os IDs ficam em [RouteSettings.arguments].
  static const corePlanDetail = '/plans/detail';
  static const coreWorkout = '/plans/session';
  static const coreWorkoutSummary = '/plans/completion';
  static const coreWorkoutHistory = '/activities/workout';

  static bool isCoreJourneyPath(String? value) =>
      value == home ||
      value == plans ||
      value == activities ||
      (value?.startsWith('$plans/') ?? false) ||
      (value?.startsWith('/workout/') ?? false) ||
      (value?.startsWith('$activities/workout/') ?? false);

  /// Rota de prova tecnica, protegida por `kDebugMode` no [RootRouter].
  static const debugWorkoutVerticalSlice = '/debug/offline-workout-slice';
}
