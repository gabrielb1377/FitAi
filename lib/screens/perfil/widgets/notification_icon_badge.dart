import 'package:flutter/material.dart';

import '../../../models/fitai_notification_model.dart';
import '../../../theme/app_theme.dart';

class NotificationIconBadge extends StatelessWidget {
  final FitaiNotificationModel notificacao;
  final Color color;

  const NotificationIconBadge({
    super.key,
    required this.notificacao,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_icon, color: color),
        ),
        if (!notificacao.lida)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  IconData get _icon {
    switch (notificacao.categoria) {
      case FitaiNotificationCategoria.treinos:
        return Icons.fitness_center_rounded;
      case FitaiNotificationCategoria.corridas:
        return Icons.directions_run_rounded;
      case FitaiNotificationCategoria.metas:
        return Icons.flag_rounded;
      case FitaiNotificationCategoria.recordes:
        return Icons.emoji_events_rounded;
      case FitaiNotificationCategoria.coach:
        return Icons.psychology_rounded;
      case FitaiNotificationCategoria.agenda:
        return Icons.calendar_month_rounded;
      case FitaiNotificationCategoria.evolucao:
        return Icons.trending_up_rounded;
    }
  }
}
