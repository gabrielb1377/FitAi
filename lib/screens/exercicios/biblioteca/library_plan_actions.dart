import 'package:flutter/material.dart';

import '../../../core/design_system/components/navigation/fit_containers.dart';
import '../../../core/exercises/exercise_plan_integration.dart';
import '../../../design_system/components/fit_button.dart';
import '../../../design_system/tokens/fit_spacing.dart';
import '../../../models/exercicio_model.dart';
import '../../../models/treino_model.dart';
import '../../treinos/criar_treino_page.dart';

Future<ExercisePlanInsertionResult?> showLibraryAddToPlanSheet({
  required BuildContext context,
  required ExercicioModel exercise,
  ExercisePlanIntegration? integration,
}) {
  return FitBottomSheetContainer.show<ExercisePlanInsertionResult>(
    context: context,
    title: 'Adicionar ao plano',
    subtitle: 'A configuracao sera salva neste dispositivo.',
    isScrollControlled: true,
    child: _LibraryAddToPlanSheet(
      exercise: exercise,
      integration: integration ?? ExercisePlanIntegration(),
    ),
  );
}

class _LibraryAddToPlanSheet extends StatefulWidget {
  const _LibraryAddToPlanSheet({
    required this.exercise,
    required this.integration,
  });

  final ExercicioModel exercise;
  final ExercisePlanIntegration integration;

  @override
  State<_LibraryAddToPlanSheet> createState() => _LibraryAddToPlanSheetState();
}

class _LibraryAddToPlanSheetState extends State<_LibraryAddToPlanSheet> {
  late final TextEditingController _setsController;
  late final TextEditingController _repetitionsController;
  late final TextEditingController _restController;
  List<TreinoModel> _plans = const [];
  TreinoModel? _selectedPlan;
  int? _dayIndex;
  var _positionAtEnd = true;
  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: '${widget.exercise.series <= 0 ? 3 : widget.exercise.series}',
    );
    _repetitionsController = TextEditingController(
      text: widget.exercise.repeticoes.trim().isEmpty
          ? '8-12'
          : widget.exercise.repeticoes,
    );
    _restController = TextEditingController(
      text:
          '${widget.exercise.descansoSegundos <= 0 ? 60 : widget.exercise.descansoSegundos}',
    );
    _loadPlans();
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repetitionsController.dispose();
    _restController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await widget.integration.availablePlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _selectedPlan = plans.isEmpty ? null : plans.first;
        _dayIndex = _selectedPlan?.planoDias.isEmpty ?? true ? null : 0;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel carregar seus planos.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final plan = _selectedPlan;
    final sets = int.tryParse(_setsController.text.trim());
    final rest = int.tryParse(_restController.text.trim());
    final repetitions = _repetitionsController.text.trim();
    if (plan == null ||
        sets == null ||
        sets < 1 ||
        rest == null ||
        rest < 0 ||
        repetitions.isEmpty) {
      setState(() => _error = 'Revise plano, series, repeticoes e descanso.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.integration.addToPlan(
        ExercisePlanInsertion(
          plan: plan,
          exercise: widget.exercise,
          dayIndex: _dayIndex,
          position: _positionAtEnd ? null : 0,
          sets: sets,
          repetitions: repetitions,
          restSeconds: rest,
        ),
      );
      if (mounted) Navigator.of(context).pop(result);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_plans.isEmpty) return _noPlanState();

    final plan = _selectedPlan!;
    final hasDays = plan.planoDias.isNotEmpty;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .56,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: FitSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<TreinoModel>(
              key: ValueKey(plan.id),
              initialValue: plan,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Plano'),
              items: _plans
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.nome, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (selected) => setState(() {
                      _selectedPlan = selected;
                      _dayIndex = selected?.planoDias.isEmpty ?? true
                          ? null
                          : 0;
                    }),
            ),
            if (hasDays) ...[
              const SizedBox(height: FitSpacing.s12),
              DropdownButtonFormField<int>(
                key: ValueKey('plan-day-${plan.id}'),
                initialValue: _dayIndex,
                decoration: const InputDecoration(labelText: 'Treino do plano'),
                items: List.generate(
                  plan.planoDias.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(plan.planoDias[index].nome),
                  ),
                ),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _dayIndex = value),
              ),
            ],
            const SizedBox(height: FitSpacing.s12),
            _PrescriptionFields(
              setsController: _setsController,
              repetitionsController: _repetitionsController,
              restController: _restController,
              enabled: !_saving,
            ),
            const SizedBox(height: FitSpacing.s8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Adicionar ao final'),
              subtitle: const Text(
                'Desative para inserir no inicio do treino.',
              ),
              value: _positionAtEnd,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _positionAtEnd = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: FitSpacing.s8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: FitSpacing.s12),
            FitButton(
              label: 'Confirmar no plano',
              icon: Icons.playlist_add_check_rounded,
              onPressedAsync: _saving ? null : _submit,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _noPlanState() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Nenhum plano encontrado. Crie um plano antes de adicionar exercicios.',
      ),
      if (_error != null) ...[
        const SizedBox(height: FitSpacing.s8),
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: FitSpacing.s12),
      FitButton(
        label: 'Criar plano',
        icon: Icons.add_rounded,
        expand: true,
        onPressed: () async {
          Navigator.of(context).pop();
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const CriarTreinoPage()),
          );
        },
      ),
    ],
  );
}

class _PrescriptionFields extends StatelessWidget {
  const _PrescriptionFields({
    required this.setsController,
    required this.repetitionsController,
    required this.restController,
    required this.enabled,
  });

  final TextEditingController setsController;
  final TextEditingController repetitionsController;
  final TextEditingController restController;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: setsController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Series'),
        ),
      ),
      const SizedBox(width: FitSpacing.s8),
      Expanded(
        child: TextField(
          controller: repetitionsController,
          enabled: enabled,
          decoration: const InputDecoration(labelText: 'Repeticoes'),
        ),
      ),
      const SizedBox(width: FitSpacing.s8),
      Expanded(
        child: TextField(
          controller: restController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Descanso (s)'),
        ),
      ),
    ],
  );
}
