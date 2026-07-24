import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/root_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FitAI());
}

class FitAI extends StatelessWidget {
  const FitAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitIA',
      theme: AppTheme.dark,
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RootRouter.onGenerateRoute,
    );
  }
}
