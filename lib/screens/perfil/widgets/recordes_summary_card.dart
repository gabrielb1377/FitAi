import 'package:flutter/material.dart';

import '../../../models/fitai_recorde_model.dart';
import '../../../theme/app_theme.dart';

class RecordesSummaryCard extends StatelessWidget {
  final List<FitaiRecordeModel> recordes;

  const RecordesSummaryCard({super.key, required this.recordes});

  @override
  Widget build(BuildContext context) {
    final treinos = _contar(FitaiRecordeCategoria.treinos);
    final corridas = _contar(FitaiRecordeCategoria.corridas);
    final volume = _contar(FitaiRecordeCategoria.volume);
    final sequencia = _contar(FitaiRecordeCategoria.sequencia);

    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECORDES',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Suas melhores marcas',
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(label: 'Treinos', value: '$treinos'),
              _SummaryPill(label: 'Corridas', value: '$corridas'),
              _SummaryPill(label: 'Volume', value: '$volume'),
              _SummaryPill(label: 'Sequencia', value: '$sequencia'),
            ],
          ),
        ],
      ),
    );
  }

  int _contar(String categoria) {
    return recordes.where((recorde) => recorde.categoria == categoria).length;
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
