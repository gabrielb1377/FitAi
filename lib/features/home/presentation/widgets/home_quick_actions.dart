import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onCreatePlan,
    required this.onOpenLibrary,
    required this.onOpenRunning,
    required this.onOpenSteps,
  });

  final VoidCallback onCreatePlan;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenRunning;
  final VoidCallback onOpenSteps;

  @override
  Widget build(BuildContext context) {
    return FitSection(
      title: 'Acesso rapido',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 620 ? 2 : 4;
          final width =
              (constraints.maxWidth - (columns - 1) * FitSpacing.s12) / columns;
          return Wrap(
            spacing: FitSpacing.s12,
            runSpacing: FitSpacing.s12,
            children: [
              SizedBox(
                width: width,
                child: FitQuickActionCard(
                  label: 'Criar plano',
                  icon: Icons.playlist_add_rounded,
                  onTap: onCreatePlan,
                ),
              ),
              SizedBox(
                width: width,
                child: FitQuickActionCard(
                  label: 'Biblioteca',
                  icon: Icons.grid_view_rounded,
                  onTap: onOpenLibrary,
                ),
              ),
              SizedBox(
                width: width,
                child: FitQuickActionCard(
                  label: 'Corridas',
                  icon: Icons.directions_run_rounded,
                  color: FitColors.running,
                  onTap: onOpenRunning,
                ),
              ),
              SizedBox(
                width: width,
                child: FitQuickActionCard(
                  label: 'Passos',
                  icon: Icons.directions_walk_rounded,
                  color: FitColors.steps,
                  onTap: onOpenSteps,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
