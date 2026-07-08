import 'package:flutter/material.dart';

import '../../../models/fitai_recorde_model.dart';
import '../../../theme/app_theme.dart';

class RecordeFilterBar extends StatelessWidget {
  final String filtroAtual;
  final ValueChanged<String> onChanged;

  const RecordeFilterBar({
    super.key,
    required this.filtroAtual,
    required this.onChanged,
  });

  static const todos = 'todos';

  @override
  Widget build(BuildContext context) {
    final filtros = const [
      todos,
      FitaiRecordeCategoria.treinos,
      FitaiRecordeCategoria.corridas,
      FitaiRecordeCategoria.sequencia,
      FitaiRecordeCategoria.volume,
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final selected = filtro == filtroAtual;
          final label = filtro == todos
              ? 'Todos'
              : FitaiRecordeCategoria.label(filtro);

          return ChoiceChip(
            selected: selected,
            label: Text(label),
            onSelected: (_) => onChanged(filtro),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceVariant,
            labelStyle: TextStyle(
              color: selected ? Colors.black : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withAlpha(35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}
