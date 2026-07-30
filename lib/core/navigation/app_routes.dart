/// Rotas raiz nomeadas do aplicativo.
///
/// Rotas internas de cada seção vivem no módulo correspondente. O shell só é
/// aberto depois que o fluxo de autenticação o autoriza.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/auth/onboarding';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const passwordRecovery = '/auth/password-recovery';
  static const permissions = '/auth/permissions';
  static const appShell = '/app';

  /// Rota de prova tecnica, protegida por `kDebugMode` no [RootRouter].
  static const debugWorkoutVerticalSlice = '/debug/offline-workout-slice';
}
