import 'package:flutter/material.dart';

import '../../../models/fitai_recorde_model.dart';
import '../../../theme/app_theme.dart';
import 'recorde_card.dart';

class RecordeCategorySection extends StatelessWidget {
  final String categoria;
  final List<FitaiRecordeModel> recordes;

  const RecordeCategorySection({
    super.key,
    required this.categoria,
    required this.recordes,
  });

  @override
  Widget build(BuildContext context) {
    if (recordes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              FitaiRecordeCategoria.label(categoria),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < recordes.length; index++) ...[
          RecordeCard(recorde: recordes[index]),
          if (index != recordes.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  IconData get _icon {
    switch (categoria) {
      case FitaiRecordeCategoria.corridas:
        return Icons.directions_run_rounded;
      case FitaiRecordeCategoria.sequencia:
        return Icons.local_fire_department_rounded;
      case FitaiRecordeCategoria.volume:
        return Icons.inventory_2_rounded;
      case FitaiRecordeCategoria.treinos:
      default:
        return Icons.fitness_center_rounded;
    }
  }
}
