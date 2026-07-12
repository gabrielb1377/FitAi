import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          FitHeader(
            title: 'Meus Planos',
            subtitle: 'Organize sua rotina e acompanhe sua evolucao.',
            padding: EdgeInsets.zero,
            actions: [
              IconButton(
                tooltip: 'Historico de treinos',
                onPressed: onOpenHistory,
                icon: const Icon(Icons.history_rounded),
              ),
              IconButton(
                tooltip: 'Criar plano',
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          FitSearchField(
            controller: searchController,
            hintText: 'Buscar por nome, objetivo ou divisao',
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}
