import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SerieCard extends StatelessWidget {
  final int numero;
  final String peso;
  final String repeticoes;
  final bool concluida;
  final VoidCallback onToggle;

  const SerieCard({
    super.key,
    required this.numero,
    required this.peso,
    required this.repeticoes,
    required this.concluida,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: concluida
            ? AppColors.primary.withAlpha(26)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: concluida ? AppColors.primary : Colors.white.withAlpha(18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: concluida
                  ? AppColors.primary.withAlpha(34)
                  : Colors.black.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$numero',
                style: TextStyle(
                  color: concluida ? AppColors.primary : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SerieMetric(label: 'Peso', value: peso),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SerieMetric(label: 'Reps', value: repeticoes),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: concluida
                    ? AppColors.primary.withAlpha(36)
                    : Colors.black.withAlpha(22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: concluida ? AppColors.primary : Colors.white24,
                ),
              ),
              child: Icon(
                concluida ? Icons.check_rounded : Icons.circle_outlined,
                color: concluida ? AppColors.primary : Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SerieMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SerieMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
