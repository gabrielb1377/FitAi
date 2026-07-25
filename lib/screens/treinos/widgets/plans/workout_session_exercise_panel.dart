import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../widgets/exercicio_gif_viewer.dart';
import 'workout_session_models.dart';

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
    required this.onCompleteSet,
    required this.onRestTap,
    required this.onViewAllHistory,
    required this.onChanged,
    this.restTotalSeconds = 60,
    this.restPaused = false,
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
  final Future<void> Function() onCompleteSet;
  final VoidCallback onRestTap;
  final VoidCallback onViewAllHistory;
  final ValueChanged<String> onChanged;
  final int restTotalSeconds;
  final bool restPaused;
  final VoidCallback? onRestTogglePause;
  final VoidCallback? onRestSkip;
  final VoidCallback? onRestAddTime;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      padding: const EdgeInsets.all(FitSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExerciseHeading(
            exercise: exercise,
            number: exerciseNumber,
            onViewExecution: onViewExecution,
          ),
          const SizedBox(height: FitSpacing.s16),
          _ExerciseMediaHero(exercise: exercise),
          const SizedBox(height: FitSpacing.s12),
          Text(
            '$targetSets séries  •  ${_repetitions(exercise)} reps  •  ${_configuredRest(exercise)}s descanso',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FitSpacing.s16),
          SizedBox(
            height: 56,
            child: FitButton(
              label: 'CONCLUIR SÉRIE',
              leadingIcon: Icons.check_circle_rounded,
              onPressedAsync: onCompleteSet,
              expand: true,
            ),
          ),
          const SizedBox(height: FitSpacing.s16),
          _WorkoutMetricsRow(
            repetitionsController: repetitionsController,
            weightController: weightController,
            restSeconds: restSeconds,
            isResting: isResting,
            onRestTap: onRestTap,
            onChanged: onChanged,
          ),
          if (isResting) ...[
            const SizedBox(height: FitSpacing.s12),
            _InlineRestTimer(
              seconds: restSeconds,
              totalSeconds: restTotalSeconds,
              paused: restPaused,
              onTogglePause: onRestTogglePause,
              onSkip: onRestSkip ?? onRestTap,
              onAddTime: onRestAddTime,
            ),
          ],
          const SizedBox(height: FitSpacing.s20),
          _SetHistoryStrip(
            completedSets: completedSets,
            targetSets: targetSets,
            history: history,
            onViewAll: onViewAllHistory,
          ),
        ],
      ),
    );
  }

  static String _repetitions(ExercicioModel value) =>
      value.repeticoes.trim().isEmpty ? '8-12' : value.repeticoes;

  static int _configuredRest(ExercicioModel value) =>
      value.descansoSegundos <= 0 ? 60 : value.descansoSegundos;
}

/// Descanso entre séries mostrado dentro do painel do exercício ativo.
///
/// O relógio é controlado pela sessão; este widget apenas representa o estado
/// atual e encaminha as ações do usuário.
class _InlineRestTimer extends StatelessWidget {
  const _InlineRestTimer({
    required this.seconds,
    required this.totalSeconds,
    required this.paused,
    this.onTogglePause,
    this.onSkip,
    this.onAddTime,
  });

  final int seconds;
  final int totalSeconds;
  final bool paused;
  final VoidCallback? onTogglePause;
  final VoidCallback? onSkip;
  final VoidCallback? onAddTime;

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    final safeTotal = totalSeconds <= 0 ? 1 : totalSeconds;
    final progress = ((safeTotal - seconds) / safeTotal).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: paused ? 'Descanso pausado' : 'Descanso entre séries',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paused ? 'Descanso pausado' : 'Descanso entre séries',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: FitSpacing.s8),
          FitRestTimerWidget(
            embedded: true,
            remainingLabel: '$minutes:$remainder',
            progress: progress,
            progressRingSize: FitLayout.domainThumbnailSmall,
            paused: paused,
            onTogglePause: onTogglePause,
            onSkip: onSkip,
            onAddTime: onAddTime,
            addTimeLabel: '+15 s',
          ),
        ],
      ),
    );
  }
}

class _ExerciseHeading extends StatelessWidget {
  const _ExerciseHeading({
    required this.exercise,
    required this.number,
    required this.onViewExecution,
  });

  final ExercicioModel exercise;
  final int number;
  final VoidCallback onViewExecution;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 320;
            final numberBadge = Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: FitColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: FitColors.onPrimary),
              ),
            );
            final label = Text(
              'EXERCÍCIO ATUAL',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: FitColors.primary),
            );
            final action = FitButton(
              label: 'Ver execução',
              leadingIcon: Icons.play_arrow_rounded,
              size: FitButtonSize.compact,
              variant: FitButtonVariant.outlined,
              onPressed: onViewExecution,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      numberBadge,
                      const SizedBox(width: FitSpacing.s12),
                      Expanded(child: label),
                    ],
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              children: [
                numberBadge,
                const SizedBox(width: FitSpacing.s12),
                Expanded(child: label),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: FitSpacing.s12),
        Text(
          exercise.nome,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: FitSpacing.s8),
        Text(
          _muscles(exercise),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
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
    return names.isEmpty ? 'Grupo muscular não informado' : names.join('  •  ');
  }
}

class _ExerciseMediaHero extends StatelessWidget {
  const _ExerciseMediaHero({required this.exercise});

  final ExercicioModel exercise;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: FitRadius.mediumBorder,
              child: ExercicioGifImage(
                imagem: exercise.imagem,
                titulo: exercise.nome,
                gifPath: exercise.gifPath,
                fit: BoxFit.contain,
                cacheHeight: 640,
              ),
            ),
          ),
          Positioned(
            left: FitSpacing.s12,
            bottom: FitSpacing.s12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FitSpacing.s12,
                vertical: FitSpacing.s8,
              ),
              decoration: const BoxDecoration(
                color: FitColors.overlay,
                borderRadius: FitRadius.mediumBorder,
              ),
              child: const Text('GIF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutMetricsRow extends StatelessWidget {
  const _WorkoutMetricsRow({
    required this.repetitionsController,
    required this.weightController,
    required this.restSeconds,
    required this.isResting,
    required this.onRestTap,
    required this.onChanged,
  });

  final TextEditingController repetitionsController;
  final TextEditingController weightController;
  final int restSeconds;
  final bool isResting;
  final VoidCallback onRestTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s12),
      decoration: BoxDecoration(
        border: Border.all(color: FitColors.outlineSoft),
        borderRadius: FitRadius.mediumBorder,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _MetricInput(
                icon: Icons.repeat_rounded,
                controller: repetitionsController,
                label: 'reps',
                onChanged: onChanged,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _MetricInput(
                icon: Icons.fitness_center_rounded,
                controller: weightController,
                label: 'kg',
                decimal: true,
                onChanged: onChanged,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _RestMetric(
                seconds: restSeconds,
                isResting: isResting,
                onTap: onRestTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricInput extends StatelessWidget {
  const _MetricInput({
    required this.icon,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.decimal = false,
  });

  final IconData icon;
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: FitColors.primary, size: 22),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9,.]') : RegExp(r'[0-9]'),
            ),
          ],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: FitSpacing.s4),
          ),
          onChanged: onChanged,
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RestMetric extends StatelessWidget {
  const _RestMetric({
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: FitColors.warning, size: 22),
          const SizedBox(height: FitSpacing.s4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$minutes:$remainder',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Text('descanso', style: Theme.of(context).textTheme.bodySmall),
          Text(
            isResting ? 'Pular' : 'Iniciar',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: FitColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SetHistoryStrip extends StatelessWidget {
  const _SetHistoryStrip({
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
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Text(
              'HISTÓRICO DA SÉRIE',
              style: Theme.of(context).textTheme.labelMedium,
            );
            final status = Text('$completedSets de $targetSets');
            final action = TextButton(
              onPressed: onViewAll,
              child: const Text('Ver todas'),
            );
            if (constraints.maxWidth < 320) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  Wrap(
                    spacing: FitSpacing.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [status, action],
                  ),
                ],
              );
            }
            return Wrap(
              spacing: FitSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [title, status, action],
            );
          },
        ),
        const SizedBox(height: FitSpacing.s8),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(width: FitSpacing.s8),
            itemBuilder: (context, index) =>
                _SetHistoryCard(snapshot: history[index]),
          ),
        ),
      ],
    );
  }
}

class _SetHistoryCard extends StatelessWidget {
  const _SetHistoryCard({required this.snapshot});

  final WorkoutSetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(FitSpacing.s12),
      decoration: BoxDecoration(
        color: snapshot.isCurrent
            ? FitColors.primaryContainer
            : Colors.transparent,
        borderRadius: FitRadius.mediumBorder,
        border: Border.all(
          color: snapshot.isCurrent ? FitColors.primary : FitColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: FitColors.textSecondary),
                ),
                child: Text('${snapshot.number}'),
              ),
              const Spacer(),
              if (snapshot.isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: FitColors.primary,
                  size: 22,
                ),
            ],
          ),
          const Spacer(),
          Text(
            '${snapshot.weight} kg x ${snapshot.repetitions}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: FitSpacing.s4),
          Text(
            '${snapshot.restSeconds}s',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
