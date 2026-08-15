import 'package:flutter/material.dart';

import '../../../core/design_system/components/navigation/fit_containers.dart';
import '../../../core/exercises/exercise_library_intelligence.dart';
import '../../../models/exercicio_model.dart';

Future<void> showLibraryExerciseComparisonSheet({
  required BuildContext context,
  required ExercicioModel source,
  required List<ExerciseRecommendation> candidates,
  ExerciseLibraryIntelligence intelligence =
      const ExerciseLibraryIntelligence(),
}) async {
  if (candidates.isEmpty) return;
  await FitBottomSheetContainer.show<void>(
    context: context,
    title: 'Comparar exercicios',
    subtitle: 'Use criterios objetivos do catalogo local.',
    isScrollControlled: true,
    child: _LibraryComparisonSheet(
      source: source,
      candidates: candidates,
      intelligence: intelligence,
    ),
  );
}

class _LibraryComparisonSheet extends StatefulWidget {
  const _LibraryComparisonSheet({
    required this.source,
    required this.candidates,
    required this.intelligence,
  });

  final ExercicioModel source;
  final List<ExerciseRecommendation> candidates;
  final ExerciseLibraryIntelligence intelligence;

  @override
  State<_LibraryComparisonSheet> createState() =>
      _LibraryComparisonSheetState();
}

class _LibraryComparisonSheetState extends State<_LibraryComparisonSheet> {
  late ExercicioModel _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.candidates.first.exercise;
  }

  @override
  Widget build(BuildContext context) {
    final comparison = widget.intelligence.compare(widget.source, _selected);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .48,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<ExercicioModel>(
              key: ValueKey(_selected.id),
              initialValue: _selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Comparar com'),
              items: widget.candidates
                  .map(
                    (recommendation) => DropdownMenuItem(
                      value: recommendation.exercise,
                      child: Text(
                        recommendation.exercise.nome,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (exercise) {
                if (exercise != null) setState(() => _selected = exercise);
              },
            ),
            const SizedBox(height: 12),
            _ComparisonRow(
              label: 'Musculos em comum',
              value: comparison.sharedMuscles.isEmpty
                  ? 'Nenhum musculo informado em comum'
                  : comparison.sharedMuscles.join(', '),
            ),
            _ComparisonRow(
              label: 'Padrao de movimento',
              value: comparison.sameMovement ? 'Preservado' : 'Diferente',
            ),
            _ComparisonRow(
              label: 'Equipamento',
              value: comparison.sameEquipment ? 'Compativel' : 'Diferente',
            ),
            _ComparisonRow(
              label: 'Dificuldade',
              value: comparison.sameDifficulty ? 'Equivalente' : 'Diferente',
            ),
            const SizedBox(height: 8),
            for (final item in comparison.summary)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(item, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 142,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
