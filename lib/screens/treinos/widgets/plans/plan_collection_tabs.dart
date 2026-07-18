import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

enum PlanCollectionTab { active, completed, drafts }

class PlanCollectionTabs extends StatelessWidget {
  const PlanCollectionTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PlanCollectionTab selected;
  final ValueChanged<PlanCollectionTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Categorias de planos',
      child: Row(
        children: PlanCollectionTab.values
            .map((tab) {
              final isSelected = selected == tab;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: FitRadius.smallBorder,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          tab.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: isSelected
                                    ? FitColors.primary
                                    : FitColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: FitSpacing.s12),
                        AnimatedContainer(
                          duration: FitDuration.fast,
                          height: 2,
                          color: isSelected
                              ? FitColors.primary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

extension on PlanCollectionTab {
  String get label => switch (this) {
    PlanCollectionTab.active => 'Ativos',
    PlanCollectionTab.completed => 'Concluidos',
    PlanCollectionTab.drafts => 'Rascunhos',
  };
}
