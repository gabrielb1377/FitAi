import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_recorde_model.dart';

class ProfileRecords extends StatelessWidget {
  final List<FitaiRecordeModel> records;
  final VoidCallback onViewAll;

  const ProfileRecords({
    super.key,
    required this.records,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return FitSection(
        title: 'Recordes',
        padding: EdgeInsets.zero,
        child: FitEmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'Seus recordes aparecerao aqui.',
          description:
              'Conclua treinos e corridas para registrar suas melhores marcas.',
          actionLabel: 'Ver todos',
          onAction: onViewAll,
        ),
      );
    }
    final highlights = [
      _recordFor(
        'Maior carga',
        (record) => record.unidade.toLowerCase().contains('kg'),
      ),
      _recordFor(
        'Maior sequencia',
        (record) => record.categoria == FitaiRecordeCategoria.sequencia,
      ),
      _recordFor(
        'Maior distancia',
        (record) =>
            record.categoria == FitaiRecordeCategoria.corridas &&
            record.unidade.toLowerCase().contains('km'),
      ),
      _recordFor(
        'Melhor pace',
        (record) =>
            record.titulo.toLowerCase().contains('pace') ||
            record.unidade.toLowerCase().contains('min/km'),
        lowerIsBetter: true,
      ),
    ];
    return FitSection(
      title: 'Recordes',
      onViewAll: onViewAll,
      padding: EdgeInsets.zero,
      child: FitCard(
        variant: FitCardVariant.outlined,
        padding: const EdgeInsets.all(FitSpacing.s16),
        child: Column(
          children: [
            for (var index = 0; index < highlights.length; index++) ...[
              _RecordRow(
                label: highlights[index].label,
                record: highlights[index].record,
              ),
              if (index < highlights.length - 1)
                const FitDivider(verticalSpacing: FitSpacing.s12),
            ],
          ],
        ),
      ),
    );
  }

  _RecordHighlight _recordFor(
    String label,
    bool Function(FitaiRecordeModel) matches, {
    bool lowerIsBetter = false,
  }) {
    final candidates = records.where(matches).toList();
    candidates.sort(
      (a, b) => lowerIsBetter
          ? a.valor.compareTo(b.valor)
          : b.valor.compareTo(a.valor),
    );
    return _RecordHighlight(
      label,
      candidates.isEmpty ? null : candidates.first,
    );
  }
}

class _RecordHighlight {
  final String label;
  final FitaiRecordeModel? record;

  const _RecordHighlight(this.label, this.record);
}

class _RecordRow extends StatelessWidget {
  final String label;
  final FitaiRecordeModel? record;

  const _RecordRow({required this.label, required this.record});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.emoji_events_outlined),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Flexible(
          child: Text(
            record?.valorFormatado ?? '--',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}
