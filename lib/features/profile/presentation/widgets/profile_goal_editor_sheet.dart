import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../progression/progression.dart';

/// Edicao local de alvo sem reescrever metas ja concluídas ou expirada.
class ProfileGoalEditorSheet extends StatefulWidget {
  const ProfileGoalEditorSheet({
    super.key,
    required this.goals,
    required this.onSave,
  });

  final List<UserGoal> goals;
  final Future<void> Function(GoalType type, int target) onSave;

  @override
  State<ProfileGoalEditorSheet> createState() => _ProfileGoalEditorSheetState();
}

class _ProfileGoalEditorSheetState extends State<ProfileGoalEditorSheet> {
  UserGoal? _selected;
  late int _target;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.goals.firstOrNull;
    _target = _selected?.target ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected == null) {
      return const FitEmptyState(
        icon: FitIcons.goal,
        title: 'Nenhuma meta ativa',
        description: 'Uma nova meta aparecera quando houver dados locais.',
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: FitSpacing.s8,
          runSpacing: FitSpacing.s8,
          children: [
            for (final goal in widget.goals)
              FitChip(
                label: _label(goal.type),
                selected: selected.id == goal.id,
                onSelected: (_) => setState(() {
                  _selected = goal;
                  _target = goal.target;
                }),
              ),
          ],
        ),
        const SizedBox(height: FitSpacing.s16),
        FitStepper(
          label: _unit(selected.type),
          value: _target.toDouble(),
          min: _minimum(selected.type).toDouble(),
          max: _maximum(selected.type).toDouble(),
          step: _step(selected.type).toDouble(),
          valueFormatter: (value) => value.round().toString(),
          onChanged: (value) => setState(() => _target = value.round()),
        ),
        const SizedBox(height: FitSpacing.s16),
        FitLoadingButton(
          label: 'Salvar meta',
          loading: _saving,
          onPressed: _saving
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  setState(() => _saving = true);
                  try {
                    await widget.onSave(selected.type, _target);
                    if (mounted) navigator.pop();
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
        ),
      ],
    );
  }

  String _label(GoalType type) => switch (type) {
    GoalType.weeklyWorkouts => 'Treinos',
    GoalType.weeklyRuns => 'Corridas',
    GoalType.weeklyDistance => 'Distancia',
    GoalType.dailySteps => 'Passos',
    GoalType.weeklyActiveDays => 'Dias ativos',
    GoalType.monthlyFrequency => 'Frequencia',
  };

  String _unit(GoalType type) => switch (type) {
    GoalType.weeklyDistance => 'Quilometros',
    GoalType.dailySteps => 'Passos',
    _ => 'Atividades',
  };

  int _minimum(GoalType type) => type == GoalType.dailySteps ? 1000 : 1;
  int _maximum(GoalType type) => type == GoalType.dailySteps ? 100000 : 100;
  int _step(GoalType type) => type == GoalType.dailySteps ? 500 : 1;
}
