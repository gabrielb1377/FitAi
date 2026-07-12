import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import 'plans_entrance.dart';

class PlanQuickActions extends StatelessWidget {
  final VoidCallback onCreateWithAi;
  final VoidCallback onCreateManually;
  final VoidCallback onAddReadyPlan;

  const PlanQuickActions({
    super.key,
    required this.onCreateWithAi,
    required this.onCreateManually,
    required this.onAddReadyPlan,
  });

  @override
  Widget build(BuildContext context) {
    return PlansEntrance(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - FitSpacing.s16) / 3;
          return Row(
            children: [
              _ActionTile(
                width: width,
                icon: Icons.auto_awesome_rounded,
                label: 'IA',
                tooltip: 'Criar com IA',
                onTap: onCreateWithAi,
              ),
              const SizedBox(width: FitSpacing.s8),
              _ActionTile(
                width: width,
                icon: Icons.edit_note_rounded,
                label: 'Manual',
                tooltip: 'Criar manualmente',
                onTap: onCreateManually,
              ),
              const SizedBox(width: FitSpacing.s8),
              _ActionTile(
                width: width,
                icon: Icons.library_books_rounded,
                label: 'Biblioteca',
                tooltip: 'Adicionar treino pronto',
                onTap: onAddReadyPlan,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: width,
        child: FitCard(
          variant: FitCardVariant.clickable,
          padding: const EdgeInsets.all(FitSpacing.s12),
          onTap: onTap,
          semanticLabel: tooltip,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: FitSpacing.s8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
