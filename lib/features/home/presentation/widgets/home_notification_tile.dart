import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_notification_model.dart';

class HomeNotificationTile extends StatelessWidget {
  const HomeNotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final FitaiNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _color;
    return Semantics(
      button: true,
      label:
          '${notification.lida ? '' : 'Nao lida. '}${notification.titulo}. ${notification.descricao}',
      child: Material(
        color: accent.withValues(
          alpha: notification.lida ? FitOpacity.transparent : FitOpacity.subtle,
        ),
        borderRadius: FitRadius.mediumBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.mediumBorder,
          child: Padding(
            padding: const EdgeInsets.all(FitSpacing.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon, color: accent),
                const SizedBox(width: FitSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.titulo,
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: FitSpacing.s4),
                      Text(
                        notification.descricao,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FitSpacing.s8),
                Column(
                  children: [
                    Text(_relativeTime(), style: context.textTheme.labelSmall),
                    if (!notification.lida) ...[
                      const SizedBox(height: FitSpacing.s8),
                      Container(
                        width: FitSpacing.s8,
                        height: FitSpacing.s8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (notification.categoria) {
    FitaiNotificationCategoria.treinos ||
    FitaiNotificationCategoria.agenda => Icons.fitness_center_rounded,
    FitaiNotificationCategoria.corridas => Icons.directions_run_rounded,
    FitaiNotificationCategoria.metas => Icons.directions_walk_rounded,
    FitaiNotificationCategoria.recordes => Icons.emoji_events_rounded,
    FitaiNotificationCategoria.coach ||
    FitaiNotificationCategoria.evolucao => Icons.auto_awesome_rounded,
  };

  Color get _color => switch (notification.categoria) {
    FitaiNotificationCategoria.coach ||
    FitaiNotificationCategoria.evolucao => FitColors.ai,
    FitaiNotificationCategoria.corridas => FitColors.running,
    FitaiNotificationCategoria.recordes => FitColors.achievement,
    _ => FitColors.primary,
  };

  String _relativeTime() {
    final difference = DateTime.now().difference(notification.data);
    if (difference.inMinutes < 1) return 'Agora';
    if (difference.inHours < 1) return '${difference.inMinutes} min';
    if (difference.inDays < 1) return '${difference.inHours} h';
    return '${difference.inDays} d';
  }
}
