import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import '../../../theme/app_theme.dart';

class PlanCard extends StatelessWidget {
  final TreinoModel treino;
  final String ultimaExecucao;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PlanCard({
    super.key,
    required this.treino,
    required this.ultimaExecucao,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(28),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          treino.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          treino.objetivo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppChip(
                    label: treino.criadoPorIA ? "IA" : "Manual",
                    icon: treino.criadoPorIA
                        ? Icons.auto_awesome_rounded
                        : Icons.edit_note_rounded,
                    color: treino.criadoPorIA
                        ? AppColors.primary
                        : AppColors.accent1,
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: IconButton(
                        onPressed: onDelete,
                        tooltip: "Apagar plano",
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.list_alt_rounded,
                    label: "${treino.exercicios.length} exercicios",
                  ),
                  _InfoPill(
                    icon: Icons.timer_rounded,
                    label: "${treino.tempoEstimado} min",
                  ),
                  _InfoPill(icon: Icons.history_rounded, label: ultimaExecucao),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
