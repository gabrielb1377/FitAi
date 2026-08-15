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
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: largeText ? 116 : 72,
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
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: FitSpacing.s4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
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
    final colors = Theme.of(context).colorScheme;
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
                ).textTheme.titleMedium?.copyWith(color: colors.primary),
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
    final primaryActions = <WorkoutQuickAction>[
      for (final label in const ['Coach IA', 'Histórico', 'Mais opções'])
        for (final action in actions)
          if (action.label == label) action,
    ];

    if (primaryActions.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: _QuickActionsRow(actions: primaryActions),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<WorkoutQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return _NarrowQuickActionsGrid(actions: actions);
        }
        return Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: FitSpacing.s8),
              Expanded(child: _QuickActionTile(action: actions[index])),
            ],
          ],
        );
      },
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
        crossAxisCount: 3,
        mainAxisExtent: FitLayout.buttonHeightLarge,
        crossAxisSpacing: FitSpacing.s8,
        mainAxisSpacing: FitSpacing.s8,
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
    final colors = Theme.of(context).colorScheme;
    final color = action.color ?? colors.onSurfaceVariant;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: colors.onSurface);

    return Tooltip(
      message: action.label,
      child: Semantics(
        button: true,
        label: action.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onTap,
            borderRadius: FitRadius.smallBorder,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FitLayout.minimumTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitSpacing.s4,
                  vertical: FitSpacing.s8,
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
      isScrollControlled: true,
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
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 4;
            final width =
                (constraints.maxWidth - (FitSpacing.s8 * (columns - 1))) /
                columns;
            return Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: width,
                    child: _MoreOptionsActionTile(
                      action: action,
                      onTap: () => _openAction(context, action),
                    ),
                  ),
              ],
            );
          },
        ),
        Divider(height: FitSpacing.s16, color: Theme.of(context).dividerColor),
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
    final color = action.color ?? Theme.of(context).colorScheme.onSurface;
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
    required this.exerciseIndex,
    required this.exerciseCount,
    this.onPrevious,
    this.onNext,
  });

  final int exerciseIndex;
  final int exerciseCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Navegação entre exercícios',
      child: Semantics(
        container: true,
        label:
            'Navegação entre exercícios. Exercício ${exerciseIndex + 1} de $exerciseCount',
        child: Container(
          padding: const EdgeInsets.only(top: FitSpacing.s16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              return Row(
                children: [
                  compact
                      ? FitIconButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Exercício anterior',
                          variant: FitIconButtonVariant.outlined,
                          onPressed: onPrevious,
                        )
                      : Expanded(
                          child: FitButton(
                            label: 'Anterior',
                            leadingIcon: Icons.chevron_left_rounded,
                            variant: FitButtonVariant.ghost,
                            onPressed: onPrevious,
                            expand: true,
                          ),
                        ),
                  const SizedBox(width: FitSpacing.s8),
                  SizedBox(
                    width: FitLayout.buttonHeightLarge,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (exerciseIndex + 1).toString().padLeft(2, '0'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          'de $exerciseCount',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: FitSpacing.s8),
                  compact
                      ? FitIconButton(
                          icon: Icons.chevron_right_rounded,
                          tooltip: 'Próximo exercício',
                          variant: FitIconButtonVariant.outlined,
                          onPressed: onNext,
                        )
                      : Expanded(
                          child: FitButton(
                            label: 'Próximo',
                            trailingIcon: Icons.chevron_right_rounded,
                            variant: FitButtonVariant.ghost,
                            onPressed: onNext,
                            expand: true,
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
