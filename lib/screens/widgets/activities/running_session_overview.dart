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

    return FitCard(
      variant: FitCardVariant.outlined,
      elevation: 1,
      title: isActive ? 'Corrida em andamento' : 'Pronto para correr?',
      subtitle: isActive
          ? (isFinalizing
                ? 'Finalização protegida neste dispositivo.'
                : isPaused
                ? 'Sessao pausada.'
                : gpsConnected
                ? 'GPS conectado.'
                : 'Buscando GPS.')
          : 'Inicie uma corrida para acompanhar seus dados.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distancia', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: FitSpacing.s4),
          Text(
            '${distanceKm.toStringAsFixed(2)} km',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: FitSpacing.s16),
          Row(
            children: [
              Expanded(
                child: _SessionValue(
                  label: 'Tempo',
                  value: _formatTime(elapsedSeconds),
                ),
              ),
              Expanded(
                child: _SessionValue(label: 'Pace', value: _formatPace(pace)),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s20),
          action,
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

class _SessionValue extends StatelessWidget {
  final String label;
  final String value;

  const _SessionValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: FitSpacing.s4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
