import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/root_router.dart';
import 'features/settings/settings.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SettingsRuntime.initialize();
  runApp(const FitAI());
}

class FitAI extends StatelessWidget {
  const FitAI({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsRuntime.controller,
      builder: (context, _) {
        final locale = SettingsRuntime
            .controller
            .state
            .snapshot
            ?.settings
            .device
            .locale
            .locale;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FitIA',
          theme: AppTheme.dark,
          locale: locale == AppLocalePreference.portugueseBrazil
              ? const Locale('pt', 'BR')
              : null,
          scrollBehavior: const AppScrollBehavior(),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: RootRouter.onGenerateRoute,
        );
      },
    );
  }
}
