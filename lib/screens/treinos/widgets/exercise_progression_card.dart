import 'package:flutter/material.dart';

import '../../../services/progressao_service.dart';
import '../../../theme/app_theme.dart';

class ExerciseProgressionCard extends StatelessWidget {
  final Future<ProgressaoInteligenteResumo> future;

  const ExerciseProgressionCard({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProgressaoInteligenteResumo>(
      future: future,
      builder: (context, snapshot) {
        final progressao = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(progressao: progressao),
              const SizedBox(height: 14),
              if (progressao == null)
                const LinearProgressIndicator(minHeight: 6)
              else ...[
                _Metrics(progressao: progressao),
                const SizedBox(height: 12),
                Text(
                  progressao.recomendacao,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: progressao.ultimasCinco
                      .map((item) => Chip(label: Text(item.cargaFormatada)))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ProgressaoInteligenteResumo? progressao;

  const _Header({required this.progressao});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.trending_up_rounded, color: AppColors.primary),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Progressao',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          progressao == null
              ? '...'
              : '${progressao!.indicadorSimbolo} ${progressao!.indicadorTexto}',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  final ProgressaoInteligenteResumo progressao;

  const _Metrics({required this.progressao});

  @override
  Widget build(BuildContext context) {
    final dados = {
      'Ultima': progressao.ultimaExecucaoTexto,
      'Melhor': progressao.melhorExecucaoTexto,
      'Carga media': progressao.cargaMediaTexto,
      'Volume medio': progressao.volumeMedioTexto,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dados.entries.map((entry) {
        return SizedBox(
          width: 174,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${entry.key}\n${entry.value}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
