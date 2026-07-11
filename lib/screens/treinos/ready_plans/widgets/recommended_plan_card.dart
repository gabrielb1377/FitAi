import 'package:flutter/material.dart';

import '../../../../models/ready_plan_model.dart';
import '../../../../theme/app_theme.dart';

class RecommendedPlanCard extends StatelessWidget {
  final ReadyPlanModel plan;
  final String reason;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const RecommendedPlanCard({
    super.key,
    required this.plan,
    required this.reason,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 268,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.primary.withAlpha(56)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Para você',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: isFavorite
                          ? 'Remover dos favoritos'
                          : 'Favoritar plano',
                      onPressed: onFavoriteToggle,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? const Color(0xFFE57373)
                            : AppColors.textHint,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  plan.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '${plan.daysPerWeek} dias · ${plan.estimatedMinutes} min',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
