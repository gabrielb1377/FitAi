import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import 'plan_media.dart';

/// Superficie oficial PLAN-009. O estado e as regras da sessao permanecem no
/// controller legado; este widget cuida apenas da apresentacao e interacao.
class OfficialWorkoutSession extends StatelessWidget {
  const OfficialWorkoutSession({
    super.key,
    required this.title,
    required this.elapsedTime,
    required this.exercise,
    required this.exerciseIndex,
    required this.exerciseCount,
    required this.completedSets,
    required this.targetSets,
    required this.repetitionsController,
    required this.weightController,
    required this.restSeconds,
    required this.isResting,
    required this.progress,
    required this.onClose,
    required this.onExerciseTap,
    required this.onCompleteSet,
    required this.onRestTap,
    required this.onChanged,
    this.historyLines = const [],
    this.onSwapExercise,
    this.onEndWorkout,
    this.onPrevious,
    this.onNext,
  });

  final String title;
  final String elapsedTime;
  final ExercicioModel exercise;
  final int exerciseIndex;
  final int exerciseCount;
  final int completedSets;
  final int targetSets;
  final TextEditingController repetitionsController;
  final TextEditingController weightController;
  final int restSeconds;
  final bool isResting;
  final double progress;
  final VoidCallback onClose;
  final VoidCallback onExerciseTap;
  final VoidCallback onCompleteSet;
  final VoidCallback onRestTap;
  final ValueChanged<String> onChanged;
  final List<String> historyLines;
  final VoidCallback? onSwapExercise;
  final VoidCallback? onEndWorkout;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final currentSet = (completedSets + 1).clamp(1, targetSets).toInt();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s20,
                FitSpacing.s8,
                FitSpacing.s20,
                FitSpacing.s32,
              ),
              children: [
                _SessionHeader(title: title, onClose: onClose),
                const SizedBox(height: FitSpacing.s20),
                Semantics(
                  label: 'Tempo total $elapsedTime',
                  child: Column(
                    children: [
                      Text(
                        elapsedTime,
                        style: Theme.of(
                          context,
                        ).textTheme.displayMedium?.copyWith(fontSize: 54),
                      ),
                      const SizedBox(height: FitSpacing.s4),
                      Text(
                        'Tempo total',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FitSpacing.s24),
                FitProgress(value: progress, animate: true),
                const SizedBox(height: FitSpacing.s24),
                _SectionLabel(
                  label: 'Exercicio atual',
                  value: '${exerciseIndex + 1}/$exerciseCount',
                ),
                const SizedBox(height: FitSpacing.s12),
                FitCard(
                  variant: FitCardVariant.clickable,
                  padding: const EdgeInsets.all(FitSpacing.s12),
                  onTap: onExerciseTap,
                  semanticLabel: 'Acoes de ${exercise.nome}',
                  child: Row(
                    children: [
                      ExerciseMedia(exercise: exercise, width: 88, height: 88),
                      const SizedBox(width: FitSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: FitSpacing.s4),
                            Text(
                              '$targetSets series - ${_repetitions(exercise)} reps',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: FitSpacing.s24),
                _SectionLabel(
                  label: 'Serie atual',
                  value: '$currentSet de $targetSets',
                ),
                const SizedBox(height: FitSpacing.s12),
                Row(
                  children: [
                    Expanded(
                      child: _WorkoutValueField(
                        controller: repetitionsController,
                        label: 'Repeticoes',
                        semanticLabel: 'Repeticoes da serie atual',
                        onChanged: onChanged,
                      ),
                    ),
                    const SizedBox(width: FitSpacing.s12),
                    Expanded(
                      child: _WorkoutValueField(
                        controller: weightController,
                        label: 'Carga',
                        suffix: 'kg',
                        semanticLabel: 'Carga da serie atual em quilos',
                        decimal: true,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FitSpacing.s20),
                FitButton(
                  label: 'Concluir serie',
                  leadingIcon: Icons.check_rounded,
                  onPressed: onCompleteSet,
                  expand: true,
                ),
                const SizedBox(height: FitSpacing.s16),
                _RestAction(
                  seconds: restSeconds,
                  isResting: isResting,
                  onTap: onRestTap,
                ),
                if (historyLines.isNotEmpty) ...[
                  const SizedBox(height: FitSpacing.s16),
                  _SessionHistory(lines: historyLines),
                ],
                const SizedBox(height: FitSpacing.s16),
                Row(
                  children: [
                    Expanded(
                      child: FitButton(
                        label: 'Anterior',
                        leadingIcon: Icons.chevron_left_rounded,
                        variant: FitButtonVariant.ghost,
                        onPressed: onPrevious,
                      ),
                    ),
                    const SizedBox(width: FitSpacing.s8),
                    Expanded(
                      child: FitButton(
                        label: 'Proximo',
                        trailingIcon: Icons.chevron_right_rounded,
                        variant: FitButtonVariant.ghost,
                        onPressed: onNext,
                      ),
                    ),
                  ],
                ),
                if (onSwapExercise != null || onEndWorkout != null) ...[
                  const SizedBox(height: FitSpacing.s8),
                  Row(
                    children: [
                      if (onSwapExercise != null)
                        Expanded(
                          child: FitButton(
                            label: 'Trocar',
                            leadingIcon: Icons.swap_horiz_rounded,
                            variant: FitButtonVariant.ghost,
                            onPressed: onSwapExercise,
                          ),
                        ),
                      if (onSwapExercise != null && onEndWorkout != null)
                        const SizedBox(width: FitSpacing.s8),
                      if (onEndWorkout != null)
                        Expanded(
                          child: FitButton(
                            label: 'Encerrar',
                            leadingIcon: Icons.stop_circle_outlined,
                            variant: FitButtonVariant.outlined,
                            onPressed: onEndWorkout,
                          ),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: FitSpacing.s32 + bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _repetitions(ExercicioModel value) {
    return value.repeticoes.trim().isEmpty ? '8-12' : value.repeticoes;
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FitIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Encerrar treino',
              variant: FitIconButtonVariant.subtle,
              onPressed: onClose,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistory extends StatelessWidget {
  const _SessionHistory({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      padding: const EdgeInsets.all(FitSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historico desta sessao',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FitSpacing.s8),
          for (final line in lines.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: FitSpacing.s2),
              child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _WorkoutValueField extends StatelessWidget {
  const _WorkoutValueField({
    required this.controller,
    required this.label,
    required this.semanticLabel,
    required this.onChanged,
    this.suffix,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String semanticLabel;
  final String? suffix;
  final bool decimal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel,
      child: FitCard(
        variant: FitCardVariant.outlined,
        padding: const EdgeInsets.symmetric(
          horizontal: FitSpacing.s12,
          vertical: FitSpacing.s16,
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  decimal ? RegExp(r'[0-9,.]') : RegExp(r'[0-9]'),
                ),
              ],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixText: suffix,
              ),
              onChanged: onChanged,
            ),
            const SizedBox(height: FitSpacing.s8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _RestAction extends StatelessWidget {
  const _RestAction({
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
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: onTap,
      semanticLabel: isResting
          ? 'Descanso em andamento, $minutes minutos e $remainder segundos. Toque para pular.'
          : 'Iniciar descanso de $seconds segundos',
      child: Row(
        children: [
          Expanded(
            child: Text(
              isResting ? 'Pular descanso' : 'Descanso',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            '$minutes:$remainder',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isResting ? FitColors.primary : FitColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
