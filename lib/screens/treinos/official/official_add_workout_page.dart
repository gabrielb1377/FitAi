import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import 'official_plan_ui.dart';

class OfficialAddWorkoutPage extends StatefulWidget {
  const OfficialAddWorkoutPage({super.key, required this.initialOrder});

  final int initialOrder;

  @override
  State<OfficialAddWorkoutPage> createState() => _OfficialAddWorkoutPageState();
}

class _OfficialAddWorkoutPageState extends State<OfficialAddWorkoutPage> {
  static const _groups = [
    'Peito',
    'Costas',
    'Ombros',
    'Braços',
    'Pernas',
    'Abdômen',
  ];

  late final TextEditingController _nameController;
  final _descriptionController = TextEditingController();
  final Set<String> _selectedGroups = {'Peito', 'Costas'};
  late int _order;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder.clamp(1, 99);
    _nameController = TextEditingController(text: 'Treino $_order');
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
                title: 'Adicionar treino',
                onBack: () => Navigator.maybePop(context),
                trailing: OfficialPlanIconButton(
                  icon: Icons.check_rounded,
                  tooltip: 'Adicionar treino',
                  onPressed: _submit,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  children: [
                    OfficialPlanLabeledField(
                      label: 'Nome do treino',
                      child: TextField(
                        controller: _nameController,
                        decoration: officialPlanInputDecoration(
                          hintText: 'Treino $_order',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    OfficialPlanLabeledField(
                      label: 'Grupos musculares principais',
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final group in _groups)
                            OfficialPlanChoiceChip(
                              label: group,
                              selected: _selectedGroups.contains(group),
                              onSelected: () => setState(() {
                                if (!_selectedGroups.remove(group)) {
                                  _selectedGroups.add(group);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    OfficialPlanLabeledField(
                      label: 'Descrição (opcional)',
                      child: TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: officialPlanInputDecoration(
                          hintText:
                              'Foque nos exercícios compostos e progressão de carga.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    OfficialPlanLabeledField(
                      label: 'Ordem do treino no plano',
                      child: OfficialPlanSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            _stepButton(Icons.remove_rounded, -1),
                            Expanded(
                              child: Text(
                                '$_order',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            _stepButton(Icons.add_rounded, 1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepButton(IconData icon, int delta) {
    return OfficialPlanIconButton(
      icon: icon,
      tooltip: delta > 0 ? 'Aumentar ordem' : 'Diminuir ordem',
      outlined: true,
      onPressed: () => setState(() {
        _order = (_order + delta).clamp(1, 99);
      }),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome e ao menos um grupo muscular.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      TreinoDiaModel(
        codigo: name,
        nome: _selectedGroups.join(' e '),
        ordem: _order,
        exercicioIds: const [],
      ),
    );
  }
}
