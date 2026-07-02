import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import '../../../theme/app_theme.dart';

class PlanSummaryCard extends StatelessWidget {
  final TreinoModel treino;
  final String ultimaExecucao;

  const PlanSummaryCard({
    super.key,
    required this.treino,
    required this.ultimaExecucao,
  });

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(24),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppChip(
                      label: treino.criadoPorIA ? "Plano IA" : "Plano manual",
                      icon: treino.criadoPorIA
                          ? Icons.auto_awesome_rounded
                          : Icons.edit_note_rounded,
                      dark: true,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      treino.nome,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      treino.objetivo,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.timer_rounded,
                label: "${treino.tempoEstimado} min",
              ),
              _MetricChip(
                icon: Icons.list_alt_rounded,
                label: "${treino.exercicios.length} exercicios",
              ),
              _MetricChip(icon: Icons.history_rounded, label: ultimaExecucao),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black87, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
