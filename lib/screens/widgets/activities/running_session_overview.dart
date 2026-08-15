import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class RunningSessionOverview extends StatelessWidget {
  final double distanceKm;
  final int elapsedSeconds;
  final double averageSpeed;
  final double currentSpeed;
  final double pace;
  final bool isActive;
  final bool isPaused;
  final bool isFinalizing;
  final bool gpsConnected;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final VoidCallback? onCancel;

  const RunningSessionOverview({
    super.key,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.averageSpeed,
    required this.currentSpeed,
    required this.pace,
    required this.isActive,
    required this.isPaused,
    required this.isFinalizing,
    required this.gpsConnected,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final runningColor = Theme.of(context).fitSemanticColors.running;
    final action = isFinalizing
        ? const FitButton(
            label: 'Salvando corrida',
            isLoading: true,
            enabled: false,
            expand: true,
          )
        : isActive
        ? Row(
            children: [
              Expanded(
                child: FitButton(
                  label: isPaused ? 'Retomar' : 'Pausar',
                  icon: isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onPressed: isPaused ? onResume : onPause,
                  variant: FitButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: FitSpacing.s12),
              Expanded(
                child: FitButton(
                  label: 'Finalizar',
                  icon: Icons.stop_rounded,
                  onPressed: onFinish,
                  variant: FitButtonVariant.danger,
                ),
              ),
            ],
          )
        : FitButton(
            label: 'Iniciar corrida',
            icon: Icons.play_arrow_rounded,
            onPressed: onStart,
            expand: true,
          );

    return FitEditorialHero(
      eyebrow: isActive ? 'Corrida ativa' : 'Corrida',
      title: isActive ? 'Em movimento' : 'Pronto para correr?',
      subtitle: isActive
          ? (isFinalizing
                ? 'Finalizacao protegida neste dispositivo.'
                : isPaused
                ? 'Sessao pausada.'
                : gpsConnected
                ? 'GPS conectado.'
                : 'Buscando sinal de GPS.')
          : 'Tempo, distancia e ritmo salvos mesmo sem internet.',
      accentColor: runningColor,
      trailing: Icon(Icons.directions_run_rounded, color: runningColor),
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISTANCIA', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: FitSpacing.s4),
          Text(
            '${distanceKm.toStringAsFixed(2)} km',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: FitSpacing.s16),
          FitMetricRail(
            items: [
              FitMetricRailItem(
                label: 'Tempo',
                value: _formatTime(elapsedSeconds),
                icon: Icons.timer_outlined,
                color: runningColor,
              ),
              FitMetricRailItem(
                label: 'Pace',
                value: _formatPace(pace),
                icon: Icons.route_outlined,
                color: runningColor,
              ),
            ],
          ),
          if (isActive && !isFinalizing && onCancel != null) ...[
            const SizedBox(height: FitSpacing.s8),
            Align(
              alignment: Alignment.center,
              child: FitButton(
                label: 'Cancelar corrida',
                icon: Icons.close_rounded,
                onPressed: onCancel,
                variant: FitButtonVariant.ghost,
                size: FitButtonSize.small,
                tooltip: 'Descartar sessao sem salvar no historico',
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  static String _formatPace(double pace) {
    if (pace <= 0) return '--';
    final seconds = (pace * 60).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min/km';
  }
}
