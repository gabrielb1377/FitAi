import 'package:flutter/material.dart';

import '../../../models/fitai_recorde_model.dart';
import '../../../theme/app_theme.dart';
import 'recorde_mini_badge.dart';

class RecordeCard extends StatelessWidget {
  final FitaiRecordeModel recorde;

  const RecordeCard({super.key, required this.recorde});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(recorde.categoria);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withAlpha(210),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(_categoryIcon(recorde.categoria), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recorde.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recorde.descricao,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RecordeMiniBadge(
                      icon: Icons.military_tech_rounded,
                      text: recorde.valorFormatado,
                      color: color,
                    ),
                    if (recorde.exercicioNome != null)
                      RecordeMiniBadge(
                        icon: Icons.fitness_center_rounded,
                        text: recorde.exercicioNome!,
                        color: AppColors.primary,
                      ),
                    if (recorde.treinoNome != null)
                      RecordeMiniBadge(
                        icon: Icons.assignment_turned_in_rounded,
                        text: recorde.treinoNome!,
                        color: AppColors.accent1,
                      ),
                    RecordeMiniBadge(
                      icon: Icons.calendar_today_rounded,
                      text: _formatarData(recorde.data),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String categoria) {
    switch (categoria) {
      case FitaiRecordeCategoria.corridas:
        return Icons.speed_rounded;
      case FitaiRecordeCategoria.sequencia:
        return Icons.local_fire_department_rounded;
      case FitaiRecordeCategoria.volume:
        return Icons.inventory_2_rounded;
      case FitaiRecordeCategoria.treinos:
      default:
        return Icons.emoji_events_rounded;
    }
  }

  Color _categoryColor(String categoria) {
    switch (categoria) {
      case FitaiRecordeCategoria.corridas:
        return AppColors.accent1;
      case FitaiRecordeCategoria.sequencia:
        return const Color(0xFFFFC857);
      case FitaiRecordeCategoria.volume:
        return AppColors.accent2;
      case FitaiRecordeCategoria.treinos:
      default:
        return AppColors.primary;
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}
