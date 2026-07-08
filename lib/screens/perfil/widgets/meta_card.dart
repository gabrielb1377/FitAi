import 'package:flutter/material.dart';

import '../../../models/fitai_meta_model.dart';
import '../../../theme/app_theme.dart';
import 'meta_card_bits.dart';

class MetaCard extends StatelessWidget {
  final FitaiMetaModel meta;
  final Color color;

  const MetaCard({super.key, required this.meta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                MetaStatusPill(meta: meta, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              meta.descricao,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MetaValueTile(
                    label: 'Atual',
                    value: _valor(meta.valorAtual),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetaValueTile(
                    label: 'Objetivo',
                    value: _valor(meta.valorObjetivo),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetaValueTile(
                    label: 'Progresso',
                    value: meta.progressoPercentual,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: meta.progresso.clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: Colors.white.withAlpha(18),
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            MetaInfoLine(
              icon: Icons.schedule_rounded,
              text: meta.tempoRestante,
            ),
            const SizedBox(height: 6),
            MetaInfoLine(
              icon: Icons.trending_up_rounded,
              text: meta.estimativa,
            ),
            const SizedBox(height: 10),
            MetaCoachLine(text: meta.coachDica, color: color),
          ],
        ),
      ),
    );
  }

  String _valor(double valor) {
    if (meta.unidade.isEmpty && valor <= 0) return 'Futuro';
    final texto = valor == valor.roundToDouble()
        ? valor.round().toString()
        : valor.toStringAsFixed(1).replaceAll('.', ',');
    return meta.unidade.isEmpty ? texto : '$texto ${meta.unidade}';
  }
}
