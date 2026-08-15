import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../widgets/exercicio_gif_viewer.dart';
import 'workout_session_models.dart';

/// Conteudo principal da sessao de treino, inspirado no prototipo HTML
/// canonico. Ele e puramente apresentacional e nao controla timers ou dados.
class WorkoutExercisePanel extends StatelessWidget {
  const WorkoutExercisePanel({
    super.key,
    required this.exercise,
    required this.exerciseNumber,
    required this.targetSets,
    required this.completedSets,
    required this.repetitionsController,
    required this.weightController,
    required this.restSeconds,
    required this.isResting,
    required this.history,
    required this.onViewExecution,
    required this.onViewMuscles,
    required this.onCompleteSet,
    required this.onRestTap,
    required this.onViewAllHistory,
    required this.onChanged,
    this.restTotalSeconds = 60,
    this.restPaused = false,
    this.nextExerciseName,
    this.onRestTogglePause,
    this.onRestSkip,
    this.onRestAddTime,
  });

  final ExercicioModel exercise;
  final int exerciseNumber;
  final int targetSets;
  final int completedSets;
  final TextEditingController repetitionsController;
  final TextEditingController weightController;
  final int restSeconds;
  final bool isResting;
  final List<WorkoutSetSnapshot> history;
  final VoidCallback onViewExecution;
  final VoidCallback onViewMuscles;
  final Future<void> Function() onCompleteSet;
  final VoidCallback onRestTap;
  final VoidCallback onViewAllHistory;
  final ValueChanged<String> onChanged;
  final int restTotalSeconds;
  final bool restPaused;
  final String? nextExerciseName;
  final VoidCallback? onRestTogglePause;
  final VoidCallback? onRestSkip;
  final VoidCallback? onRestAddTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExerciseHeading(
          exercise: exercise,
          number: exerciseNumber,
          onViewMuscles: onViewMuscles,
        ),
        const SizedBox(height: FitSpacing.s12),
        _ExerciseMediaHero(
          exercise: exercise,
          onViewExecution: onViewExecution,
        ),
        const SizedBox(height: FitSpacing.s16),
        _WorkoutIndicators(
          repetitions: _targetRepetitions(exercise, repetitionsController.text),
          restSeconds: restSeconds,
          isResting: isResting,
          completedSets: completedSets,
          targetSets: targetSets,
          onRestTap: onRestTap,
        ),
        const SizedBox(height: FitSpacing.s16),
        _RegisterSetPanel(
          repetitionsController: repetitionsController,
          weightController: weightController,
          onChanged: onChanged,
          onCompleteSet: onCompleteSet,
        ),
        if (isResting) ...[
          const SizedBox(height: FitSpacing.s12),
          _RestContext(
            seconds: restSeconds,
            totalSeconds: restTotalSeconds,
            paused: restPaused,
            nextExerciseName: nextExerciseName,
            onTogglePause: onRestTogglePause,
            onSkip: onRestSkip ?? onRestTap,
            onAddTime: onRestAddTime,
          ),
        ],
        const SizedBox(height: FitSpacing.s16),
        _SetHistoryPanel(
          completedSets: completedSets,
          targetSets: targetSets,
          history: history,
          onViewAll: onViewAllHistory,
        ),
      ],
    );
  }

  static String _targetRepetitions(
    ExercicioModel exercise,
    String currentValue,
  ) {
    final range = exercise.repeticoes.trim();
    if (range.isNotEmpty) return range;
    return currentValue.trim().isEmpty ? '-' : currentValue.trim();
  }
}

class _ExerciseHeading extends StatelessWidget {
  const _ExerciseHeading({
    required this.exercise,
    required this.number,
    required this.onViewMuscles,
  });

  final ExercicioModel exercise;
  final int number;
  final VoidCallback onViewMuscles;

  @override
  Widget build(BuildContext context) {
    final muscles = _muscles(exercise);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: FitSpacing.s32,
              height: FitSpacing.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: FitRadius.smallBorder,
              ),
              child: Text(
                '$number',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.onPrimary),
              ),
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Text(
                'EXERCICIO ATUAL',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s8),
        Text(
          exercise.nome,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: FitSpacing.s4),
        Tooltip(
          message: 'Ver musculos trabalhados',
          child: Semantics(
            button: true,
            label: 'Ver musculos trabalhados: $muscles',
            child: InkWell(
              onTap: onViewMuscles,
              borderRadius: FitRadius.smallBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FitSpacing.s4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        muscles,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: FitLayout.iconSizeCompact,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _muscles(ExercicioModel value) {
    final names = <String>{
      ...value.musculos.where((name) => name.trim().isNotEmpty),
      ...value.musculosSecundarios.where((name) => name.trim().isNotEmpty),
    }.take(3).toList();
    if (names.isEmpty && value.categoria.trim().isNotEmpty) {
      names.add(value.categoria.trim());
    }
    return names.isEmpty ? 'Grupo muscular nao informado' : names.join(' - ');
  }
}

class _ExerciseMediaHero extends StatelessWidget {
  const _ExerciseMediaHero({
    required this.exercise,
    required this.onViewExecution,
  });

  final ExercicioModel exercise;
  final VoidCallback onViewExecution;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Abrir midia do exercicio ${exercise.nome} em tela cheia',
      child: Tooltip(
        message: 'Toque para ampliar',
        child: InkWell(
          onTap: onViewExecution,
          borderRadius: FitRadius.mediumBorder,
          child: AspectRatio(
            aspectRatio: FitLayout.domainCompactMediaAspectRatio,
            child: ClipRRect(
              borderRadius: FitRadius.mediumBorder,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExercicioGifImage(
                    imagem: exercise.imagem,
                    titulo: exercise.nome,
                    gifPath: exercise.gifPath,
                    fit: BoxFit.contain,
                    cacheHeight: 640,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: Theme.of(context).fitGradients.mediaScrim,
                    ),
                  ),
                  Positioned(
                    left: FitSpacing.s12,
                    bottom: FitSpacing.s12,
                    child: _MediaBadge(
                      icon: Icons.circle,
                      label: 'GIF',
                      iconColor: colors.primary,
                    ),
                  ),
                  const Positioned(
                    right: FitSpacing.s12,
                    bottom: FitSpacing.s12,
                    child: _MediaBadge(
                      icon: Icons.fullscreen_rounded,
                      label: 'Toque para ampliar',
                    ),
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

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s8,
        vertical: FitSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).fitSemanticColors.overlayScrim,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: FitRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: FitLayout.iconSizeSmall,
            color: iconColor ?? colors.onSurface,
          ),
          const SizedBox(width: FitSpacing.s4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _WorkoutIndicators extends StatelessWidget {
  const _WorkoutIndicators({
    required this.repetitions,
    required this.restSeconds,
    required this.isResting,
    required this.completedSets,
    required this.targetSets,
    required this.onRestTap,
  });

  final String repetitions;
  final int restSeconds;
  final bool isResting;
  final int completedSets;
  final int targetSets;
  final VoidCallback onRestTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Indicator(value: repetitions, label: 'Reps'),
        ),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: _Indicator(
            value: _formatTime(restSeconds),
            label: 'Descanso',
            selected: isResting,
            onTap: onRestTap,
            semanticLabel: isResting
                ? 'Descanso em andamento, ${_formatTime(restSeconds)} restantes'
                : 'Iniciar descanso de ${_formatTime(restSeconds)}',
          ),
        ),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: _Indicator(
            value: '${completedSets + 1}/$targetSets',
            label: 'Series',
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.value,
    required this.label,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  final String value;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer
              : Theme.of(context).fitSemanticColors.surfaceSubtle,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(FitSpacing.s8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: selected ? colors.primary : null,
                    ),
                  ),
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: semanticLabel ?? '$label $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FitLayout.domainProgressRingLarge),
        child: content,
      ),
    );
  }
}

class _RegisterSetPanel extends StatelessWidget {
  const _RegisterSetPanel({
    required this.repetitionsController,
    required this.weightController,
    required this.onChanged,
    required this.onCompleteSet,
  });

  final TextEditingController repetitionsController;
  final TextEditingController weightController;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onCompleteSet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s16,
        FitSpacing.s12,
        FitSpacing.s12,
        FitSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).fitSemanticColors.surfaceSubtle,
        border: Border(left: BorderSide(color: colors.primary, width: 4)),
        borderRadius: FitRadius.mediumBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REGISTRAR SERIE',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: FitSpacing.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              final fields = Row(
                children: [
                  Expanded(
                    child: _MetricInput(
                      controller: weightController,
                      label: 'Carga',
                      unit: 'kg',
                      decimal: true,
                      semanticLabel: 'Carga em quilogramas',
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: FitSpacing.s8),
                  Expanded(
                    child: _MetricInput(
                      controller: repetitionsController,
                      label: 'Reps',
                      semanticLabel: 'Quantidade de repeticoes',
                      onChanged: onChanged,
                    ),
                  ),
                ],
              );
              final submit = SizedBox(
                width: compact ? double.infinity : FitLayout.buttonHeightLarge,
                height: FitLayout.buttonHeightLarge,
                child: FitButton(
                  label: '+',
                  semanticLabel: 'Registrar serie',
                  tooltip: 'Registrar serie',
                  size: FitButtonSize.large,
                  onPressedAsync: onCompleteSet,
                  enableHapticFeedback: true,
                ),
              );
              if (compact) {
                return Column(
                  children: [
                    fields,
                    const SizedBox(height: FitSpacing.s8),
                    submit,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: fields),
                  const SizedBox(width: FitSpacing.s8),
                  submit,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricInput extends StatelessWidget {
  const _MetricInput({
    required this.controller,
    required this.label,
    required this.semanticLabel,
    required this.onChanged,
    this.unit,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String semanticLabel;
  final ValueChanged<String> onChanged;
  final String? unit;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      textField: true,
      label: semanticLabel,
      child: Container(
        height: FitLayout.buttonHeightLarge,
        padding: const EdgeInsets.symmetric(horizontal: FitSpacing.s12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: FitRadius.smallBorder,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: FitSpacing.s4),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  right: unit == null ? 0 : FitSpacing.s20,
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: decimal,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      decimal ? RegExp(r'[0-9,.]') : RegExp(r'[0-9]'),
                    ),
                  ],
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleLarge,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
            if (unit != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: FitSpacing.s8),
                  child: Text(
                    unit!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RestContext extends StatelessWidget {
  const _RestContext({
    required this.seconds,
    required this.totalSeconds,
    required this.paused,
    required this.nextExerciseName,
    this.onTogglePause,
    this.onSkip,
    this.onAddTime,
  });

  final int seconds;
  final int totalSeconds;
  final bool paused;
  final String? nextExerciseName;
  final VoidCallback? onTogglePause;
  final VoidCallback? onSkip;
  final VoidCallback? onAddTime;

  @override
  Widget build(BuildContext context) {
    final message = nextExerciseName == null
        ? 'Proxima serie fica pronta ao terminar.'
        : 'Proximo: $nextExerciseName';
    final label = _formatTime(seconds);
    final safeTotal = totalSeconds <= 0 ? 1 : totalSeconds;
    final progress = ((safeTotal - seconds) / safeTotal).clamp(0.0, 1.0);
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: paused
          ? 'Descanso pausado em $label'
          : 'Descanso em andamento, $label restantes',
      child: Container(
        padding: const EdgeInsets.all(FitSpacing.s12),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          border: Border(left: BorderSide(color: colors.primary, width: 4)),
          borderRadius: FitRadius.smallBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    paused ? 'Descanso pausado' : 'Descanso iniciado',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.primary),
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: FitSpacing.s4),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: FitSpacing.s8),
            FitProgress(
              value: progress,
              height: FitLayout.progressCompactThickness,
            ),
            const SizedBox(height: FitSpacing.s8),
            Wrap(
              spacing: FitSpacing.s8,
              runSpacing: FitSpacing.s8,
              children: [
                if (onAddTime != null)
                  FitButton(
                    label: '+15 s',
                    variant: FitButtonVariant.ghost,
                    size: FitButtonSize.compact,
                    onPressed: onAddTime,
                  ),
                if (onTogglePause != null)
                  FitButton(
                    label: paused ? 'Retomar' : 'Pausar',
                    variant: FitButtonVariant.ghost,
                    size: FitButtonSize.compact,
                    onPressed: onTogglePause,
                  ),
                if (onSkip != null)
                  FitButton(
                    label: 'Pular',
                    variant: FitButtonVariant.ghost,
                    size: FitButtonSize.compact,
                    onPressed: onSkip,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int value) {
    final minutes = (value ~/ 60).toString().padLeft(2, '0');
    final seconds = (value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SetHistoryPanel extends StatelessWidget {
  const _SetHistoryPanel({
    required this.completedSets,
    required this.targetSets,
    required this.history,
    required this.onViewAll,
  });

  final int completedSets;
  final int targetSets;
  final List<WorkoutSetSnapshot> history;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final completed = history
        .where((set) => set.isCompleted)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2;
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REGISTRO ATUAL',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  'Historico',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            );
            final actions = Wrap(
              spacing: FitSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('$completedSets de $targetSets'),
                FitButton(
                  label: 'Ver todas',
                  variant: FitButtonVariant.ghost,
                  size: FitButtonSize.compact,
                  onPressed: onViewAll,
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: FitSpacing.s8),
                  actions,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: heading),
                actions,
              ],
            );
          },
        ),
        const SizedBox(height: FitSpacing.s12),
        if (completed.isEmpty)
          const _HistoryEmptyState()
        else
          Column(
            children: [
              for (final set in completed) ...[
                _HistoryRow(snapshot: set),
                const SizedBox(height: FitSpacing.s8),
              ],
            ],
          ),
      ],
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: Theme.of(context).dividerColor),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s16),
      child: Text(
        'Registre sua primeira serie.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.snapshot});

  final WorkoutSetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label:
          'Serie ${snapshot.number}, ${snapshot.weight} quilogramas por ${snapshot.repetitions} repeticoes',
      child: Container(
        constraints: const BoxConstraints(
          minHeight: FitLayout.minimumTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s12,
          vertical: FitSpacing.s8,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Container(
              width: FitLayout.iconSizeLarge,
              height: FitLayout.iconSizeLarge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text('${snapshot.number}'),
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Text(
                '${snapshot.weight} kg x ${snapshot.repetitions}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              '${snapshot.restSeconds}s',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
