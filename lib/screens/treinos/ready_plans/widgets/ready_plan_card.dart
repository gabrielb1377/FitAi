import 'package:flutter/material.dart';

import '../../../../models/ready_plan_model.dart';
import '../../../../theme/app_theme.dart';

class ReadyPlanCard extends StatelessWidget {
  final ReadyPlanModel plan;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ReadyPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanIcon(category: plan.category, goal: plan.goal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        plan.goal,
                        plan.level,
                      ].where((item) => item.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Detail(
                          label: plan.split.isEmpty ? 'Plano' : plan.split,
                          icon: Icons.account_tree_outlined,
                        ),
                        _Detail(
                          label: '${plan.daysPerWeek} dias',
                          icon: Icons.calendar_today_outlined,
                        ),
                        _Detail(
                          label: '${plan.estimatedMinutes} min',
                          icon: Icons.schedule_outlined,
                        ),
                      ],
                    ),
                    if (plan.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: plan.tags
                            .take(3)
                            .map((tag) => _Tag(label: tag))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
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
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  final String category;
  final String goal;

  const _PlanIcon({required this.category, required this.goal});

  @override
  Widget build(BuildContext context) {
    final text = '$category $goal'.toLowerCase();
    final icon = text.contains('casa') || text.contains('calistenia')
        ? Icons.home_outlined
        : text.contains('força') || text.contains('power')
        ? Icons.fitness_center_rounded
        : text.contains('emagrecimento')
        ? Icons.bolt_rounded
        : Icons.auto_graph_rounded;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Detail({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
