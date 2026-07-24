import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import 'pages/buttons_showcase_page.dart';
import 'pages/cards_showcase_page.dart';
import 'pages/common_showcase_page.dart';
import 'pages/feedback_showcase_page.dart';
import 'pages/inputs_showcase_page.dart';
import 'pages/navigation_showcase_page.dart';
import 'showcase_home_page.dart';

/// Aplicativo independente para inspeção manual da Component Library.
class DesignSystemShowcaseApp extends StatelessWidget {
  const DesignSystemShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitIA Component Library',
      theme: FitTheme.dark(),
      initialRoute: ShowcaseRoutes.home,
      routes: {
        ShowcaseRoutes.home: (_) => const ShowcaseHomePage(),
        ShowcaseRoutes.buttons: (_) => const ButtonsShowcasePage(),
        ShowcaseRoutes.inputs: (_) => const InputsShowcasePage(),
        ShowcaseRoutes.cards: (_) => const CardsShowcasePage(),
        ShowcaseRoutes.navigation: (_) => const NavigationShowcasePage(),
        ShowcaseRoutes.feedback: (_) => const FeedbackShowcasePage(),
        ShowcaseRoutes.common: (_) => const CommonShowcasePage(),
      },
    );
  }
}

/// Rotas locais do showcase; nenhuma é registrada no app principal.
abstract final class ShowcaseRoutes {
  static const home = '/';
  static const buttons = '/buttons';
  static const inputs = '/inputs';
  static const cards = '/cards';
  static const navigation = '/navigation';
  static const feedback = '/feedback';
  static const common = '/common';
}
