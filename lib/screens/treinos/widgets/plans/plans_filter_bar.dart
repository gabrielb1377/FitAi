import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

enum PlanListFilter { all, active, saved, completed }

class PlansFilterBar extends StatelessWidget {
  final int totalPlans;
  final PlanListFilter selectedFilter;
  final ValueChanged<PlanListFilter> onFilterChanged;

  const PlansFilterBar({
    super.key,
    required this.totalPlans,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meus planos ($totalPlans)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: FitSpacing.s12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PlanListFilter.values.map(_buildFilter).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilter(PlanListFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(right: FitSpacing.s8),
      child: FitFilterChip(
        label: filter.label,
        selected: selectedFilter == filter,
        onSelected: (_) => onFilterChanged(filter),
      ),
    );
  }
}

extension on PlanListFilter {
  String get label => switch (this) {
    PlanListFilter.all => 'Todos',
    PlanListFilter.active => 'Ativo',
    PlanListFilter.saved => 'Salvos',
    PlanListFilter.completed => 'Concluidos',
  };
}
