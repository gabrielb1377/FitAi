import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import 'workout_session_models.dart';

class WorkoutSessionHeader extends StatelessWidget {
  const WorkoutSessionHeader({
    super.key,
    required this.title,
    required this.elapsedLabel,
    required this.onClose,
    required this.onMenu,
  });

  final String title;
  final String elapsedLabel;
  final VoidCallback onClose;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FitIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Encerrar treino',
              variant: FitIconButtonVariant.subtle,
              onPressed: onClose,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: FitSpacing.s4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: FitColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: FitSpacing.s8),
                    Text(
                      elapsedLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FitIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: 'Mais opções do treino',
              variant: FitIconButtonVariant.subtle,
              onPressed: onMenu,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutProgressHeader extends StatelessWidget {
  const WorkoutProgressHeader({
    super.key,
    required this.progress,
    required this.exerciseIndex,
    required this.exerciseCount,
  });

  final double progress;
  final int exerciseIndex;
  final int exerciseCount;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress.clamp(0.0, 1.0) * 100).round();
    return Semantics(
      label:
          'Progresso do treino, exercício $exerciseIndex de $exerciseCount, $percentage por cento',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PROGRESSO DO TREINO',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Text('$exerciseIndex de $exerciseCount'),
              const SizedBox(width: FitSpacing.s16),
              Text(
                '$percentage%',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: FitColors.primary),
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s12),
          FitProgress(value: progress, height: 8, animate: true),
        ],
      ),
    );
  }
}

class WorkoutQuickActionsPanel extends StatelessWidget {
  const WorkoutQuickActionsPanel({super.key, required this.actions});

  final List<WorkoutQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s12,
        FitSpacing.s12,
        FitSpacing.s12,
        FitSpacing.s16,
      ),
      decoration: BoxDecoration(
        color: FitColors.surface,
        borderRadius: FitRadius.xLargeBorder,
        border: Border.all(color: FitColors.outlineSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: const BoxDecoration(
              color: FitColors.textHint,
              borderRadius: FitRadius.pillBorder,
            ),
          ),
          const SizedBox(height: FitSpacing.s12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 88,
              crossAxisSpacing: FitSpacing.s4,
              mainAxisSpacing: FitSpacing.s4,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) =>
                _QuickActionTile(action: actions[index]),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final WorkoutQuickAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? FitColors.primary;
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: FitRadius.mediumBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FitSpacing.s4,
              vertical: FitSpacing.s8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: FitColors.outlineSoft),
              borderRadius: FitRadius.mediumBorder,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: color, size: 25),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: FitColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutSessionBottomNavigation extends StatelessWidget {
  const WorkoutSessionBottomNavigation({
    super.key,
    required this.restSeconds,
    required this.isResting,
    required this.onRestTap,
    this.onPrevious,
    this.onNext,
  });

  final int restSeconds;
  final bool isResting;
  final VoidCallback onRestTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FitColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FitRadius.xLarge),
        ),
        border: Border(top: BorderSide(color: FitColors.outlineSoft)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          FitSpacing.s16,
          FitSpacing.s12,
          FitSpacing.s16,
          FitSpacing.s12,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              children: [
                Expanded(
                  child: FitButton(
                    label: 'Anterior',
                    leadingIcon: Icons.chevron_left_rounded,
                    variant: FitButtonVariant.outlined,
                    onPressed: onPrevious,
                    expand: true,
                  ),
                ),
                const SizedBox(width: FitSpacing.s12),
                _RestNavigationButton(
                  seconds: restSeconds,
                  isResting: isResting,
                  onTap: onRestTap,
                ),
                const SizedBox(width: FitSpacing.s12),
                Expanded(
                  flex: 2,
                  child: FitButton(
                    label: 'Próximo exercício',
                    trailingIcon: Icons.chevron_right_rounded,
                    onPressed: onNext,
                    expand: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestNavigationButton extends StatelessWidget {
  const _RestNavigationButton({
    required this.seconds,
    required this.isResting,
    required this.onTap,
  });

  final int seconds;
  final bool isResting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return Tooltip(
      message: isResting ? 'Pular descanso $minutes:$remainder' : 'Descanso',
      child: Semantics(
        button: true,
        label: isResting
            ? 'Descanso $minutes minutos e $remainder segundos'
            : 'Iniciar descanso',
        child: InkWell(
          onTap: onTap,
          borderRadius: FitRadius.pillBorder,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isResting ? FitColors.warning : FitColors.outline,
              ),
              color: FitColors.surfaceVariant,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isResting ? FitColors.warning : FitColors.textPrimary,
                ),
                Text(
                  isResting ? '$minutes:$remainder' : 'REST',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isResting
                        ? FitColors.warning
                        : FitColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
