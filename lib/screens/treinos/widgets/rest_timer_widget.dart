import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class RestTimerWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final int totalSeconds;
  final int remainingSeconds;
  final bool showNextButton;
  final VoidCallback onSkip;
  final VoidCallback? onNext;

  const RestTimerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.showNextButton,
    required this.onSkip,
    this.onNext,
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
                finished ? 'Hora de continuar.' : 'Recupere o folego.',
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
                _formatTime(remainingSeconds),
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
                  title.trim().isEmpty ? 'Proximo exercicio' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.trim().isEmpty ? 'Grupo muscular' : subtitle,
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
    if (finished && showNextButton && onNext != null) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.skip_next_rounded),
          label: const Text('Proximo exercicio'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onSkip,
        icon: const Icon(Icons.double_arrow_rounded),
        label: const Text('Pular descanso'),
      ),
    );
  }

  String _formatTime(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = safeSeconds ~/ 60;
    final rest = safeSeconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}";
  }
}
