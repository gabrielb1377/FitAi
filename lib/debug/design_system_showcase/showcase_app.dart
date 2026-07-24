import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import 'pages/buttons_showcase_page.dart';
import 'pages/cards_showcase_page.dart';
import 'pages/common_showcase_page.dart';
import 'pages/activities_domain_showcase_page.dart';
import 'pages/feedback_showcase_page.dart';
import 'pages/home_domain_showcase_page.dart';
import 'pages/inputs_showcase_page.dart';
import 'pages/library_domain_showcase_page.dart';
import 'pages/navigation_showcase_page.dart';
import 'pages/nutrition_domain_showcase_page.dart';
import 'pages/plans_domain_showcase_page.dart';
import 'pages/premium_domain_showcase_page.dart';
import 'pages/profile_domain_showcase_page.dart';
import 'pages/running_domain_showcase_page.dart';
import 'pages/settings_domain_showcase_page.dart';
import 'pages/steps_domain_showcase_page.dart';
import 'pages/workout_domain_showcase_page.dart';
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
        ShowcaseRoutes.homeDomain: (_) => const HomeDomainShowcasePage(),
        ShowcaseRoutes.plansDomain: (_) => const PlansDomainShowcasePage(),
        ShowcaseRoutes.workoutDomain: (_) => const WorkoutDomainShowcasePage(),
        ShowcaseRoutes.activitiesDomain: (_) =>
            const ActivitiesDomainShowcasePage(),
        ShowcaseRoutes.runningDomain: (_) => const RunningDomainShowcasePage(),
        ShowcaseRoutes.stepsDomain: (_) => const StepsDomainShowcasePage(),
        ShowcaseRoutes.libraryDomain: (_) => const LibraryDomainShowcasePage(),
        ShowcaseRoutes.nutritionDomain: (_) =>
            const NutritionDomainShowcasePage(),
        ShowcaseRoutes.profileDomain: (_) => const ProfileDomainShowcasePage(),
        ShowcaseRoutes.premiumDomain: (_) => const PremiumDomainShowcasePage(),
        ShowcaseRoutes.settingsDomain: (_) =>
            const SettingsDomainShowcasePage(),
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
  static const homeDomain = '/domain/home';
  static const plansDomain = '/domain/plans';
  static const workoutDomain = '/domain/workout';
  static const activitiesDomain = '/domain/activities';
  static const runningDomain = '/domain/running';
  static const stepsDomain = '/domain/steps';
  static const libraryDomain = '/domain/library';
  static const nutritionDomain = '/domain/nutrition';
  static const profileDomain = '/domain/profile';
  static const premiumDomain = '/domain/premium';
  static const settingsDomain = '/domain/settings';
}
