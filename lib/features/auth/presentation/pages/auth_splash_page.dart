import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../auth_navigation.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_page_scaffold.dart';
import 'login_page.dart';
import 'onboarding_page.dart';

class AuthSplashPage extends StatefulWidget {
  const AuthSplashPage({super.key, this.authService, this.resolveDestination});

  final AuthService? authService;
  final Future<AuthLaunchDestination> Function()? resolveDestination;

  @override
  State<AuthSplashPage> createState() => _AuthSplashPageState();
}

class _AuthSplashPageState extends State<AuthSplashPage> {
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _continueLaunch());
  }

  Future<void> _continueLaunch() async {
    AuthLaunchDestination destination;
    try {
      destination =
          await (widget.resolveDestination ??
              (widget.authService ?? AuthService()).resolveLaunchDestination)();
    } on Object {
      destination = AuthLaunchDestination.login;
    }
    final minimumDuration = const Duration(milliseconds: 520);
    final remaining = minimumDuration - DateTime.now().difference(_startedAt);
    if (!remaining.isNegative) await Future<void>.delayed(remaining);
    if (!mounted) return;

    switch (destination) {
      case AuthLaunchDestination.onboarding:
        AuthNavigation.replaceAll(context, const OnboardingPage());
      case AuthLaunchDestination.login:
        AuthNavigation.replaceAll(context, const LoginPage());
      case AuthLaunchDestination.appShell:
        AuthNavigation.replaceWithApp(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      scrollable: false,
      alignment: Alignment.center,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: .92, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              ),
              child: Column(
                children: [
                  const AuthLogo(),
                  const SizedBox(height: 20),
                  Text(
                    'Treine com inteligencia.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 108,
              child: LinearProgressIndicator(minHeight: 3),
            ),
            const Spacer(),
            Text('FitIA 1.0.0', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
