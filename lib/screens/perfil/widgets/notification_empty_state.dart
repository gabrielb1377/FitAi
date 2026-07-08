import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary.withAlpha(190),
            size: 44,
          ),
          const SizedBox(height: 12),
          Text('Nada por aqui', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Quando o FitIA encontrar algo importante, aparece nesta central.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
