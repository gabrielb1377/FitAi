import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class XpRankCard extends StatelessWidget {
  final int xp;
  final int nivel;

  const XpRankCard({super.key, required this.xp, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final rankColor = _corRank();
    final rankIcon = _iconRank();
    final rankNome = _rankAtual();
    final proximoRankNome = _proximoRank();
    const xpParaProximoNivel = 100;
    final xpAtualNoNivel = xp % xpParaProximoNivel;
    final progresso = (xpAtualNoNivel / xpParaProximoNivel).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: rankColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(rankIcon, color: rankColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NÍVEL $nivel · $rankNome',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: rankColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rankNome,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: rankColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(70),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$xp XP',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP no nível',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    '$xpAtualNoNivel / $xpParaProximoNivel',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF2A2A2A)),
                  child: FractionallySizedBox(
                    widthFactor: progresso,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [rankColor.withAlpha(200), AppColors.primary],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (rankNome != 'Diamante') ...[
                const SizedBox(height: 10),
                Text(
                  'Próximo rank: $proximoRankNome',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _rankAtual() {
    if (nivel >= 50) return 'Diamante';
    if (nivel >= 30) return 'Platina';
    if (nivel >= 20) return 'Ouro';
    if (nivel >= 10) return 'Prata';
    return 'Bronze';
  }

  String _proximoRank() {
    if (nivel >= 50) return 'Máximo';
    if (nivel >= 30) return 'Diamante (Nv. 50)';
    if (nivel >= 20) return 'Platina (Nv. 30)';
    if (nivel >= 10) return 'Ouro (Nv. 20)';
    return 'Prata (Nv. 10)';
  }

  Color _corRank() {
    if (nivel >= 50) return AppColors.rankDiamante;
    if (nivel >= 30) return AppColors.rankPlatina;
    if (nivel >= 20) return AppColors.rankOuro;
    if (nivel >= 10) return AppColors.rankPrata;
    return AppColors.rankBronze;
  }

  IconData _iconRank() {
    if (nivel >= 50) return Icons.diamond_rounded;
    if (nivel >= 30) return Icons.emoji_events_rounded;
    if (nivel >= 20) return Icons.military_tech_rounded;
    if (nivel >= 10) return Icons.shield_rounded;
    return Icons.workspace_premium_rounded;
  }
}
