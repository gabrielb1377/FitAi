import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MetasCoachCard extends StatelessWidget {
  final List<String> dicas;

  const MetasCoachCard({super.key, required this.dicas});

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Coach FitIA',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final dica in dicas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      dica,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
