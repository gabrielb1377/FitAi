import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import 'showcase_app.dart';

/// Índice navegável dos módulos da biblioteca.
class ShowcaseHomePage extends StatelessWidget {
  const ShowcaseHomePage({super.key});

  static const _entries = <_ShowcaseEntry>[
    _ShowcaseEntry('Buttons', ShowcaseRoutes.buttons, FitIcons.add),
    _ShowcaseEntry('Inputs', ShowcaseRoutes.inputs, FitIcons.edit),
    _ShowcaseEntry('Cards', ShowcaseRoutes.cards, FitIcons.list),
    _ShowcaseEntry('Navigation', ShowcaseRoutes.navigation, FitIcons.home),
    _ShowcaseEntry('Feedback', ShowcaseRoutes.feedback, FitIcons.info),
    _ShowcaseEntry('Common', ShowcaseRoutes.common, FitIcons.more),
    _ShowcaseEntry('Home · domínio', ShowcaseRoutes.homeDomain, FitIcons.home),
    _ShowcaseEntry(
      'Planos · domínio',
      ShowcaseRoutes.plansDomain,
      FitIcons.plans,
    ),
    _ShowcaseEntry(
      'Treino · domínio',
      ShowcaseRoutes.workoutDomain,
      FitIcons.workout,
    ),
    _ShowcaseEntry(
      'Atividades · domínio',
      ShowcaseRoutes.activitiesDomain,
      FitIcons.activities,
    ),
    _ShowcaseEntry(
      'Corridas · domínio',
      ShowcaseRoutes.runningDomain,
      FitIcons.running,
    ),
    _ShowcaseEntry(
      'Passos · domínio',
      ShowcaseRoutes.stepsDomain,
      FitIcons.steps,
    ),
    _ShowcaseEntry(
      'Biblioteca · domínio',
      ShowcaseRoutes.libraryDomain,
      FitIcons.library,
    ),
    _ShowcaseEntry(
      'Nutrição · domínio',
      ShowcaseRoutes.nutritionDomain,
      FitIcons.nutrition,
    ),
    _ShowcaseEntry(
      'Perfil · domínio',
      ShowcaseRoutes.profileDomain,
      FitIcons.profile,
    ),
    _ShowcaseEntry(
      'Premium · domínio',
      ShowcaseRoutes.premiumDomain,
      FitIcons.premium,
    ),
    _ShowcaseEntry(
      'Configurações · domínio',
      ShowcaseRoutes.settingsDomain,
      FitIcons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FitTopBar(title: 'Component Library'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(FitSpacing.s16),
          itemCount: _entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: FitSpacing.s8),
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return FitListTile(
              title: entry.label,
              subtitle: 'Abrir exemplos do módulo',
              leading: Icon(entry.icon),
              trailing: const Icon(FitIcons.forward),
              onTap: () => Navigator.of(context).pushNamed(entry.route),
            );
          },
        ),
      ),
    );
  }
}

class _ShowcaseEntry {
  const _ShowcaseEntry(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}
