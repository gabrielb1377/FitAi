import 'package:flutter/material.dart';

import '../../../../models/ready_plan_model.dart';
import '../../official/official_plan_ui.dart';

class ReadyPlanCard extends StatelessWidget {
  const ReadyPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final ReadyPlanModel plan;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final rating = _rating(plan);
    return OfficialPlanSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            OfficialReadyPlanMedia(plan: plan, width: 70, height: 66),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: OfficialPlanColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${plan.daysPerWeek} treinos · ${plan.level}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: OfficialPlanColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: isFavorite ? 'Remover dos favoritos' : 'Favoritar plano',
              child: InkWell(
                onTap: onFavoriteToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 17,
                        color: OfficialPlanColors.warning,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: OfficialPlanColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _rating(ReadyPlanModel plan) {
    final seed = plan.popularityCount + plan.name.length;
    return 4.7 + (seed % 3) * 0.1;
  }
}
