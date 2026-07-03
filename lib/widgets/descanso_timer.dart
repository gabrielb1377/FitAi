import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DescansoTimer extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final VoidCallback onSkip;
  final VoidCallback onAdd15;
  final VoidCallback onRemove15;
  final String? proximoExercicio;
  final String? proximoGrupo;

  const DescansoTimer({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.onSkip,
    required this.onAdd15,
    required this.onRemove15,
    this.proximoExercicio,
    this.proximoGrupo,
  });

  @override
  Widget build(BuildContext context) {
    final finished = remainingSeconds <= 0;
    final progress = totalSeconds <= 0
        ? 1.0
        : (remainingSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(58),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: AppGradientCard(
        gradient: finished ? AppColors.gradientPrimary : AppColors.gradientCard,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _title(finished),
            const SizedBox(height: 20),
            _timer(progress, finished),
            const SizedBox(height: 18),
            _nextInfo(finished),
            const SizedBox(height: 18),
            _actions(finished),
          ],
        ),
      ),
    );
  }

  Widget _title(bool finished) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: finished
                ? Colors.black.withAlpha(24)
                : AppColors.primary.withAlpha(28),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(
            finished ? Icons.check_rounded : Icons.hourglass_bottom_rounded,
            color: finished ? Colors.black : AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                finished ? 'Descanso finalizado' : 'Descanso',
                style: TextStyle(
                  color: finished ? Colors.black : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                finished ? 'Hora da proxima serie.' : 'Recupere o folego.',
                style: TextStyle(
                  color: finished ? Colors.black87 : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timer(double progress, bool finished) {
    final timerColor = finished ? Colors.black : AppColors.textPrimary;
    final progressColor = finished ? Colors.black : AppColors.primary;

    return Center(
      child: SizedBox(
        width: 174,
        height: 174,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 320),
              builder: (context, value, _) {
                return SizedBox(
                  width: 174,
                  height: 174,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 10,
                    color: progressColor,
                    backgroundColor: finished
                        ? Colors.black26
                        : AppColors.surfaceVariant,
                    strokeCap: StrokeCap.round,
                  ),
                );
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                _formatar(remainingSeconds),
                key: ValueKey(remainingSeconds),
                style: TextStyle(
                  color: timerColor,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextInfo(bool finished) {
    final title = proximoExercicio?.trim();
    final subtitle = proximoGrupo?.trim();
    final textColor = finished ? Colors.black : AppColors.textPrimary;
    final mutedColor = finished ? Colors.black87 : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: finished ? Colors.black.withAlpha(18) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: finished ? Colors.black26 : Colors.white.withAlpha(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.skip_next_rounded, color: mutedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title == null || title.isEmpty ? 'Proxima serie' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle == null || subtitle.isEmpty
                      ? 'Mesmo exercicio'
                      : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(bool finished) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton(onPressed: onRemove15, child: const Text('-15s')),
        ElevatedButton.icon(
          onPressed: onSkip,
          icon: Icon(
            finished ? Icons.check_rounded : Icons.double_arrow_rounded,
          ),
          label: Text(finished ? 'Continuar' : 'Pular'),
        ),
        OutlinedButton(onPressed: onAdd15, child: const Text('+15s')),
      ],
    );
  }

  String _formatar(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final rest = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${rest.toString().padLeft(2, '0')}';
  }
}
