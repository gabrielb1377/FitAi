import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/auth_splash_page.dart';
import '../../features/auth/presentation/pages/initial_permissions_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/password_recovery_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../screens/dashboard_page.dart';
import 'app_routes.dart';

/// Roteador nomeado do nível raiz, fora das pilhas internas do shell.
abstract final class RootRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      AppRoutes.splash => (_) => const AuthSplashPage(),
      AppRoutes.onboarding => (_) => const OnboardingPage(),
      AppRoutes.login => (_) => const LoginPage(),
      AppRoutes.register => (_) => const RegisterPage(),
      AppRoutes.passwordRecovery => (_) => const PasswordRecoveryPage(),
      AppRoutes.permissions => (_) => const InitialPermissionsPage(),
      AppRoutes.appShell => (_) => DashboardPage(
        initialDeepLink: switch (settings.arguments) {
          final Uri uri => uri,
          _ => null,
        },
      ),
      _ => (_) => const AuthSplashPage(),
    };
    return MaterialPageRoute<dynamic>(settings: settings, builder: builder);
  }
}
