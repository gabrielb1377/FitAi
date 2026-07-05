import 'package:flutter/material.dart';

import '../models/exercicio_model.dart';
import '../theme/app_theme.dart';

class CardExercicio extends StatelessWidget {
  final ExercicioModel exercicio;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final bool favorito;

  const CardExercicio({
    super.key,
    required this.exercicio,
    this.onTap,
    this.onDelete,
    this.onFavorite,
    this.favorito = false,
  });

  @override
  Widget build(BuildContext context) {
    final equipamento = exercicio.equipamentos.isEmpty
        ? "Peso corporal"
        : exercicio.equipamentos.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AppGradientCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(24),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(55),
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercicio.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          exercicio.categoria,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: onDelete != null
                        ? IconButton(
                            onPressed: onDelete,
                            tooltip: "Remover",
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.redAccent,
                          )
                        : IconButton(
                            onPressed: onFavorite,
                            tooltip: favorito
                                ? "Remover favorito"
                                : "Favoritar",
                            icon: Icon(
                              favorito
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                            ),
                            color: favorito
                                ? AppColors.accent2
                                : Colors.white54,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(equipamento),
                  _chip(exercicio.dificuldade),
                  if (exercicio.musculos.isNotEmpty)
                    _chip(exercicio.musculos.first),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
