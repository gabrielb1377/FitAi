import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../../../models/exercise_progression_model.dart';

/// Sugestao explicavel para a proxima execucao; exige confirmacao do usuario.
class ExerciseNextProgressionCard extends StatelessWidget {
  final Future<ExerciseProgressionModel> future;
  final VoidCallback? onApply;
  final VoidCallback? onKeep;
  final VoidCallback? onViewHistory;
  final bool compact;

  const ExerciseNextProgressionCard({
    super.key,
    required this.future,
    this.onApply,
    this.onKeep,
    this.onViewHistory,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExerciseProgressionModel>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const FitLoading.inline(
            label: 'Calculando proxima progressao',
          );
        }
        if (snapshot.hasError) {
          return FitErrorState(
            title: 'Progressao indisponivel',
            error: 'Nao foi possivel analisar o historico deste exercicio.',
          );
        }
        final progression = snapshot.data;
        if (progression == null) return const SizedBox.shrink();
        return _Content(
          progression: progression,
          compact: compact,
          onApply: onApply,
          onKeep: onKeep,
          onViewHistory: onViewHistory,
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  final ExerciseProgressionModel progression;
  final bool compact;
  final VoidCallback? onApply;
  final VoidCallback? onKeep;
  final VoidCallback? onViewHistory;

  const _Content({
    required this.progression,
    required this.compact,
    this.onApply,
    this.onKeep,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayWeight = progression.suggestedWeight.toStringAsFixed(
      progression.suggestedWeight % 1 == 0 ? 0 : 1,
    );
    final title = compact
        ? 'Sugestao para esta execucao'
        : 'Proxima progressao';

    return FitCard(
      title: title,
      leading: const Icon(Icons.trending_up_rounded),
      trailing: FitBadge(
        label: progression.confidenceLabel,
        tone: switch (progression.confidence) {
          ExerciseProgressionConfidence.high => FitBadgeTone.success,
          ExerciseProgressionConfidence.medium => FitBadgeTone.info,
          ExerciseProgressionConfidence.low => FitBadgeTone.neutral,
        },
      ),
      variant: FitCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progression.actionLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progression.reason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Atual: ${_weight(progression.currentWeight)} kg, '
            '${progression.currentSets} series, '
            '${progression.currentRepRange} reps, '
            '${progression.currentRestSeconds}s descanso.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (progression.action !=
              ExerciseProgressionAction.insufficientData) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Metric(label: 'Carga', value: '$displayWeight kg'),
                _Metric(label: 'Series', value: '${progression.suggestedSets}'),
                _Metric(
                  label: 'Repeticoes',
                  value: progression.suggestedRepRange,
                ),
                _Metric(
                  label: 'Descanso',
                  value: '${progression.suggestedRestSeconds}s',
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (progression.isActionable && onApply != null)
                FitButton(
                  label: 'Aplicar',
                  icon: Icons.check_rounded,
                  size: FitButtonSize.compact,
                  onPressed: onApply,
                ),
              if (onKeep != null)
                FitButton(
                  label: 'Manter atual',
                  variant: FitButtonVariant.outlined,
                  size: FitButtonSize.compact,
                  onPressed: onKeep,
                ),
              if (onViewHistory != null)
                FitButton(
                  label: 'Ver historico',
                  variant: FitButtonVariant.ghost,
                  size: FitButtonSize.compact,
                  onPressed: onViewHistory,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _weight(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
