import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class HomeStatsRow extends StatelessWidget {
  final double distancia;
  final int passos;

  const HomeStatsRow({
    super.key,
    required this.distancia,
    required this.passos,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppStatChip(
            label: 'Distância',
            value: '${distancia.toStringAsFixed(2)} km',
            icon: Icons.route_outlined,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatChip(
            label: 'Passos',
            value: '$passos',
            icon: Icons.directions_walk_outlined,
            iconColor: AppColors.accent1,
          ),
        ),
      ],
    );
  }
}
