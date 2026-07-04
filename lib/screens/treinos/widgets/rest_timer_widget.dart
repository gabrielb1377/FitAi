import 'dart:ui';

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
  final VoidCallback? onAdd15;
  final VoidCallback? onRemove15;

  const RestTimerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.showNextButton,
    required this.onSkip,
    this.onNext,
    this.onAdd15,
    this.onRemove15,
  });

  @override
  Widget build(BuildContext context) {
    final finished = remainingSeconds <= 0;
    final progress = totalSeconds <= 0
        ? 1.0
        : (remainingSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(86),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: finished
                      ? AppColors.gradientPrimary
                      : AppColors.gradientCard,
                ),
              ),
            ),
            Positioned(
              right: -38,
              top: -34,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(finished ? 34 : 14),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: finished
                      ? Colors.white.withAlpha(18)
                      : Colors.white.withAlpha(8),
                  border: Border.all(
                    color: finished
                        ? Colors.black.withAlpha(26)
                        : Colors.white.withAlpha(20),
                  ),
                ),
                child: Column(
                  children: [
                    _title(finished),
                    const SizedBox(height: 22),
                    _timer(progress, finished),
                    const SizedBox(height: 20),
                    _nextInfo(finished),
                    const SizedBox(height: 18),
                    _actions(finished),
                  ],
                ),
              ),
            ),
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
            finished ? Icons.check_rounded : Icons.timer_rounded,
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
                finished
                    ? 'Hora de continuar.'
                    : 'Respire e prepare a proxima serie.',
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
        width: 186,
        height: 186,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: finished
                    ? Colors.black.withAlpha(12)
                    : Colors.black.withAlpha(38),
                border: Border.all(
                  color: finished
                      ? Colors.black.withAlpha(22)
                      : Colors.white.withAlpha(18),
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 320),
              builder: (context, value, _) {
                return SizedBox(
                  width: 186,
                  height: 186,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 11,
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
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                _formatTime(remainingSeconds),
                key: ValueKey(remainingSeconds),
                style: TextStyle(
                  color: timerColor,
                  fontSize: 44,
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
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Proximo exercicio'),
            ),
          ),
          const SizedBox(height: 10),
          _timeControls(finished),
        ],
      );
    }

    return _timeControls(finished);
  }

  Widget _timeControls(bool finished) {
    final foreground = finished ? Colors.black : AppColors.textPrimary;
    final muted = finished ? Colors.black54 : AppColors.textSecondary;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _timeButton(
          label: '-15s',
          icon: Icons.remove_rounded,
          onPressed: onRemove15,
          foreground: foreground,
          muted: muted,
        ),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onSkip,
            icon: Icon(
              finished ? Icons.check_rounded : Icons.double_arrow_rounded,
            ),
            label: Text(finished ? 'Continuar' : 'Pular'),
          ),
        ),
        _timeButton(
          label: '+15s',
          icon: Icons.add_rounded,
          onPressed: onAdd15,
          foreground: foreground,
          muted: muted,
        ),
      ],
    );
  }

  Widget _timeButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color foreground,
    required Color muted,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: onPressed == null ? muted : foreground,
          side: BorderSide(
            color: onPressed == null
                ? muted.withAlpha(70)
                : foreground.withAlpha(90),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
