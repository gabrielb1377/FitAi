import 'package:flutter/material.dart';

import '../../../models/fitai_meta_model.dart';
import '../../../theme/app_theme.dart';

class MetasSummaryCard extends StatelessWidget {
  final FitaiMetasResumo resumo;

  const MetasSummaryCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Central de Metas',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resumo.concluidas}/${resumo.metas.length} metas concluidas',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: resumo.progressoMedio,
              minHeight: 8,
              backgroundColor: Colors.black.withAlpha(45),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(resumo.progressoMedio * 100).round()}% de progresso medio',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
