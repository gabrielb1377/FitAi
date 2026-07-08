import 'package:flutter/material.dart';

import '../../../models/fitai_notification_model.dart';
import '../../../theme/app_theme.dart';
import 'notification_icon_badge.dart';
import 'notification_mini_action.dart';

class NotificationCard extends StatelessWidget {
  final FitaiNotificationModel notificacao;
  final VoidCallback onTap;
  final VoidCallback onMarcarLida;
  final VoidCallback onExcluir;

  const NotificationCard({
    super.key,
    required this.notificacao,
    required this.onTap,
    required this.onMarcarLida,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoriaColor(notificacao.categoria);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AppGradientCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationIconBadge(notificacao: notificacao, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacao.categoriaLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificacao.titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notificacao.descricao,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          _formatarData(notificacao.data),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!notificacao.lida)
                          NotificationMiniAction(
                            label: 'Lida',
                            icon: Icons.done_rounded,
                            onTap: onMarcarLida,
                          ),
                        NotificationMiniAction(
                          label: 'Excluir',
                          icon: Icons.delete_outline_rounded,
                          onTap: onExcluir,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoriaColor(FitaiNotificationCategoria categoria) {
    switch (categoria) {
      case FitaiNotificationCategoria.treinos:
      case FitaiNotificationCategoria.evolucao:
        return AppColors.primary;
      case FitaiNotificationCategoria.corridas:
      case FitaiNotificationCategoria.agenda:
        return Colors.cyanAccent;
      case FitaiNotificationCategoria.metas:
      case FitaiNotificationCategoria.recordes:
        return Colors.amberAccent;
      case FitaiNotificationCategoria.coach:
        return Colors.greenAccent;
    }
  }

  String _formatarData(DateTime data) {
    final local = data.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$minuto';
  }
}
