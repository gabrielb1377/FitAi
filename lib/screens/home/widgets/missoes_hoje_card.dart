import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MissoesHojeCard extends StatelessWidget {
  final bool treinoConcluidoHoje;
  final int passos;
  final int treinosSemana;
  final int xpSemana;

  const MissoesHojeCard({
    super.key,
    required this.treinoConcluidoHoje,
    required this.passos,
    required this.treinosSemana,
    required this.xpSemana,
  });

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MISSÕES DE HOJE',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Complete para ganhar XP e manter o ritmo.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MissaoItem(
            icon: Icons.fitness_center_rounded,
            label: 'Concluir 1 treino hoje',
            detalhe: treinoConcluidoHoje ? 'Concluído' : 'Pendente',
            progresso: treinoConcluidoHoje ? 1.0 : 0.0,
            concluido: treinoConcluidoHoje,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _MissaoItem(
            icon: Icons.directions_walk_rounded,
            label: '8.000 passos hoje',
            detalhe: '$passos/8000',
            progresso: passos / 8000,
            concluido: passos >= 8000,
            color: AppColors.accent1,
          ),
          const SizedBox(height: 14),
          _MissaoItem(
            icon: Icons.bolt_rounded,
            label: '200 XP esta semana',
            detalhe: '$xpSemana/200 XP',
            progresso: xpSemana / 200,
            concluido: xpSemana >= 200,
            color: AppColors.accent2,
          ),
          const SizedBox(height: 14),
          _MissaoItem(
            icon: Icons.calendar_today_rounded,
            label: '3 treinos nesta semana',
            detalhe: '$treinosSemana/3 treinos',
            progresso: treinosSemana / 3,
            concluido: treinosSemana >= 3,
            color: AppColors.accent3,
          ),
        ],
      ),
    );
  }
}

class _MissaoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detalhe;
  final double progresso;
  final bool concluido;
  final Color color;

  const _MissaoItem({
    required this.icon,
    required this.label,
    required this.detalhe,
    required this.progresso,
    required this.concluido,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valor = progresso.clamp(0.0, 1.0).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: concluido ? color.withAlpha(35) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            concluido ? Icons.check_rounded : icon,
            color: concluido ? color : Colors.white70,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    detalhe,
                    style: TextStyle(
                      color: concluido ? color : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: valor,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
