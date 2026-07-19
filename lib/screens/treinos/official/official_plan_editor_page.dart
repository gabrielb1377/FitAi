import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import '../../../services/treino_service.dart';
import '../widgets/plans/plan_media.dart';
import 'official_plan_model_utils.dart';
import 'official_plan_ui.dart';

class OfficialPlanEditorPage extends StatefulWidget {
  const OfficialPlanEditorPage({
    super.key,
    this.initialPlan,
    this.onSaved,
    this.onDeleted,
  });

  final TreinoModel? initialPlan;
  final ValueChanged<TreinoModel>? onSaved;
  final VoidCallback? onDeleted;

  @override
  State<OfficialPlanEditorPage> createState() => _OfficialPlanEditorPageState();
}

class _OfficialPlanEditorPageState extends State<OfficialPlanEditorPage> {
  static const _goals = ['Hipertrofia', 'Definição', 'Força', 'Saúde'];
  static const _levels = ['Iniciante', 'Intermediário', 'Avançado'];
  static const _splits = ['Upper / Lower', 'Push / Pull / Legs', 'Full Body'];

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _goal;
  late String _level;
  late String _split;
  var _saving = false;

  bool get _editing => widget.initialPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _nameController = TextEditingController(text: plan?.nome ?? '');
    _descriptionController = TextEditingController(text: plan?.descricao ?? '');
    _goal = _matching(_goals, plan?.objetivo, 'Hipertrofia');
    _level = _matching(_levels, plan?.nivel, 'Intermediário');
    _split = _matching(_splits, plan?.divisao, 'Full Body');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OfficialPlanColors.background,
      body: SafeArea(
        child: OfficialPlanViewport(
          child: Column(
            children: [
              OfficialPlanHeader(
                title: _editing ? 'Editar plano' : 'Criar novo plano',
                onBack: () => Navigator.maybePop(context),
                trailing: OfficialPlanIconButton(
                  icon: Icons.check_rounded,
                  tooltip: 'Salvar plano',
                  onPressed: _save,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  children: [
                    _photo(),
                    const SizedBox(height: 18),
                    OfficialPlanLabeledField(
                      label: _editing ? 'Nome' : 'Nome do plano',
                      child: TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: officialPlanInputDecoration(
                          hintText: 'Ex: Upper A',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _choiceGroup('Objetivo', _goals, _goal, (value) {
                      setState(() => _goal = value);
                    }),
                    const SizedBox(height: 14),
                    _choiceGroup('Nível', _levels, _level, (value) {
                      setState(() => _level = value);
                    }),
                    const SizedBox(height: 14),
                    _choiceGroup('Divisão', _splits, _split, (value) {
                      setState(() => _split = value);
                    }),
                    const SizedBox(height: 14),
                    OfficialPlanLabeledField(
                      label: 'Descrição (opcional)',
                      child: TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: officialPlanInputDecoration(
                          hintText: _editing
                              ? 'Foco em desenvolver peito, costas e ombros com ênfase em exercícios compostos e progressão de carga.'
                              : 'Fale sobre o foco do plano...',
                        ),
                      ),
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: OfficialPlanColors.danger,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Excluir plano'),
                      ),
                    ],
                    if (_saving) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        color: OfficialPlanColors.green,
                        backgroundColor: OfficialPlanColors.border,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo() {
    final plan = widget.initialPlan;
    if (plan != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 164,
          height: 88,
          child: PlanMedia(
            plan: plan,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    return Align(
      child: Container(
        width: 170,
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: OfficialPlanColors.borderStrong,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: OfficialPlanColors.textMuted),
            SizedBox(height: 8),
            Text(
              'Adicionar foto',
              style: TextStyle(
                color: OfficialPlanColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceGroup(
    String label,
    List<String> values,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return OfficialPlanLabeledField(
      label: label,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final value in values)
            OfficialPlanChoiceChip(
              label: value,
              selected: value == selected,
              onSelected: () => onSelected(value),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe o nome do plano.')));
      return;
    }
    setState(() => _saving = true);
    final original = widget.initialPlan;
    final plan = original == null
        ? TreinoModel(
            id: 'plan_${DateTime.now().microsecondsSinceEpoch}',
            nome: name,
            descricao: _descriptionController.text.trim(),
            objetivo: _goal,
            nivel: _level,
            divisao: _split,
            tempoEstimado: 45,
            diasPorSemana: 4,
            criadoPorIA: false,
            exercicios: const [],
            dataCriacao: DateTime.now().toIso8601String(),
          )
        : copyOfficialPlan(
            original,
            name: name,
            description: _descriptionController.text.trim(),
            goal: _goal,
            level: _level,
            split: _split,
          );
    await TreinoService.instance.adicionarTreinoComPersistencia(plan);
    if (!mounted) return;
    widget.onSaved?.call(plan);
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final plan = widget.initialPlan;
    if (plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir plano?'),
        content: const Text('Esta ação removerá o plano dos seus planos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: OfficialPlanColors.danger,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    TreinoService.instance.removerTreino(plan.id);
    widget.onDeleted?.call();
    Navigator.pop(context, true);
  }

  static String _matching(
    List<String> options,
    String? current,
    String fallback,
  ) {
    if (current == null) return fallback;
    final normalized = current.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    for (final option in options) {
      final candidate = option.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      if (candidate == normalized ||
          candidate.contains(normalized) ||
          normalized.contains(candidate)) {
        return option;
      }
    }
    return fallback;
  }
}
