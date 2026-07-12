import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import 'plans_entrance.dart';

class PlansHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;
  final VoidCallback onOpenHistory;

  const PlansHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAdd,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    return PlansEntrance(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            FitHeader(
              title: 'Meus Planos',
              subtitle: 'Sua rotina, em um so lugar.',
              padding: EdgeInsets.zero,
              actions: [
                IconButton(
                  tooltip: 'Historico de treinos',
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history_rounded),
                ),
                IconButton.filled(
                  tooltip: 'Criar plano',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: FitSpacing.s20),
            FitSearchField(
              controller: searchController,
              hintText: 'Buscar planos, objetivos ou divisao',
              onChanged: onSearchChanged,
            ),
          ],
        ),
      ),
    );
  }
}
