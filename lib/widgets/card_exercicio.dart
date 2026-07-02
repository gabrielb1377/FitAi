import 'package:flutter/material.dart';

import '../models/exercicio_model.dart';
import '../theme/app_theme.dart';

class CardExercicio extends StatelessWidget {
  final ExercicioModel exercicio;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CardExercicio({
    super.key,
    required this.exercicio,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AppGradientCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    exercicio.nome.isEmpty ? "?" : exercicio.nome[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${exercicio.categoria} • ${exercicio.dificuldade}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 42,
                height: 42,
                child: onDelete == null
                    ? const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                      )
                    : IconButton(
                        onPressed: onDelete,
                        tooltip: "Remover",
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.redAccent,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
