import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../screens/treinos/widgets/plans/plan_media.dart';

/// Estados visuais que a camada de aplicacao pode fornecer ao pre-treino.
///
/// O preview atual recebe um plano ja carregado, portanto a pagina oficial usa
/// [WorkoutPreparationStatus.ready]. As outras variantes deixam a superficie
/// preparada para uma futura fonte de carregamento sem inventar esse contrato.
enum WorkoutPreparationStatus { ready, loading, offline, error, partial }

/// Composicao visual do pre-treino. Recebe somente dados e comandos externos.
class WorkoutPreparationContent extends StatelessWidget {
  const WorkoutPreparationContent({
    super.key,
    required this.workoutName,
    required this.planLabel,
    required this.exercises,
    required this.estimatedMinutes,
    required this.defaultRestSeconds,
    required this.onBack,
    required this.onOpenExercise,
    required this.onOpenExerciseList,
    this.status = WorkoutPreparationStatus.ready,
    this.errorMessage,
  });

  final String workoutName;
  final String planLabel;
  final List<ExercicioModel> exercises;
  final int estimatedMinutes;
  final int defaultRestSeconds;
  final VoidCallback onBack;
  final ValueChanged<ExercicioModel> onOpenExercise;
  final VoidCallback onOpenExerciseList;
  final WorkoutPreparationStatus status;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (status == WorkoutPreparationStatus.loading) {
      return const _WorkoutPreparationSkeleton();
    }

    return ListView(
      key: const PageStorageKey<String>('workout-preparation-list'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FitSpacing.s16,
        FitSpacing.s12,
        FitSpacing.s16,
        FitSpacing.s32,
      ),
      children: [
        _PreparationHeader(
          workoutName: workoutName,
          planLabel: planLabel,
          onBack: onBack,
        ),
        const SizedBox(height: FitSpacing.s20),
        if (status == WorkoutPreparationStatus.offline) ...[
          const FitOfflineState(compact: true),
          const SizedBox(height: FitSpacing.s16),
        ],
        if (status == WorkoutPreparationStatus.partial) ...[
          const FitInfoCard(
            title: 'Alguns detalhes estao indisponiveis',
            description:
                'O treino continua pronto para iniciar com os dados salvos.',
            icon: FitIcons.warning,
            tone: FitInfoCardTone.warning,
          ),
          const SizedBox(height: FitSpacing.s16),
        ],
        if (status == WorkoutPreparationStatus.error)
          FitErrorState(
            title: 'Nao foi possivel preparar o treino',
            error:
                errorMessage ??
                'Confira o plano salvo e tente abrir o treino novamente.',
          )
        else if (exercises.isEmpty)
          const FitEmptyState(
            icon: FitIcons.workout,
            title: 'Treino sem exercicios',
            description: 'Adicione exercicios ao plano antes de iniciar.',
          )
        else ...[
          _WorkoutPreparationHero(
            exercise: exercises.first,
            planLabel: planLabel,
            onOpenExercise: () => onOpenExercise(exercises.first),
          ),
          const SizedBox(height: FitSpacing.s20),
          _WorkoutPreparationSummary(
            exerciseCount: exercises.length,
            setCount: _setCount(exercises),
            estimatedMinutes: estimatedMinutes,
          ),
          const SizedBox(height: FitSpacing.s16),
          _WorkoutPreparationContext(
            focus: _focus(exercises),
            equipment: _equipment(exercises),
            defaultRestSeconds: defaultRestSeconds,
          ),
          const SizedBox(height: FitSpacing.s24),
          _WorkoutPreparationExerciseSection(
            exercises: exercises,
            onOpenExercise: onOpenExercise,
            onOpenExerciseList: onOpenExerciseList,
          ),
        ],
      ],
    );
  }

  static int _setCount(List<ExercicioModel> values) =>
      values.fold<int>(0, (total, exercise) => total + _setsFor(exercise));

  static int _setsFor(ExercicioModel exercise) =>
      exercise.series <= 0 ? 3 : exercise.series;

  static String _focus(List<ExercicioModel> values) {
    final muscles = values
        .expand((exercise) => exercise.musculos)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .take(3);
    return muscles.isEmpty ? 'Nao informado' : muscles.join(' · ');
  }

  static String _equipment(List<ExercicioModel> values) {
    final equipment = values
        .expand((exercise) => exercise.equipamentos)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .take(3);
    return equipment.isEmpty ? 'Nao informado' : equipment.join(' · ');
  }
}

class _PreparationHeader extends StatelessWidget {
  const _PreparationHeader({
    required this.workoutName,
    required this.planLabel,
    required this.onBack,
  });

  final String workoutName;
  final String planLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Preparar treino, $workoutName, $planLabel',
      child: Row(
        children: [
          FitIconButton(
            icon: FitIcons.back,
            tooltip: 'Voltar para o detalhe do plano',
            variant: FitIconButtonVariant.outlined,
            onPressed: onBack,
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              children: [
                Text(
                  'PREPARAR TREINO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: FitSpacing.s4),
                Text(
                  workoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: FitSpacing.s2),
                Text(
                  planLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          const SizedBox.square(dimension: FitLayout.minimumTouchTarget),
        ],
      ),
    );
  }
}

class _WorkoutPreparationHero extends StatelessWidget {
  const _WorkoutPreparationHero({
    required this.exercise,
    required this.planLabel,
    required this.onOpenExercise,
  });

  final ExercicioModel exercise;
  final String planLabel;
  final VoidCallback onOpenExercise;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final muscles = <String>{
      ...exercise.musculos.where((name) => name.trim().isNotEmpty),
      ...exercise.musculosSecundarios.where((name) => name.trim().isNotEmpty),
    }.take(3).join(' · ');

    return FitCard(
      variant: FitCardVariant.outlined,
      padding: const EdgeInsets.all(FitSpacing.s12),
      semanticLabel: 'Primeiro exercicio, ${exercise.nome}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FitSpacing.s8,
            runSpacing: FitSpacing.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FitBadge(
                label: largeText ? 'Primeiro' : 'Primeiro exercicio',
                tone: FitBadgeTone.success,
                icon: largeText ? null : FitIcons.play,
              ),
              Text(planLabel, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: FitSpacing.s12),
          Text(
            exercise.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (muscles.isNotEmpty) ...[
            const SizedBox(height: FitSpacing.s4),
            Text(
              muscles,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: FitSpacing.s16),
          FitExerciseMedia(
            semanticLabel: 'Midia do exercicio ${exercise.nome}',
            fallbackLabel: 'Midia de ${exercise.nome} indisponivel',
            onTap: onOpenExercise,
            child: ExerciseMedia(exercise: exercise),
          ),
          const SizedBox(height: FitSpacing.s12),
          Align(
            alignment: Alignment.centerRight,
            child: FitOutlinedButton(
              label: 'Ver execucao',
              icon: FitIcons.play,
              onPressed: onOpenExercise,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPreparationSummary extends StatelessWidget {
  const _WorkoutPreparationSummary({
    required this.exerciseCount,
    required this.setCount,
    required this.estimatedMinutes,
  });

  final int exerciseCount;
  final int setCount;
  final int estimatedMinutes;

  @override
  Widget build(BuildContext context) {
    return FitWorkoutSummaryCard(
      title: 'Resumo do treino',
      metrics: [
        FitMetricData(
          label: 'Exercicios',
          value: '$exerciseCount',
          icon: FitIcons.exercise,
        ),
        FitMetricData(
          label: 'Series',
          value: '$setCount',
          icon: FitIcons.repetitions,
        ),
        FitMetricData(
          label: 'Duracao',
          value: '$estimatedMinutes',
          unit: 'min',
          icon: FitIcons.timer,
        ),
      ],
    );
  }
}

class _WorkoutPreparationContext extends StatelessWidget {
  const _WorkoutPreparationContext({
    required this.focus,
    required this.equipment,
    required this.defaultRestSeconds,
  });

  final String focus;
  final String equipment;
  final int defaultRestSeconds;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      padding: const EdgeInsets.all(FitSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreparationContextRow(
            icon: FitIcons.muscles,
            label: 'Foco muscular',
            value: focus,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: FitSpacing.s8),
            child: Divider(height: FitLayout.none),
          ),
          _PreparationContextRow(
            icon: FitIcons.equipment,
            label: 'Equipamentos',
            value: equipment,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: FitSpacing.s8),
            child: Divider(height: FitLayout.none),
          ),
          _PreparationContextRow(
            icon: FitIcons.timer,
            label: 'Descanso padrao',
            value: _restLabel(defaultRestSeconds),
          ),
        ],
      ),
    );
  }

  String _restLabel(int value) {
    final seconds = value.clamp(0, 599);
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _PreparationContextRow extends StatelessWidget {
  const _PreparationContextRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: FitSpacing.s2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkoutExerciseList extends StatelessWidget {
  const _WorkoutExerciseList({
    required this.exercises,
    required this.onOpenExercise,
  });

  final List<ExercicioModel> exercises;
  final ValueChanged<ExercicioModel> onOpenExercise;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < exercises.length; index++) ...[
            FitExerciseCompactRow(
              name: exercises[index].nome,
              subtitle: _prescription(exercises[index]),
              media: _ExerciseOrder(index: index + 1),
              onTap: () => onOpenExercise(exercises[index]),
            ),
            if (index != exercises.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: FitSpacing.s12),
                child: Divider(height: FitLayout.none),
              ),
          ],
        ],
      ),
    );
  }

  String _prescription(ExercicioModel exercise) {
    final sets = exercise.series <= 0 ? 3 : exercise.series;
    final repetitions = exercise.repeticoes.trim().isEmpty
        ? '8-12'
        : exercise.repeticoes;
    final rest = exercise.descansoSegundos <= 0
        ? '--'
        : '${exercise.descansoSegundos}s';
    return '$sets series · $repetitions reps · $rest descanso';
  }
}

class _WorkoutPreparationExerciseSection extends StatelessWidget {
  const _WorkoutPreparationExerciseSection({
    required this.exercises,
    required this.onOpenExercise,
    required this.onOpenExerciseList,
  });

  final List<ExercicioModel> exercises;
  final ValueChanged<ExercicioModel> onOpenExercise;
  final VoidCallback onOpenExerciseList;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Exercicios do treino',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge,
    );
    final subtitle = Text(
      '${exercises.length} na ordem do plano',
      style: Theme.of(context).textTheme.bodyMedium,
    );
    final action = TextButton(
      onPressed: onOpenExerciseList,
      child: const Text('Ver lista'),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (largeText) ...[
          title,
          const SizedBox(height: FitSpacing.s4),
          subtitle,
          Align(alignment: Alignment.centerRight, child: action),
        ] else ...[
          Row(
            children: [
              Expanded(child: title),
              action,
            ],
          ),
          const SizedBox(height: FitSpacing.s4),
          subtitle,
        ],
        const SizedBox(height: FitSpacing.s12),
        _WorkoutExerciseList(
          exercises: exercises,
          onOpenExercise: onOpenExercise,
        ),
      ],
    );
  }
}

class _ExerciseOrder extends StatelessWidget {
  const _ExerciseOrder({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FitLayout.domainThumbnailSmall,
      height: FitLayout.domainThumbnailSmall,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: FitRadius.mediumBorder,
      ),
      child: Text(
        '$index',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _WorkoutPreparationSkeleton extends StatelessWidget {
  const _WorkoutPreparationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: const [
        Row(
          children: [
            FitSkeleton(
              height: FitLayout.minimumTouchTarget,
              width: FitLayout.minimumTouchTarget,
            ),
            SizedBox(width: FitSpacing.s12),
            Expanded(child: FitSkeleton(height: FitSpacing.s20)),
          ],
        ),
        SizedBox(height: FitSpacing.s24),
        FitSkeleton(height: FitLayout.domainChartHeight),
        SizedBox(height: FitSpacing.s16),
        FitSkeleton(height: FitLayout.skeletonListItemHeight),
        SizedBox(height: FitSpacing.s12),
        FitSkeleton(height: FitLayout.skeletonListItemHeight),
        SizedBox(height: FitSpacing.s12),
        FitSkeleton(height: FitLayout.skeletonListItemHeight),
      ],
    );
  }
}
