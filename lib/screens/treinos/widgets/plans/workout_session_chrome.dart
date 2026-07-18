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
    final primaryActions = actions.take(4).toList(growable: false);
    final moreAction = actions.length > 4 ? actions[4] : null;

    if (primaryActions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(FitSpacing.s8),
      decoration: BoxDecoration(
        color: FitColors.surfaceVariant,
        borderRadius: FitRadius.largeBorder,
        border: Border.all(color: FitColors.outlineSoft),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            if (constraints.maxWidth < 390)
              _NarrowQuickActionsGrid(actions: primaryActions)
            else
              _QuickActionsRow(actions: primaryActions),
            if (moreAction != null) ...[
              const SizedBox(height: FitSpacing.s4),
              const Divider(height: 1, color: FitColors.outlineSoft),
              Align(
                alignment: Alignment.centerRight,
                child: FitButton(
                  label: moreAction.label,
                  leadingIcon: moreAction.icon,
                  onPressed: moreAction.onTap,
                  variant: FitButtonVariant.ghost,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<WorkoutQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(width: FitSpacing.s4),
          Expanded(child: _QuickActionTile(action: actions[index])),
        ],
      ],
    );
  }
}

class _NarrowQuickActionsGrid extends StatelessWidget {
  const _NarrowQuickActionsGrid({required this.actions});

  final List<WorkoutQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 58,
        crossAxisSpacing: FitSpacing.s4,
        mainAxisSpacing: FitSpacing.s4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) =>
          _QuickActionTile(action: actions[index], compact: true),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, this.compact = false});

  final WorkoutQuickAction action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? FitColors.textSecondary;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: FitColors.textPrimary);

    return Tooltip(
      message: action.label,
      child: Semantics(
        button: true,
        label: action.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onTap,
            borderRadius: FitRadius.mediumBorder,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitSpacing.s4,
                  vertical: FitSpacing.s4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: FitColors.outlineSoft),
                  borderRadius: FitRadius.mediumBorder,
                ),
                child: compact
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action.icon, color: color, size: 20),
                          const SizedBox(width: FitSpacing.s8),
                          Flexible(
                            child: Text(
                              action.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action.icon, color: color, size: 20),
                          const SizedBox(height: FitSpacing.s4),
                          Text(
                            action.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: labelStyle,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutMoreOptionsSheet {
  const WorkoutMoreOptionsSheet._();

  static Future<void> show({
    required BuildContext context,
    required List<WorkoutQuickAction> actions,
    required VoidCallback onEndWorkout,
  }) {
    return FitBottomSheet.show<void>(
      context: context,
      title: 'Mais opções',
      child: _WorkoutMoreOptionsContent(
        actions: actions,
        onEndWorkout: onEndWorkout,
      ),
    );
  }
}

class _WorkoutMoreOptionsContent extends StatelessWidget {
  const _WorkoutMoreOptionsContent({
    required this.actions,
    required this.onEndWorkout,
  });

  final List<WorkoutQuickAction> actions;
  final VoidCallback onEndWorkout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: FitSpacing.s8),
              Expanded(
                child: _MoreOptionsActionTile(
                  action: actions[index],
                  onTap: () => _openAction(context, actions[index]),
                ),
              ),
            ],
          ],
        ),
        const Divider(height: FitSpacing.s16, color: FitColors.outlineSoft),
        SizedBox(
          width: double.infinity,
          child: FitButton(
            label: 'Encerrar treino',
            leadingIcon: Icons.stop_circle_outlined,
            onPressed: () => _endWorkout(context),
            variant: FitButtonVariant.danger,
          ),
        ),
      ],
    );
  }

  void _openAction(BuildContext context, WorkoutQuickAction action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action.onTap());
  }

  void _endWorkout(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => onEndWorkout());
  }
}

class _MoreOptionsActionTile extends StatelessWidget {
  const _MoreOptionsActionTile({required this.action, required this.onTap});

  final WorkoutQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? FitColors.textPrimary;
    return Tooltip(
      message: action.label,
      child: Semantics(
        button: true,
        label: action.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: FitRadius.mediumBorder,
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: color, size: 18),
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
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
