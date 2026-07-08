import 'package:flutter/material.dart';

import '../../../models/fitai_meta_model.dart';
import '../../../theme/app_theme.dart';
import 'meta_card.dart';

class MetaCategorySection extends StatelessWidget {
  final FitaiMetaCategoria categoria;
  final List<FitaiMetaModel> metas;

  const MetaCategorySection({
    super.key,
    required this.categoria,
    required this.metas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_icon, color: _color, size: 20),
            const SizedBox(width: 8),
            Text(
              _label,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...metas.map((meta) => MetaCard(meta: meta, color: _color)),
      ],
    );
  }

  String get _label {
    switch (categoria) {
      case FitaiMetaCategoria.treinos:
        return 'Treinos';
      case FitaiMetaCategoria.corridas:
        return 'Corridas';
      case FitaiMetaCategoria.passos:
        return 'Passos';
      case FitaiMetaCategoria.forca:
        return 'Forca';
      case FitaiMetaCategoria.corpo:
        return 'Corpo';
    }
  }

  IconData get _icon {
    switch (categoria) {
      case FitaiMetaCategoria.treinos:
        return Icons.fitness_center_rounded;
      case FitaiMetaCategoria.corridas:
        return Icons.directions_run_rounded;
      case FitaiMetaCategoria.passos:
        return Icons.directions_walk_rounded;
      case FitaiMetaCategoria.forca:
        return Icons.monitor_weight_rounded;
      case FitaiMetaCategoria.corpo:
        return Icons.accessibility_new_rounded;
    }
  }

  Color get _color {
    switch (categoria) {
      case FitaiMetaCategoria.treinos:
      case FitaiMetaCategoria.forca:
        return AppColors.primary;
      case FitaiMetaCategoria.corridas:
        return Colors.cyanAccent;
      case FitaiMetaCategoria.passos:
        return Colors.greenAccent;
      case FitaiMetaCategoria.corpo:
        return Colors.amberAccent;
    }
  }
}
