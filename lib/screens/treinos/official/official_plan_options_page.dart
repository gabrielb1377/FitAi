import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import '../../../services/treino_service.dart';
import 'official_add_workout_page.dart';
import 'official_plan_editor_page.dart';
import 'official_plan_model_utils.dart';
import 'official_plan_ui.dart';

class OfficialPlanOptionsPage extends StatefulWidget {
  const OfficialPlanOptionsPage({super.key, required this.plan});

  final TreinoModel plan;

  @override
  State<OfficialPlanOptionsPage> createState() =>
      _OfficialPlanOptionsPageState();
}

class _OfficialPlanOptionsPageState extends State<OfficialPlanOptionsPage> {
  late TreinoModel _plan = widget.plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OfficialPlanColors.background,
      body: SafeArea(
        child: OfficialPlanViewport(
          child: Column(
            children: [
              OfficialPlanHeader(
                title: 'Opções do plano',
                onBack: () => Navigator.maybePop(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Row(
                  children: [
                    OfficialPlanMedia(plan: _plan, width: 68, height: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _plan.nome,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: OfficialPlanColors.text),
                          ),
                          Text(
                            '${_days(_plan)} treinos · ${_plan.nivel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Criado por você',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OfficialPlanSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _option(Icons.edit_outlined, 'Editar plano', _edit),
                      _option(
                        Icons.add_circle_outline_rounded,
                        'Adicionar treino',
                        _addWorkout,
                      ),
                      _option(
                        Icons.copy_outlined,
                        'Duplicar plano',
                        _duplicate,
                      ),
                      _option(
                        Icons.share_outlined,
                        'Compartilhar plano',
                        () => _unavailable('Compartilhamento'),
                      ),
                      _option(
                        Icons.picture_as_pdf_outlined,
                        'Exportar plano (PDF)',
                        () => _unavailable('Exportação em PDF'),
                      ),
                      _option(
                        Icons.delete_outline_rounded,
                        'Excluir plano',
                        _delete,
                        destructive: true,
                        last: true,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OfficialPlanColors.text,
                      side: const BorderSide(color: OfficialPlanColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
    bool last = false,
  }) {
    final color = destructive
        ? OfficialPlanColors.danger
        : OfficialPlanColors.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: last
              ? null
              : const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: OfficialPlanColors.border),
                  ),
                ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: OfficialPlanColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit() async {
    TreinoModel? updated;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OfficialPlanEditorPage(
          initialPlan: _plan,
          onSaved: (value) => updated = value,
        ),
      ),
    );
    if (!mounted || changed != true || updated == null) return;
    setState(() => _plan = updated!);
  }

  Future<void> _addWorkout() async {
    final day = await Navigator.push<TreinoDiaModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OfficialAddWorkoutPage(initialOrder: _plan.planoDias.length + 1),
      ),
    );
    if (!mounted || day == null) return;
    final days = [..._plan.planoDias, day]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    final updated = copyOfficialPlan(_plan, days: days);
    await TreinoService.instance.adicionarTreinoComPersistencia(updated);
    if (!mounted) return;
    setState(() => _plan = updated);
  }

  Future<void> _duplicate() async {
    final copy = copyOfficialPlan(
      _plan,
      id: 'plan_${DateTime.now().microsecondsSinceEpoch}',
      name: '${_plan.nome} (cópia)',
      createdAt: DateTime.now().toIso8601String(),
    );
    await TreinoService.instance.adicionarTreinoComPersistencia(copy);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plano duplicado.')));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir plano?'),
        content: const Text('Confirme para remover este plano.'),
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
    TreinoService.instance.removerTreino(_plan.id);
    Navigator.pop(context, true);
  }

  void _unavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature ainda não está disponível.')),
    );
  }

  int _days(TreinoModel plan) {
    return plan.planoDias.isNotEmpty
        ? plan.planoDias.length
        : plan.diasPorSemana;
  }
}
